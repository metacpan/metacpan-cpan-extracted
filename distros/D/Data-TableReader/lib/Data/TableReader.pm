package Data::TableReader;
use Moo 2;
use Try::Tiny;
use Carp;
use Scalar::Util qw( blessed refaddr );
use List::Util 'max';
use Module::Runtime 'require_module';
use Data::TableReader::Field;
use Data::TableReader::Iterator;
use namespace::clean;

# ABSTRACT: Extract records from "dirty" tabular data sources
our $VERSION = '0.015'; # VERSION


has input               => ( is => 'rw', required => 1 );
has _file_handle        => ( is => 'lazy' );
has _decoder_arg        => ( is => 'rw', init_arg => 'decoder' );
has decoder             => ( is => 'lazy', init_arg => undef );
has fields              => ( is => 'rw', required => 1, coerce => \&_coerce_field_list );
sub field_list             { @{ shift->fields } }
has field_by_name       => ( is => 'lazy' );
has field_by_addr       => ( is => 'lazy' );
has record_class        => ( is => 'rw', required => 1, default => sub { 'HASH' } );
has static_field_order  => ( is => 'rw' ); # force order of columns
has header_row_at       => ( is => 'rw', default => sub { [1,10] } ); # row of header, or range to scan
has header_row_combine  => ( is => 'rw', lazy => 1, builder => 1 );
has table_search_results=> ( is => 'rw', lazy => 1, builder => 1, clearer => 1, predicate => 1 );
has col_map             => ( is => 'rw', lazy => 1, builder => 1, predicate => 1 );
has on_partial_match    => ( is => 'rw', default => sub { 'next' } );
has on_ambiguous_columns=> ( is => 'rw', default => sub { 'error' } );
has on_unknown_columns  => ( is => 'rw', default => sub { 'warn' } );
has on_blank_row        => ( is => 'rw', default => sub { 'next' } );
has on_validation_fail  => ( is => 'rw', default => sub { 'die' } );
has log                 => ( is => 'rw', trigger => sub { shift->_clear_log } );

sub BUILD {
	my ($self)= @_;
	# If user supplied col_map, it probably contains names instead of Field objects.
	if ($self->has_col_map) {
		# Make a new array in case other parts of user code refer to current one
		$self->col_map($self->_resolve_colmap_names([ @{ $self->col_map } ]));
	}
}

# Modifies array to replace name with field ref
sub _resolve_colmap_names {
	my ($self, $col_map)= @_;
	for (grep defined && !ref, @$col_map) {
		defined(my $f= $self->field_by_name->{$_})
			or croak("col_map specifies non-existent field '$_'");
		$_= $f;
	}
	$col_map;
}

# Open 'input' if it isn't already a file handle
sub _build__file_handle {
	my $self= shift;
	my $i= $self->input;
	return undef if ref($i) && (
		(blessed($i) && ($i->can('get_cell') || $i->can('worksheets')))
		or ref($i) eq 'ARRAY'
	);
	return $i if ref($i) && (ref($i) eq 'GLOB' or ref($i)->can('read'));
	open(my $fh, '<', $i) or croak "open($i): $!";
	binmode $fh;
	return $fh;
}

# Create ::Decoder instance either from user-supplied args, or by detecting input format
sub _build_decoder {
	my $self= shift;
	my $decoder_arg= $self->_decoder_arg;
	my $decoder_ref= ref $decoder_arg;
	my ($class, @args);
	if (!$decoder_arg) {
		($class, @args)= $self->detect_input_format;
		$self->_log->('trace', "Detected input format as %s", $class);
	}
	elsif (!$decoder_ref) {
		$class= $decoder_arg;
	}
	elsif ($decoder_ref eq "HASH" or $decoder_ref eq "ARRAY") {
		($class, @args)= $decoder_ref eq "ARRAY"? @$decoder_arg : do {
			my %tmp= %$decoder_arg;
			(delete($tmp{CLASS}), %tmp);
		};
		if(!$class) {
			my ($input_class, @input_args)= $self->detect_input_format;
			croak "decoder class not in arguments and unable to identify decoder class from input"
				if !$input_class;
			($class, @args)= ($input_class, @input_args, @args);
		}
	}
	elsif ($decoder_ref->can('iterator')) {
		return $decoder_arg;
	}
	else {
		croak "Can't create decoder from $decoder_ref";
	}
	$class= "Data::TableReader::Decoder::$class"
		unless $class =~ /::/;
	require_module($class) or croak "$class does not exist or is not installed";
	$self->_log->('trace', 'Creating decoder %s on input %s', $class, $self->input);
	return $class->new(
		file_name   => ($self->input eq ($self->_file_handle||"") ? '' : $self->input),
		file_handle => $self->_file_handle,
		_log        => $self->_log,
		@args
	);
}

# User supplies any old perl data, but this field should always be an arrayref of ::Field
sub _coerce_field_list {
	my ($list)= @_;
	defined $list and ref $list eq 'ARRAY' or croak "'fields' must be a non-empty arrayref";
	my @list= @$list; # clone it, to make sure we don't unexpectedly alter the caller's data
	for (@list) {
		if (!ref $_) {
			$_= Data::TableReader::Field->new({ name => $_ });
		} elsif (ref $_ eq 'HASH') {
			my %args= %$_;
			# "isa" alias for the 'type' attribute
			$args{type}= delete $args{isa} if defined $args{isa} && !defined $args{type};
			$_= Data::TableReader::Field->new(\%args)
		} else {
			croak "Can't coerce '$_' to a Field object"
		}
	}
	return \@list;
}

sub _build_field_by_name {
	my $self= shift;
	# reverse list so first field of a name takes precedence
	return { map +( $_->name => $_ ), reverse @{ $self->fields } }
}

sub _build_field_by_addr {
	my $self= shift;
	return { map +( refaddr $_ => $_ ), @{ $self->fields } }
}

sub _build_header_row_combine {
	my $self= shift;
	# If headers contain "\n", we need to collect multiple cells per column
	# Find the maximum number of \n contained in any regex.
	max map { 1+(()= ($_->header_regex =~ /\\n|\n/g)) } $self->field_list;
}

# 'log' can be a variety of things, but '_log' will always be a coderef
has _log => ( is => 'lazy', clearer => 1 );
sub _build__log {
	_log_fn(shift->log);
}
sub _log_fn {
	my $dest= shift;
	!$dest? sub {
		my ($level, $msg, @args)= @_;
		return unless $level eq 'warn' or $level eq 'error';
		$msg= sprintf($msg, @args) if @args;
		warn $msg."\n";
	}
	: ref $dest eq 'ARRAY'? sub {
		my ($level, $msg, @args)= @_;
		return unless $level eq 'warn' or $level eq 'error';
		$msg= sprintf($msg, @args) if @args;
		push @$dest, [ $level, $msg ];
	}
	: ref($dest)->can('info')? sub {
		my ($level, $msg, @args)= @_;
		$dest->$level( @args? sprintf($msg, @args) : $msg )
			if $dest->can('is_'.$level)->($dest);
	}
	: croak "Don't know how to log to $dest";
}


sub detect_input_format {
	my ($self, $filename, $magic)= @_;

	my $input= $self->input;
	# As convenience to spreadsheet users, let input be a parsed workbook/worksheet object.
	return ('XLSX', sheet => $input)
		if ref($input) && ref($input)->can('get_cell');
	return ('XLSX', workbook => $input)
		if ref($input) && ref($input)->can('worksheets');
	# Convenience for passing already-parsed data
	if (ref($input) eq 'ARRAY') {
		# if user supplied single table of data, wrap it in an array to make an array of tables.
		$input= [ $input ]
			if @$input && ref($input->[0]) eq 'ARRAY'
			&& @{$input->[0]} && ref($input->[0][0]) ne 'ARRAY';
		return ('Mock', datasets => $input);
	}

	# Load first block of file, unless supplied
	my $fpos;
	if (!defined $magic) {
		my $fh= $self->_file_handle;
		# Need to be able to seek.
		if (seek($fh, 0, 1)) {
			$fpos= tell $fh;
			read($fh, $magic, 4096);
			seek($fh, $fpos, 0) or croak "seek: $!";
		}
		elsif ($fh->can('ungets')) {
			$fpos= 0; # to indicate that we did try reading the file
			read($fh, $magic, 4096);
			$fh->ungets($magic);
		}
		else {
			$self->_log->('notice',"Can't fully detect input format because handle is not seekable."
				." Consider fully buffering the file, or using FileHandle::Unget");
			$magic= '';
		}
	}

	# Excel is obvious so check it first.  This handles cases where an excel file is
	# erroneously named ".csv" and sillyness like that.
	return ( 'XLSX' ) if $magic =~ /^PK(\x03\x04|\x05\x06|\x07\x08)/;
	return ( 'XLS'  ) if $magic =~ /^\xD0\xCF\x11\xE0/;

	# Else trust the file extension, because TSV with commas can be very similar to CSV with
	# tabs in the data, and some crazy person might store an HTML document as the first element
	# of a CSV file.
	# Detect filename if not supplied
	if (!defined $filename) {
		$filename= '';
		$filename= "$input" if defined $input and (!ref $input || ref($input) =~ /path|file/i);
	}
	if ($filename =~ /\.([^.]+)$/) {
		my $suffix= uc($1);
		return 'HTML' if $suffix eq 'HTM';
		return $suffix;
	}

	# Else probe some more...
	$self->_log->('debug',"Probing file format because no filename suffix");
	length $magic or croak "Can't probe format. No filename suffix, and "
		.(!defined $fpos? "unseekable file handle" : "no content");

	# HTML is pretty obvious
	return 'HTML' if $magic =~ /^(\xEF\xBB\xBF|\xFF\xFE|\xFE\xFF)?<(!DOCTYPE )HTML/i;
	# Else guess between CSV and TSV
	my ($probably_csv, $probably_tsv)= (0,0);
	++$probably_csv if $magic =~ /^(\xEF\xBB\xBF|\xFF\xFE|\xFE\xFF)?["']?[\w ]+["']?,/;
	++$probably_tsv if $magic =~ /^(\xEF\xBB\xBF|\xFF\xFE|\xFE\xFF)?["']?[\w ]+["']?\t/;
	my $comma_count= () = ($magic =~ /,/g);
	my $tab_count= () = ($magic =~ /\t/g);
	my $eol_count= () = ($magic =~ /\n/g);
	++$probably_csv if $comma_count > $eol_count and $comma_count > $tab_count;
	++$probably_tsv if $tab_count > $eol_count and $tab_count > $comma_count;
	$self->_log->('debug', 'probe results: comma_count=%d tab_count=%d eol_count=%d probably_csv=%d probably_tsv=%d',
		$comma_count, $tab_count, $eol_count, $probably_csv, $probably_tsv);
	return 'CSV' if $probably_csv and $probably_csv > $probably_tsv;
	return 'TSV' if $probably_tsv and $probably_tsv > $probably_csv;
	croak "Can't determine file format";
}


sub _build_table_search_results {
	my $self= shift;
	my $result= $self->_find_table($self->decoder->iterator);
	# When called during lazy-build, not finding the table is fatal
	if (!$result->{found}) {
		my $err= $$result->{fatal} || "Can't locate valid header";
		$self->_log->('error', $err);
		croak $err;
	}
	$result;
}

sub _build_col_map {
	shift->table_search_results->{col_map}
}

sub find_table {
	my $self= shift;
	my $result= $self->_find_table($self->decoder->iterator);
	$self->table_search_results($result);
	return defined $result->{found};
}

sub field_map { _field_map(shift->col_map) }

sub _field_map {
	my $col_map= shift;
	my %fmap;
	for my $i (0 .. $#$col_map) {
		next unless defined $col_map->[$i];
		if ($col_map->[$i]->array) {
			push @{ $fmap{$col_map->[$i]->name} }, $i;
		} else {
			$fmap{$col_map->[$i]->name}= $i;
		}
	}
	return \%fmap;
}

sub _find_table {
	my ($self, $data_iter)= @_;
#	$stash ||= {};
#	while (1) {
#		$success= $self->_find_table_in_dataset($data_iter, $stash);
#		&& !defined $stash->{fatal}
#		&& $data_iter->next_dataset
#	) {}
#	if ($success) {
#		# And record the stream position of the start of the table
#		$self->col_map($stash->{col_map});
#		$stash->{first_record_pos}= $data_iter->tell;
#		$stash->{data_iter}= $data_iter;
#		return $stash;
#	}
#	else {
#		my $err= $stash->{fatal} || "Can't locate valid header";
#		$self->_log->('error', $err);
#		croak $err if $stash->{croak_on_fail};
#		return undef;
#	}
	my @fields= $self->field_list;
	my $header_at= $self->header_row_at;
	my %result;

	# Special case for the file not having any headers in it.
	# If header_row_at is undef, then there is no header.
	# Ensure static_field_order, then set up columns.
	if (!defined $header_at) {
		unless ($self->static_field_order) {
			$result{fatal}= "You must enable 'static_field_order' if there is no header row";
			return;
		}
		my $col_map= [ $self->has_col_map? @{$self->col_map} : @fields ];
		$result{found}= {
			row_idx => -1,
			dataset_idx => 0,
			col_map => $col_map,
			messages => [],
			first_record_pos => $data_iter->tell,
			_data_iter => $data_iter,
      };
		$result{candidates}= [ $result{found} ];
		return \%result;
	}

	my $dataset_idx= 0;
	dataset: do {
		# If headers contain "\n", we need to collect multiple cells per column
		my $row_accum= $self->header_row_combine;
		
		my ($start, $end)= ref $header_at? @$header_at : ( $header_at, $header_at );
		my @rows;
		
		# If header_row_at doesn't start at 1, seek forward
		if ($start > 1) {
			$self->_log->('trace', 'Skipping to row %s', $start);
			push @rows, $data_iter->() for 1..$start-1;
		}
		
		# Scan through the rows of the dataset up to the end of header_row_at, accumulating rows so that
		# multi-line regexes can match.
		for ($start .. $end) {
			my %attempt= (
				row_idx => $_,
				dataset_idx => $dataset_idx,
				messages => []
			);
			my $vals= $data_iter->();
			if (!$vals) { # if undef, we reached end of dataset
				$self->_log->('trace', 'EOF');
				last;
			}
			if ($row_accum > 1) {
				push @rows, $vals;
				shift @rows while @rows > $row_accum;
				$vals= [ map { my $c= $_; join("\n", map $_->[$c], @rows) } 0 .. $#{$rows[-1]} ];
				$attempt{context}= $row_accum.' rows ending at '.$data_iter->position;
			} else {
				$attempt{context}= $data_iter->position;
			}
			$self->_log->('trace', 'Checking for headers on %s', $attempt{context});
			# Now fill-in the col_map
			my $found= $self->static_field_order?
				# If static field order, look for headers in sequence
				$self->_match_headers_static($vals, \%attempt)
				# else search for each header
				: $self->_match_headers_dynamic($vals, \%attempt);
			$attempt{first_record_pos}= $data_iter->tell;
			$self->_log->(@$_) for @{$attempt{messages}};
			push @{$result{candidates}}, \%attempt;
			if ($found) {
				$result{found}= \%attempt;
				$result{found}{_data_iter}= $data_iter;
				$self->col_map($attempt{col_map});
				$self->_log->(info => 'Found header at '.$attempt{context});
				return \%result;
			} else {
				# Back-compat: if attempt ends with 'fatal' message, stop looking for header
				last dataset
					if delete $attempt{fatal};
				# Was this a partial match?  See if any col_map entries were added vs. what user already gave us.
				my $initial_colmap_count= !$self->has_col_map? 0
					: scalar(grep defined, @{$self->col_map});
				if ($initial_colmap_count < scalar(grep defined, @{$attempt{col_map}})) {
					# Handling of partial match determined by on_partial_match setting
					my $act= $self->on_partial_match;
					$act= $act->($self, \%attempt) if ref $act eq 'CODE';
					last dataset
						if $act eq 'last';
				}
			}
			$self->_log->('debug', '%s: No match', $attempt{context});
		}
		$self->_log->('error','No row in dataset matched full header requirements');
		++$dataset_idx;
	} while ($data_iter->next_dataset);
	return \%result;
}

# This mode assumes all headers match exactly as perscribed in the fields list or user-supplied col_map
sub _match_headers_static {
	my ($self, $header, $attempt)= @_;
	my @col_map= $self->has_col_map? @{$self->col_map} : @{$self->fields};
	$attempt->{col_map}= \@col_map;
	for my $i (0 .. $#col_map) {
		next unless defined $col_map[$i];
		next if $header->[$i] =~ $col_map[$i]->header_regex;
		# Field header doesn't match.  Start over on next row.
		push @{$attempt->{messages}}, [ error => "Header at column $i does not look like field ".$col_map[$i]->name ];
		return 0;
	}
	# found a match for every field!
	$self->_log->('debug','%s: Found!', $attempt->{context});
	return 1;
}

sub _match_headers_dynamic {
	my ($self, $header, $attempt)= @_;
	my $context= $attempt->{context};
	my $fields= $self->fields;
	# Colmap starts empty unless user supplied one
	my $user_colmap= $self->has_col_map? $self->col_map : [];
	my @colmap= map +(defined $_? [ $_ ] : undef), @$user_colmap;
	$attempt->{col_map}= \@colmap;
	# Search every cell of the header, except ones specified by the user
	my @col_search_idx= grep !defined $user_colmap->[$_], 0 .. $#$header;
	# Divide remaining fields (not specified by user) into list that can only occur following
	# another field, or the ones that can occur anywhere.
	my %seen= map +(refaddr $_ => 1 ), grep defined, @$user_colmap;
	my (@follows_fields, @free_fields);
	defined $seen{refaddr $_} or push @{($_->follows_list? \@follows_fields : \@free_fields)}, $_
		for @$fields;
	undef %seen;
	# Sort required fields to front, to fail faster on non-matching rows
	# But otherwise preserve field order in case it matters for priority of matching
	@free_fields= ( (grep $_->required, @free_fields), (grep !$_->required, @free_fields) );

	# For each freely-located field (free = lacking placement requirements) scan every un-used
	# column for a match.  Record all matches, for later analysis of ambiguity.
	# But, stop as soon as a required column is missing; it helps speed up the search for the
	# header.
	my $ambiguous_log_level= $self->on_ambiguous_columns eq 'error'? 'error' : 'warn';
	my %fieldname_cols;
	for my $f (@free_fields) {
		my $hr= $f->header_regex;
		push @{$attempt->{messages}}, [ trace => "looking for $hr" ];
		my @found_idx= grep $header->[$_] =~ $hr, @col_search_idx;
		push @{$attempt->{messages}}, [ debug => "found ".$f->name." header at col [".join(',', map $_+1, @found_idx).']' ];
		for my $idx (@found_idx) {
			# If another field of the same name matches a column, the first gets priority.
			# ignore the duplicate.
			if ($fieldname_cols{$f->name}{$idx}) {
				push @{$attempt->{messages}}, [ debug => "Ignored; column $idx is already claimed by a field named ".$f->name ];
			} else {
				push @{$colmap[$idx]}, $f;
				#$col_fieldnames{$idx}{$f->name}= 1;
				$fieldname_cols{$f->name}{$idx}= $f;
			}
		}
		# Flag missing required fields
		if (!@found_idx && $f->required) {
			push @{$attempt->{missing_required}}, $f;
			push @{$attempt->{messages}}, [ error => 'No match for required field '.$f->name ];
			# Missing required fields probably means this isn't he header row, or the input is
			# garbage, so might as well stop here before genering a bunch of analysis.
			last;
		}
	}
	# Now, check for any of the 'follows' fields, some of which might also be 'required'.
	if (@follows_fields && !$attempt->{missing_required}) {
		my %following;
		my %found;
		for my $idx (0 .. $#$header) {
			if ($colmap[$idx] && 1 == @{$colmap[$idx]}) {
				%following= ( $colmap[$idx][0]->name => $colmap[$idx][0] );
			} else {
				my $val= $header->[$idx];
				for my $f (@follows_fields) {
					next unless grep $following{$_}, $f->follows_list;
					next unless $val =~ $f->header_regex;
					# If another field of the same name matches a column, the first gets priority.
					# ignore the duplicate.
					if ($fieldname_cols{$f->name}{$idx}) {
						push @{$attempt->{messages}}, [ debug => "Ignored; column $idx is already claimed by a field named ".$f->name ];
					} else {
						push @{$colmap[$idx]}, $f;
						$fieldname_cols{$f->name}{$idx}= $f;
						$found{refaddr $f}= 1;
					}
				}
				# If successfully matched exactly one field, add it to the 'following' set.
				if ($colmap[$idx] && @{$colmap[$idx]} == 1) {
					$following{$colmap[$idx][0]->name}= $colmap[$idx][0];
				}
				# Else if no matches, or ambiguous, so reset the following set
				else {
					%following= ();
				}
			}
		}
		# Check if any of the 'follows' fields were required
		if (my @unfound= grep +($_->required && !$found{refaddr $_}), @follows_fields) {
			push @{$attempt->{missing_required}}, @unfound;
			push @{$attempt->{messages}}, [ error =>
				sprintf('No match for required %s [%s]',
					(@unfound > 1? 'fields':'field'),
					join(', ', map $_->name, sort @unfound))
			];
		}
	}

	# Make the list of columns which didn't match anything before starting to munge things
	# related to ambiguities.
	my @unmatched= grep !defined $colmap[$_], 0 .. $#$header;
	$attempt->{unmatched}= \@unmatched if @unmatched;

	# Ambiguity check: each field *name* may only be located in one column, unless
	# the field(s) are flagged as being arrays.
	my %ambiguous_fields;
	for my $name (sort keys %fieldname_cols) {
		my $cols= $fieldname_cols{$name};
		next unless keys %$cols > 1;
		next unless grep !$_->array, values %$cols;
		push @{$attempt->{messages}}, [ $ambiguous_log_level =>
			sprintf "Found field '%s' at multiple columns: %s",
				$name, join(', ', map 1+$_, sort { $a <=> $b } keys %$cols)
		];
		$ambiguous_fields{$name}= $cols;
	}
	$attempt->{ambiguous_fields}= \%ambiguous_fields
		if keys %ambiguous_fields;

	# Ambiguity check: there must be only one field claiming each column
	# If it's OK, resolve the arrayref down to its single member.
	my $col_collision= 0;
	for my $idx (0 .. $#colmap) {
		next unless defined $colmap[$idx];
		if (@{$colmap[$idx]} == 1) { # only claimed by one field
			my $f= $colmap[$idx][0];
			# but if that one field is ambiguous, discard it
			$colmap[$idx]= $ambiguous_fields{$f->name}? undef : $f;
		} else {
			push @{$attempt->{messages}}, [ $ambiguous_log_level =>
				sprintf "Column %d claimed by multiple fields: %s",
					$idx+1, join(', ', sort map $_->name, @{$colmap[$idx]})
			];
			$attempt->{ambiguous_columns}{$idx}= $colmap[$idx];
			$colmap[$idx]= undef;
		}
	}

	# Need to have found at least one column (even if none required)
	unless (grep defined, @colmap) {
		push @{$attempt->{messages}}, [
			error => ($attempt->{ambiguous_columns} || $attempt->{ambiguous_fields})
			? 'All matching headers were ambiguous'
			: 'No field headers matched'
		];
		return 0;
	}

	return 0
		if $attempt->{missing_required}
		or $self->on_ambiguous_columns ne 'warn'
			&& ($attempt->{ambiguous_columns} || $attempt->{ambiguous_fields});

	# Now, if there are any un-claimed columns, handle per 'on_unknown_columns' setting.
	if (@unmatched) {
		my $act= $self->on_unknown_columns;
		my $unknown_list= join(', ', map $self->_fmt_header_text($header->[$_]), @unmatched);
		$act= $act->($self, $header, \@unmatched) if ref $act eq 'CODE';
		if ($act eq 'warn' || $act eq 'use') { # 'use' is back-compat, 'warn' is official now.
			push @{$attempt->{messages}}, [ warn => 'Ignoring unknown columns: '.$unknown_list ];
		} elsif ($act eq 'error' || $act eq 'next') { # 'next' is back-compat, 'error' is official now.
			push @{$attempt->{messages}}, [ error => 'Would match except for unknown columns: '.$unknown_list ];
			return 0;
		} else {
			push @{$attempt->{messages}}, [ error =>
				$act eq 'die'? "${context}Header row includes unknown columns: $unknown_list"
				: "Invalid action '$act' for 'on_unknown_columns'"
			];
			$attempt->{fatal}= 1;
			return 0;
		}
	}
	return 1;
}
# Make header string readable for log messages
sub _fmt_header_text {
	shift if ref $_[0];
	my $x= shift;
	$x =~ s/ ( [^[:print:]] ) / sprintf("\\x%02X", ord $1 ) /gex;
	qq{"$x"};
}
# format the colmap into a string
sub _colmap_progress_str {
	my ($colmap, $headers)= @_;
	join(' ', map {
		$colmap->{$_}? $_.'='.$colmap->{$_}->name
		             : $_.':'._fmt_header_text($headers->[$_])
		} 0 .. $#$headers)
}


sub iterator {
	my $self= shift;
	my $fields= $self->fields;
	$self->table_search_results->{found}
		or croak "table_search_results does not contain 'found'";
	# Creating the record iterator consumes the data source's iterator.
	# The first time after detecting the table, we continue with the same iterator.
	# Every time after that we need to create a new data iterator and seek to the
	# first record under the header.
	my $data_iter= delete $self->table_search_results->{found}{_data_iter};
	unless ($data_iter) {
		$data_iter= $self->decoder->iterator;
		$data_iter->seek($self->table_search_results->{found}{first_record_pos});
	}
	my $col_map=   $self->table_search_results->{found}{col_map};
	my $field_map= _field_map($col_map);
	my @row_slice; # one column index per field, and possibly more for array_val_map
	my @arrayvals; # list of source index and destination index for building array values
	my @field_names; # ordered list of field names where row slice should be assigned
	my %trimmer;   # list of trim functions and the array indicies they should be applied to
	my @blank_val; # blank value per each fetched column
	my @type_check;# list of 
	my $class;     # optional object class for the resulting rows

	# If result is array, the slice of the row must match the position of the fields in the
	#  $self->fields array.  If a field was not found it will get an undef for that slot.
	# It also results in an undef for secondary fields of the same name as the first.
	if ($self->record_class eq 'ARRAY') {
		my %remaining= %$field_map;
		@row_slice= map {
			my $src= delete $remaining{$_->name};
			defined $src? $src : 0x7FFFFFFF
			} @$fields;
	}
	# If result is anything else, then only slice out the columns that are used for the fields
	# that we located.
	else {
		$class= $self->record_class
			unless 'HASH' eq $self->record_class;
		@field_names= keys %$field_map;
		@row_slice= values %$field_map;
	}
	# For any field whose value is an array of more that one source column,
	#  encode those details in @arrayvals, and update @row_slice and @trim_idx accordingly
	for (0 .. $#row_slice) {
		if (!ref $row_slice[$_]) {
			my $field= $col_map->[$row_slice[$_]];
			if (my $t= $field->trim_coderef) {
				$trimmer{$t} ||= [ $t, [] ];
				push @{ $trimmer{$t}[1] }, $_;
			}
			push @blank_val, $field->blank;
			push @type_check, $self->_make_validation_callback($field, $_)
				if $field->type;
		}
		else {
			# This field is an array-value, so add the src columns to @row_slice
			#  and list it in @arrayvals, and update @trim_idx if needed
			my $src= $row_slice[$_];
			$row_slice[$_]= 0x7FFFFFFF;
			my $from= @row_slice;
			push @row_slice, @$src;
			push @arrayvals, [ $_, $from, scalar @$src ];
			for ($from .. $#row_slice) {
				my $field= $col_map->[$row_slice[$_]];
				if (my $t= $field->trim_coderef) {
					$trimmer{$t} ||= [ $t, [] ];
					push @{ $trimmer{$t}[1] }, $_;
				}
				push @blank_val, $field->blank;
				push @type_check, $self->_make_validation_callback($field, $_)
					if $field->type;
			}
		}
	}
	my @trim= values %trimmer;
	@arrayvals= reverse @arrayvals;
	my ($n_blank, $first_blank, $eof);
	my $sub= sub {
		again:
		# Pull the specific slice of the next row that we need
		my $row= !$eof && $data_iter->(\@row_slice)
			or ++$eof && return undef;
		# Apply 'trim' to any column whose field requested it
		for my $t (@trim) {
			$t->[0]->() for grep defined, @{$row}[@{$t->[1]}];
		}
		# Apply 'blank value' to every column which is zero length
		$n_blank= 0;
		$row->[$_]= $blank_val[$_]
			for grep { (!defined $row->[$_] || !length $row->[$_]) && ++$n_blank } 0..$#$row;
		# If all are blank, then handle according to $on_blank_row setting
		if ($n_blank == @$row) {
			$first_blank ||= $data_iter->position;
			goto again;
		} elsif ($first_blank) {
			# At the end of a series of blank rows, run the callback to decide what to do
			unless ($self->_handle_blank_row($first_blank, $data_iter->position)) {
				$eof= 1;
				return undef;
			}
			$first_blank= undef;
		}
		# Check type constraints, if any
		if (@type_check) {
			if (my @failed= map $_->($row), @type_check) {
				$self->_handle_validation_fail(\@failed, $row, $data_iter->position.': ')
					or goto again;
			}
		}
		# Collect all the array-valued fields from the tail of the row
		$row->[$_->[0]]= [ splice @$row, $_->[1], $_->[2] ] for @arrayvals;
		# stop here if the return class is 'ARRAY'
		return $row unless @field_names;
		# Convert the row to a hashref
		my %rec;
		@rec{@field_names}= @$row;
		# Construct a class, if requested, else return hashref
		return $class? $class->new(\%rec) : \%rec;
	};
	return Data::TableReader::_RecIter->new(
		$sub, { data_iter => $data_iter, reader => $self },
	);
}

sub _make_validation_callback {
	my ($self, $field, $index)= @_;
	my $t= $field->type;
	my $c= $field->coerce;
	$index =~ /^[0-9]+\Z/ or die "$index"; # sanity check for security, since using eval
	# The validate can either be Type::Tiny or a coderef that inspects $_ and returns the error.
	my $validate_fn= ref $t eq 'CODE'? '$t->'
		: $t->can('validate')         ? '$t->validate'
		: croak "Invalid type constraint $t on field ".$field->name;
	# Coerce can either be Type::Tiny or a coderef that inspects $_[0] and returns the coerced value.
	my $coerce_fn= ref $c eq 'CODE'? '$c->'
		: $c && (!$t->can('has_coercions') || $t->has_coercions)? '$t->coerce'
		: undef;
	my $field_lvalue= '$_[0]['.$index.']';
	my $code= 'sub { my $e= '.$validate_fn.'('.$field_lvalue.'); ';
	if (defined $coerce_fn) {
		$code .= 'if (defined $e) {'
		      .  '  my $tmp= '.$coerce_fn.'('.$field_lvalue.');'
		      .  '  ('.$field_lvalue.', $e)= ($tmp) unless defined '.$validate_fn.'($tmp);'
		      .  '}';
	}
	$code .= 'defined $e? ([ $field, '.$index.', $e ]) : () }';
	return eval($code) || die "error compiling validation callback: $@";
}

sub _handle_blank_row {
	my ($self, $first, $last)= @_;
	my $act= $self->on_blank_row;
	$act= $act->($self, $first, $last)
		if ref $act eq 'CODE';
	if ($act eq 'next') {
		$self->_log->('warn', 'Skipping blank rows from %s until %s', $first, $last);
		return 1;
	}
	if ($act eq 'last') {
		$self->_log->('warn', 'Ending at blank row %s', $first);
		return 0;
	}
	if ($act eq 'die') {
		my $msg= "Encountered blank rows at $first..$last";
		$self->_log->('error', $msg);
		croak $msg;
	}
	croak "Invalid value for 'on_blank_row': \"$act\"";
}

sub _handle_validation_fail {
	my ($self, $failures, $values, $context)= @_;
	my $act= $self->on_validation_fail;
	$act= $act->($self, $failures, $values, $context)
		if ref $act eq 'CODE';
	my $errors= join(', ', map $_->[0]->name.': '.$_->[2], @$failures);
	if ($act eq 'next') {
		$self->_log->('warn', "%sSkipped for data errors: %s", $context, $errors) if $errors;
		return 0;
	}
	if ($act eq 'use') {
		$self->_log->('warn', "%sPossible data errors: %s", $context, $errors) if $errors;
		return 1;
	}
	if ($act eq 'die') {
		my $msg= "${context}Invalid record: $errors";
		$self->_log->('error', $msg);
		croak $msg;
	}
}

BEGIN { @Data::TableReader::_RecIter::ISA= ( 'Data::TableReader::Iterator' ) }
sub Data::TableReader::_RecIter::all {
	my $self= shift;
	my (@rec, $x);
	push @rec, $x while ($x= $self->());
	return \@rec;
}
sub Data::TableReader::_RecIter::position {
	shift->_fields->{data_iter}->position(@_);
}
sub Data::TableReader::_RecIter::progress {
	shift->_fields->{data_iter}->progress(@_);
}
sub Data::TableReader::_RecIter::tell {
	shift->_fields->{data_iter}->tell(@_);
}
sub Data::TableReader::_RecIter::seek {
	shift->_fields->{data_iter}->seek(@_);
}
sub Data::TableReader::_RecIter::next_dataset {
	shift->_fields->{reader}->_log
		->('warn',"Searching for subsequent table headers is not supported yet");
	return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TableReader - Extract records from "dirty" tabular data sources

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  # Find a row in the Excel file containing the headers
  #   "address", "city", "state", "zip" (in any order)
  # and then convert each row under that into a hashref of those fields.
  
  my $records= Data::TableReader>new(
      input => 'path/to/file.xlsx',
      fields => [qw( address city state zip )],
    )
    ->iterator->all;

but there are plenty of options to choose from...

  my $tr= Data::TableReader->new(
    # path or file handle
    # let it auto-detect the format (but can override that if we need)
    input => 'path/to/file.csv',
    
    # We want these fields to exist in the file (identified by headers)
    fields => [
      { name => 'address', header => qr/street|address/i },
      'city',
      'state',
      # can validate with Type::Tiny classes
      { name => 'zip', header => qr/zip\b|postal/i, type => US_Zipcode },
    ],
    
    # Our data provider is horrible; just ignore any nonsense we encounter
    on_blank_row => 'next',
    on_validation_fail => 'next',
    
    # Capture warnings and show to user who uploaded file
    log => \(my @messages)
  );
  
  my $records= $tr->iterator->all;
  ...
  $http_response->body( encode_json({ messages => \@messages }) );

=head1 DESCRIPTION

This module is designed to take "loose" or "dirty" tabular data sources
(such as Excel, CSV, TSV, or HTML) which may have been edited by non-technical
humans and extract the data into sanitized records, while also verifying that
the data file contains roughly the schema you were expecting.  It is primarily
intended for making automated imports of data from non-automated or unstable
sources, and providing human-readable feedback about the validity of the data
file.

=head1 ATTRIBUTES

=head2 input

This can be a file name, L<Path::Class> instance, file handle, arrayref, or
L<Spreadsheet::ParseExcel::Worksheet> object.  If you supply a file handle,
it must be seekable in order to auto-detect the file format, I<or> you may
specify the decoder directly to avoid auto-detection.  Arrayrefs are passed to
the L<'Mock' decoder|Data::TableReader::Decoder::Mock> which just returns the
data as-is.

=head2 decoder

This is either an instance of L<Data::TableReader::Decoder>, or a class name,
or a partial class name to be appended as C<"Data::TableReader::Decoder::$name">
or an arrayref or hashref of arguments to build the decoder.

In an arrayref the first argument can be undef, and in a hashref the CLASS
argument can be missing or undef. In those cases it will be detected from the
input attribute and any default arguments combined with (and if necessary
trumped by) the extra arguments in the arrayref or hashref.

Examples:

  'CSV'
  # becomes Data::TableReader::Decoder::CSV->new()
  
  [ 'CSV', sep_char => "|" ]
  # becomes Data::TableReader::Decoder::CSV->new(sep_char => "|")
  
  { CLASS => 'CSV', sep_char => "|" }
  # becomes Data::TableReader::Decoder::CSV->new({ sep_char => "|" })

=head2 fields

An arrayref of L<Data::TableReader::Field> objects which this module should
search for within the tables (worksheets etc.) of L</input>.

If an element of this array is a hashref or string, it will be coerced to an
instance of L<Data::TableReader::Field>, with plain strings becoming the
C<name> attribute.  See L<Data::TableReader::Field/header> for how names are
automatically converted to the header-matching regex.

There are some convenience accessors for the fields:

=over

=item field_list

List access for C<< @{ $reader->fields } >>

=item field_by_name

Map of C<< { $field->name => $field } >>.  If you have multiple fields of the
same name (allowed, but not recommended) the value is the first per the order
of C<field_list>.

=item field_by_addr

Map of C<< { refaddr($field) => $field } >>.

=back

=head2 record_class

Default is the special value C<'HASH'> for un-blessed hashref records.
The special value C<'ARRAY'> will result in arrayrefs with fields in the same
order they were specified in the L</fields> specification.
Setting it to anything else will return records created with
C<< $record_class->new(\%fields); >>

=head2 static_field_order

Boolean, whether the L</fields> must be found in columns in the exact order
that they were specified.  Default is false.

=head2 header_row_at

Row number, or range of row numbers where the header must be found.
(All row numbers in this module are 1-based, to match end-user expectations.)
The default is C<[1,10]> to limit header scanning to the first 10 rows.
As a special case, if you are reading a source which lacks headers and you
trust the source to deliver the columns in the right order, you can set this
to undef if you also set C<< static_field_order => 1 >>.

=head2 col_map

This is an arrayref, one element per column of input data, listing which field was detected
to come from that column.  If you specify this to the constructor, L</find_table> will respect
any defined element of the array, but still search for matching headers in the undefined
columns.  After a successful L</find_table>, C<col_map> is changed to refer to the same hash as
C<< ->table_search_results->{found}{col_map} >>.  (If you wanted to re-run the search for the
table, you need to both C<clear_table_search_results> I<and> reset C<col_map> to whatever
you passed to the constructor.)

For backward compatibility, if you did not specify this attribute to the constructor and try
accessing it before calling L</find_table>, it automatically calls L</find_table> for you
(and die if it fails).

=head2 has_col_map

Check whether col_map has been defined, to avoid lazy-building it.

=head2 table_search_results

This is the output of the most recent L</find_table> operation.

  {
    candidates => [
      { row_idx => $n,
        dataset_idx => $n,
        col_map => [ $field_or_undef, $field_or_undef, ... ],
        missing_required => \@fields,
        ambiguous_columns => { $col_idx => \@fields, ... },
        ambiguous_fields => { $field_name => { $col_idx => $field }, ... },
        unmatched => \@col_idx,
        messages => [],
      },
      ...
    ],
    found => $ref_to_candidate, # undef if find_table failed
  }

The fields describing problems (C<missing_required>, C<ambiguous_columns>, C<ambiguous_fields>,
and C<unmatched>) are not present unless they contain data.
All C<@fields> are refs to the actual Field objects.  C<col_map> has one element per element
of the header row.  If C<missing_required> is populated, the analysis of ambiguity may be
incomplete, because missing required columns abort the search for the header.
All C<"_idx"> values are 0-based, but the errors in C<messages> use 1-based descriptions.

=head2 has_table_search_results, clear_table_search_results

Predicate and clearer for lazy-built table_search_results.

=head2 on_partial_match

  on_partial_match    => 'next'    # keep searching for a better line of headers
  on_partial_match    => 'last'    # return failure from ->find_table
  on_partial_match    => sub {
    my ($reader, $candidate, $header_row)= @_;
    return $action; # one of the above values
  }

During L</find_table>, if a row is found that matches at least one header, but fails to match
all the requirements (required columns, unknown or ambiguous columns if those are configured as
an error) you can either keep searching for a better header row, or stop here.  The default is
'next', to keep searching, but this may result in a lot of noise.  The 'last' setting allows
you to stop after a likely header row.

If you supply a coderef, you receive the "candidate" info described in L</table_search_results>.

=head2 on_ambiguous_columns

  on_ambiguous_columns => 'warn'    # warn, and omit from the match
  on_ambiguous_columns => 'error'   # fail the header match for this row

During L</find_table>, when matching a field's header pattern vs. the columns of a row, if the
pattern could match more than one cell it is an error.  You might want to handle it
in various ways:

=over

=item C<'warn'>

If a Field matches multiple columns (and isn't an array field) omit the field from the col_map
entirely.  If a column matches multiple fields, leave the col_map blank for this column.
Both generate warnings, but the header match can still proceeed to a successful result.

=item C<'error'> (default)

Any ambiguities (field matching multiple columns, multiple fields matching a column) cause the
match of the header on this row to fail.  Further attempts at finding the header depend on the
L</on_partial_headers> setting.

=back

=head2 on_unknown_columns

  on_unknown_columns => 'warn'  # warn, and then accept these headers
  on_unknown_columns => 'error' # fail the header match for this row
  on_unknown_columns => sub {
    my ($reader, $col_headers)= @_;
    ...;
    return $opt; # one of the above values
  }

This determines handling for columns that aren't associated with any field.
The "required" columns must all be found before it considers this setting, but once it has
found everything it needs to make this a candidate, you might or might not care about the
leftover columns.

=over

=item C<'warn'>  (default)

You don't care if there are extra columns, just log warnings about them and proceed extracting
from this table.

=item C<'error'>

Extra columns mean that you didn't find the table you wanted.  Log the near-miss, and
keep searching additional rows or additional tables, according to L</on_partial_headers>.

=item C<sub {}>

You can add your own logic to handle this.  Inspect the headers however you like, and then
return one of the above values.

=back

=head2 on_blank_rows

  on_blank_rows => 'next' # warn, and then skip the row(s)
  on_blank_rows => 'last' # warn, and stop iterating the table
  on_blank_rows => 'die'  # fatal error
  on_blank_rows => 'use'  # actually try to return the blank rows as records
  on_blank_rows => sub {
    my ($reader, $first_blank_rownum, $last_blank_rownum)= @_;
    ...;
    return $opt; # one of the above values
  }

This determines what happens when you've found the table, are extracting
records, and encounter a series of blank rows (defined as a row with no
printable characters in any field) followed by non-blank rows.
If you use the callback, it suppresses the default warning, since you can
generate your own.

The default is C<'next'>.

=head2 on_validation_fail

  on_validation_fail => 'next'  # warn, and then skip the record
  on_validation_fail => 'use'   # warn, and then use the record anyway
  on_validation_fail => 'die'   # fatal error
  on_validation_fail => sub {
    my ($reader, $failures, $values, $context)= @_;
    for (@$failures) {
      my ($field, $value_index, $message)= @$_;
      ...
      # $field is a Data::TableReader::Field
      # $values->[$value_index] is the string that failed validation
      # $message is the error returned from the validation function
      # $context is a string describing the source of the row, like "Row 5"
      # You may modify $values to alter the record that is about to be created
    }
    # Clear the failures array to suppress warnings, if you actually corrected
    # the validation problems.
    @$failures= () if $opt eq 'use';
    # return one of the above constants to tell the iterator what to do next
    return $opt;
  }

This determines what happens when you've found the table, are extracting
records, and one row fails its validation.  In addition to deciding an option,
the callback gives you a chance to alter the record before C<'use'>ing it.
If you use the callback, it suppresses the default warning, since you can
generate your own.

The default is 'die'.

=head2 log

If undefined (the default) all log messages above 'info' will be emitted with
C<warn "$message\n">.  If set to an object, it should support an API of:

  trace,  is_trace
  debug,  is_debug
  info,   is_info
  warn,   is_warn
  error,  is_error

such as L<Log::Any> and may other perl logging modules use.  You can also
set it to a coderef such as:

  my @messages;
  sub { my ($level, $message)= @_;
    push @messages, [ $level, $message ]
      if grep { $level eq $_ } qw( info warn error );
  };

for a simple way to capture the messages without involving a logging module.
And for extra convenience, you can set it to an arrayref which will receive
any message that would otherwise have gone to 'warn' or 'error'.

=head1 METHODS

=head2 detect_input_format

   my ($class, @args)= $tr->detect_input_format( $filename, $head_of_file );

This is used internally to detect the format of a file, but you can call it manually if you
like.  The first argument (optional) is a file name, and the second argument (also optional)
is the first few hundred bytes of the file.  Missing arguments will be pulled from L</input>
if possible.  The return value is the best guess of module name and constructor arguments that
should be used to parse the file.  However, this doesn't guarantee such module actually exists
or is installed; it might just echo the file extension back to you.

=head2 find_table

  if ($tr->find_table) { ... }

Search through the input for the beginning of the records, identified by a header row matching
the various constraints defined in L</fields>.  If L</header_row_at> is C<undef>, then this does
nothing and assumes success.

Returns a boolean of whether it succeeded.  This method does I<not> C<croak> on failure like
L</iterator> does, on the assumption that you want to handle them gracefully.
All diagnostics about the search are logged via L</log>, but also reported in
L</table_search_results>.

=head2 field_map

Build a hashref of C<< { $field_name => $col_idx_or_arrayref } >>  for the current L</col_map>.
If the field is defined as an array field, the value will be an arrayref (even if only found in
one column).  Otherwise, the value is a simple scalar of the column index.

=head2 iterator

  my $iter= $tr->iterator;
  while (my $rec= $iter->()) { ... }

Create an iterator.  If the table has not been located, then find it and C<croak> if it
can't be found.  Depending on the decoder and input filehandle, you might only be able to
have one instance of the iterator at a time.

The iterator derives from L<Data::TableReader::Iterator> but also has a method "all" which
returns all records in an arrayref.

  my $records= $tr->iterator->all;

=head1 THANKS

Portions of this software were funded by
L<Ellis, Partners in Management Solutions|http://www.epmsonline.com/>
and L<Candela Corporation|https://www.candelacorp.com/>.

=head1 AUTHOR

Michael Conrad <mike@nrdvana.net>

=head1 CONTRIBUTOR

=for stopwords Christian Walde

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Michael Conrad.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
