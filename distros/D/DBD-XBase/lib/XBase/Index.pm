
=head1 NAME

XBase::Index - base class for the index files for dbf

=cut

package XBase::Index;
use strict;
use vars qw( @ISA $DEBUG $VERSION $VERBOSE $BIGEND );
use XBase::Base;
@ISA = qw( XBase::Base );

$VERSION = '1.05';

$DEBUG = 0;

$VERBOSE = 0 unless defined $VERBOSE;

# We will setup global variable to denote the byte order (endian)
my $packed = pack('d', 1);
if ($packed eq "\077\360\000\000\000\000\000\000") {
	$BIGEND = 1;
} elsif ($packed eq "\000\000\000\000\000\000\360\077") {
	$BIGEND = 0;
} else {
	die "XBase::Index: your architecture is not supported.\n";
}

# Open appropriate index file and create object according to suffix
sub new {
	my ($class, $file) = (shift, shift);
	my @opts = @_;
print "XBase::Index::new($class, $file, @_)\n" if $XBase::Index::VERBOSE;
	if (ref $class) { @opts = ('dbf', $class, @opts); }
	my ($ext) = ($file =~ /\.(...)$/);
	$ext = lc $ext;

	if ($ext eq 'sdbm' or $ext eq 'pag' or $ext eq 'dir') {
		require XBase::SDBM;
		$ext = 'SDBM';
	}

	my $object = eval "new XBase::$ext \$file, \@opts";
	return $object if defined $object;

	__PACKAGE__->Error("Error loading index: unknown extension\n") if $@;
	return;
}

# For XBase::*x object, a record is one page, object XBase::*x::Page here
sub get_record {
	my ($self, $num) = @_;
	return $self->{'pages_cache'}{$num}
			if defined $self->{'pages_cache'}{$num};

	my $newpage = (ref $self) . '::Page::new';
	my $page = $self->$newpage($num);

	if (defined $page) {
		$self->{'pages_cache'}{$num} = $page;

		local $^W = 0;
		print "Page $page->{'num'}:\tkeys: @{[ map { s/\s+$//; $_; } @{$page->{'keys'}}]}\n\tvalues: @{$page->{'values'}}\n" if $DEBUG;
		print "\tlefts: @{$page->{'lefts'}}\n" if defined $page->{'lefts'} and $DEBUG;
	}
	$page;
}

# Get next (value, record number in dbf) pair
# The important values of the index object are 'level' holding the
# current level of the "cursor", 'pages' holding an array of pages
# currently open for each level and 'rows' with an array of current row
# in each level
sub fetch {
	my $self = shift;
	my ($level, $page, $row, $key, $val, $left);
	
	# cycle while we get to the leaf record or otherwise get
	# a real value, not a pointer to lower page
	while (not defined $val)
		{
		$level = $self->{'level'};

		# if we do not have level, let's start from zero
		if (not defined $level) {
			$level = $self->{'level'} = 0;
			$page = $self->get_record($self->{'start_page'});
			if (not defined $page) {
				$self->Error("Index corrupt: $self: no root page $self->{'start_page'}\n");
				return;
			}
			# and initialize 'pages' and 'rows'
			$self->{'pages'} = [ $page ];
			$self->{'rows'} = [];
		}

		# get current page for this level
		$page = $self->{'pages'}[$level];
		if (not defined $page) {
			$self->Error("Index corrupt: $self: page for level $level lost in normal course\n");
			return;
		}

		# get current row for current level and increase it
		# (or setup to zero)
		my $row = $self->{'rows'}[$level];
		if (not defined $row) {
			$row = $self->{'rows'}[$level] = 0;
		} else {
			$self->{'rows'}[$level] = ++$row;
		}

		# get the (key, value, pointer) from the page
		($key, $val, $left) = $page->get_key_val_left($row);

		# there is another page to walk
		if (defined $left) {
			# go deeper
			$level++;
			my $oldpage = $page;
			# load the next page
			$page = $self->get_record($left);
			if (not defined $page) {
				$self->Error("Index corrupt: $self: no page $left, ref'd from $oldpage, row $row, level $level\n");
				return;
			}
			# and put it into the structure
			$self->{'pages'}[$level] = $page;
			$self->{'rows'}[$level] = undef;
			$self->{'level'} = $level;
			# and even if some index structures allow the
			# value in the same row as record, we want to
			# skip it when going down
			$val = undef;
			next;
		}
		# if we're lucky and got the value, return it	
		if (defined $val) {
			return ($key, $val);
		}
		# we neither got link to lower page, nor the value
		# so it means we are backtracking the structure one
		# (or more) levels back
		else {
			$self->{'level'} = --$level;	# go up the levels
			return if $level < 0;		# do not fall over 
			$page = $self->{'pages'}[$level];
			if (not defined $page)
				{
				$self->Error("Index corrupt: $self: page for level $level lost when backtracking\n");
				return;
			}
			### next unless defined $page;
			$row = $self->{'rows'}[$level];
			my ($backkey, $backval, $backleft) = $page->get_key_val_left($row);
			# this is a hook for ntx files where we do not
			# want to miss a values that are stored inside
			# the structure, not only in leaves.
			if (not defined $page->{'last_key_is_just_overflow'} and defined $backleft and defined $backval) {
				return ($backkey, $backval);
			}
		}
	}
	return;	
}

# Get list of tags in the indexfile (an indexfile may not have any)
sub tags {
	my $self = shift;
	@{$self->{'tags'}} if defined $self->{'tags'};
}

# Method allowing to refetch the active values (key, val) without
# rolling forward
sub fetch_current {
	my $self = shift;
	my $level = $self->{'level'};
	my $page = $self->{'pages'}[$level];
	my $row = $self->{'rows'}[$level];
	my ($key, $val, $left) = $page->get_key_val_left($row);
	return ($key, $val);
}

# Rewind the index to start
# the easiest way to do this is to cancel the 'level' -- this way we
# do not know where we are and we have to start anew
sub prepare_select {
	my $self = shift;
	delete $self->{'level'};
	delete $self->{'pages'};
	delete $self->{'rows'};
	1;
}

# Position index to a value (or behind it, if nothing found), so that
# next fetch fetches the correct value
sub prepare_select_eq {
	my ($self, $eq, $recno) = @_;
	$self->prepare_select();		# start from scratch

### { local $^W = 0; print STDERR "Will look for $eq $recno\n"; }

	my $left = $self->{'start_page'};
	my $level = 0;
	my $parent = undef;
	
	# we'll need to know if we want numeric or string compares
	my $numdate = ($self->{'key_type'} ? 1 : 0);

	while (1) {
		my $page = $self->get_record($left);	# get page
		if (not defined $page) {
			$self->Error("Index corrupt: $self: no page $left for level $level\n");
			return;
		}
		my $row = 0;
		my ($key, $val);
		my $empty = 1;
		while (($key, $val, my $newleft) = $page->get_key_val_left($row)) {
### { local $^W = 0; print "Got: $key, $val, $newleft ($numdate)\n"; }

			$empty = 0;	# There is at least 1 key
			$left = $newleft;
# Joe Campbell says:
# Compound char keys have two parts preceded by white space
# get rid of the white space so that I can do a matching....
# and suggests
#			$key =~ s/^\s*//g;


			# finish if we are at the end of the page or
			# behind the correct value
			if (not defined $key)
				{ last; }
			if ($numdate == 1 ? $key >= $eq : $key ge $eq)
				{ last; }
			$row++;
		}
		
		# we know where we are positioned on the page now
		$self->{'pages'}[$level] = $page;
		$self->{'rows'}[$level] = $row;

		# if there is no lower level
		if ($empty or not defined $left) {
			$self->{'rows'}[$level] = ( $row ? $row - 1: undef);
			$self->{'level'} = $level;
			last;
		}
		$page->{'parent'} = $parent->{'num'} if defined $parent;
		$parent = $page;
		$level++;
	}
	if (defined $recno) {		# exact match requested
		# get current values
		my ($key, $val) = $self->fetch_current;
		while (defined $val) {
			last if ($numdate ? $key > $eq : $key gt $eq);

			# if we're here, we still have exact match
			last if $val == $recno;

			# move forward
			($key, $val) = $self->fetch;
		}
	}
	1;
}

# Get (key, dbf record number, lower page index) from the index page
sub get_key_val_left {
	my ($self, $num) = @_;
	{
		local $^W = 0;
		my $printkey = $self->{'keys'}[$num];
		$printkey =~ s/\s+$//;
		$printkey =~ s/\000/\\0/g;
		print "Getkeyval: Page $self->{'num'}, row $num: $printkey, $self->{'values'}[$num], $self->{'lefts'}[$num]\n"
					if $DEBUG > 5;
	return ($self->{'keys'}[$num], $self->{'values'}[$num], $self->{'lefts'}[$num])
				if $num <= $#{$self->{'keys'}};
	}
	return;
}

sub num_keys {
	$#{shift->{'keys'}};
}

sub delete {
	my ($self, $key, $value) = @_;
	print "XBase::Index::delete($key, $value) called ($self->{'tag'} -> $self->{'key_string'}/$self->{'for_string'})\n" if $XBase::Index::VERBOSE;
	$self->prepare_select_eq($key, $value) or return;
	my ($foundkey, $foundvalue) = $self->fetch_current;

	if (defined $foundvalue
			and $foundkey eq $key and $foundvalue == $value) {
		$self->delete_current;
		return 1;
	}
	print "$key/$value is not in the index (wanted to delete)\n" if $XBase::Index::VERBOSE;
	undef;
}
sub insert {
	my ($self, $key, $value) = @_;
	print "XBase::Index::insert($key, $value) called\n" if $XBase::Index::VERBOSE;

	$self->prepare_select_eq($key, $value) or return;
	my ($foundkey, $foundvalue) = $self->fetch_current;

	if (defined $foundvalue
			and $foundkey eq $key and $foundvalue == $value) {
		print STDERR "Already found, strange.\n";
		return;
	}

	$self->insert_before_current($key, $value);
}

sub delete_current {
	my $self = shift;
	print "Delete_current called\n" if $XBase::Index::VERBOSE;
	my $level = $self->{'level'};
	my $page = $self->{'pages'}[$level];
	my $row = $self->{'rows'}[$level];

	splice @{$page->{'values'}}, $row, 1;
	splice @{$page->{'keys'}}, $row, 1;
	splice @{$page->{'lefts'}}, $row, 1;

	$self->{'rows'}[$level]--;
	if ($self->{'rows'}[$level] < 0) {
		$self->{'rows'}[$level] = undef;
	}

	$page->write_with_context;

	delete $self->{'pages_cache'};

	print STDERR "Delete_current returning\n" if $DEBUG;
}

sub insert_before_current {
	my ($self, $key, $value) = @_;
	print "Insert_current called ($key $value)\n" if $XBase::Index::VERBOSE;
	my $level = $self->{'level'};
	my $page = $self->{'pages'}[$level];
	my $row = $self->{'rows'}[$level];
	$row = 0 unless defined $row;

	# update keys and values and then call save
	splice @{$page->{'keys'}}, $row, 0, $key;
	splice @{$page->{'values'}}, $row, 0, $value;
	splice @{$page->{'lefts'}}, $row, 0, undef if defined $page->{'lefts'};

	$page->write_with_context;

	delete $self->{'pages_cache'};

	print STDERR "Insert_current returning\n" if $DEBUG;
}

# #############
# dBase III NDX

package XBase::ndx;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::Base XBase::Index );

*DEBUG = \$XBase::Index::DEBUG;

sub read_header {
	my $self = shift;
	my %opts = @_;
	my $header;
	$self->{'dbf'} = $opts{'dbf'};
	$self->{'fh'}->read($header, 512) == 512 or do
		{ __PACKAGE__->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
	@{$self}{ qw( start_page total_pages key_length keys_per_page
		key_type key_record_length unique key_string ) }
		= unpack 'VV @12vvvv @23c a*', $header;
	
	$self->{'key_string'} =~ s/[\000 ].*$//s;
	$self->{'record_len'} = 512;
	$self->{'header_len'} = 0;

	$self;
}

sub last_record {
	shift->{'total_pages'};
}

package XBase::ndx::Page;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::ndx );

*DEBUG = \$XBase::Index::DEBUG;

# Constructor for the ndx page
sub new {
	my ($indexfile, $num) = @_;
	my $parent;
	# we can be called from parent page
	if ((ref $indexfile) =~ /::Page$/) {			
		$parent = $indexfile;
		$indexfile = $parent->{'indexfile'};
	}
	
	my $data = $indexfile->read_record($num) or return;	# get 512 bytes
	my $noentries = unpack 'V', $data;			# num of entries
	
	my $keylength = $indexfile->{'key_length'};		
	my $keyreclength = $indexfile->{'key_record_length'};	# length

	print "page $num, noentries $noentries, keylength $keylength\n" if $DEBUG;
	my $numdate = $indexfile->{'key_type'};		# numeric or string?
	
	my $offset = 4;
	my $i = 0;
	my ($keys, $values, $lefts) = ([], [], []);		# three arrays

	# walk the page
	while ($i < $noentries) {
		# get the values for entry
		my ($left, $recno, $key)
			= unpack 'VVa*', substr($data, $offset, $keylength + 8);
		if ($numdate) {			# some decoding for numbers
			$key = reverse $key if $XBase::Index::BIGEND;
			$key = unpack 'd', $key;
		}
		print "$i: \@$offset VVa$keylength -> ($left, $recno, $key)\n" if $DEBUG > 1;
		push @$keys, $key;
		push @$values, ($recno ? $recno : undef);
		$left = ($left ? $left : undef);
		push @$lefts, $left;
		
		if ($i == 0 and defined $left)
			{ $noentries++; }	# fixup for nonleaf page
				### shouldn't this be for last page only?
	}
	continue {
		$i++;
		$offset += $keyreclength;
	}

	my $self = bless { 'keys' => $keys, 'values' => $values,
		'num' => $num, 'keylength' => $keylength,
		'lefts' => $lefts, 'indexfile' => $indexfile }, __PACKAGE__;
	
	if ($num == $indexfile->{'start_page'}
			or (defined
			$parent->{'last_key_is_just_overflow'} and
			$parent->{'lefts'}[$#{$parent->{'lefts'}}] == $num)) {
		$self->{'last_key_is_just_overflow'} = 1;
	}

	$self;
}

# ###########
# Clipper NTX

package XBase::ntx;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::Base XBase::Index );

sub read_header {
	my $self = shift;
	my %opts = @_;
	my $header;
	$self->{'dbf'} = $opts{'dbf'};
	$self->{'fh'}->read($header, 1024) == 1024 or do
		{ __PACKAGE__->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
	
	@{$self}{ qw( signature compiler_version start_offset first_unused
		key_record_length key_length decimals max_item
		half_page key_string unique ) }
			= unpack 'vvVVvvvvvA256c', $header;

	my $key_string = uc $self->{'key_string'};
	$key_string =~ s/^.*?->//;
	$self->{'key_string'} = $key_string;

	if ($self->{'signature'} != 3 and $self->{'signature'} != 6) {
		__PACKAGE__->Error("$self: bad signature value `$self->{'signature'}' found\n");
		return;
	}
	$self->{'key_string'} =~ s/[\000 ].*$//s;
	$self->{'record_len'} = 1024;
	$self->{'header_len'} = 0;
	
	$self->{'start_page'} = int($self->{'start_offset'} / $self->{'record_len'});
	my $field_type;
	if (defined $opts{'type'}) {
		$field_type = $opts{'type'};
	} elsif (defined $self->{'dbf'}) {
		$field_type = $self->{'dbf'}->field_type($key_string);
		if (not defined $field_type) {
			__PACKAGE__->Error("Couldn't find key string `$key_string' in dbf file, can't determine field type\n");
			return;
		}
	} else {
		__PACKAGE__->Error("Index type (char/numeric) unknown for $self\n");
		return;
	}
	$self->{'key_type'} = ($field_type =~ /^[NDIF]$/ ? 1 : 0);

	$self;
}
sub last_record {
	-1;
}


package XBase::ntx::Page;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::ntx );

*DEBUG = \$XBase::Index::DEBUG;

# Constructor for the ntx page
sub new {
	my ($indexfile, $num) = @_;
	my $parent;
	# we could be called from parent page
	if ((ref $indexfile) =~ /::Page$/) {			
		$parent = $indexfile;
		$indexfile = $parent->{'indexfile'};
	}
	my $data = $indexfile->read_record($num) or return;	# get data
	my $maxnumitem = $indexfile->{'max_item'} + 1;	# limit from header
	my $keylength = $indexfile->{'key_length'};
	my $record_len = $indexfile->{'record_len'};	# length

	my $numdate = $indexfile->{'key_type'};		# numeric or string?

	my ($noentries, @pointers) = unpack "vv$maxnumitem", $data;
			# get pointers where the entries are
	
	print "page $num, noentries $noentries, keylength $keylength; pointers @pointers\n" if $DEBUG;
	
	my ($keys, $values, $lefts) = ([], [], []);
	# walk the pointers
	for (my $i = 0; $i < $noentries; $i++) {
		my $offset = $pointers[$i];
		my ($left, $recno, $key)
			= unpack 'VVa*', substr($data, $offset, $keylength + 8);

		if ($numdate) {
			### if looks like with ntx the numbers are
			### stored as ASCII strings or something
			### To Be Done
			if ($key =~ tr!,+*)('&%$#"!0123456789!) { $key = '-' . $key; }
			$key += 0;
		}

		print "$i: \@$offset VVa$keylength -> ($left, $recno, $key)\n" if $DEBUG > 1;
		push @$keys, $key;
		push @$values, ($recno ? $recno : undef);
		$left = ($left ? ($left / $record_len) : undef);
		push @$lefts, $left;

		### if ($i == 0 and defined $left and (not defined $parent or $num == $parent->{'lefts'}[-1]))
		if ($i == 0 and defined $left)
			{ $noentries++; }
				### shouldn't this be for last page only?
	}

	my $self = bless { 'num' => $num, 'indexfile' => $indexfile,
		'keys' => $keys, 'values' => $values, 'lefts' => $lefts, },
								__PACKAGE__;
	$self;
}

# ###########
# FoxBase IDX

package XBase::idx;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::Base XBase::Index );

*DEBUG = \$XBase::Index::DEBUG;

sub read_header {
	my $self = shift;
	my %opts = @_;
	my $header;
	$self->{'dbf'} = $opts{'dbf'};
	$self->{'fh'}->read($header, 512) == 512 or do
		{ __PACKAGE__->Error("Error reading header of $self->{'filename'}: $!\n"); return; };
	@{$self}{ qw( start_page start_free_list total_pages
		key_length index_options index_signature
		key_string for_expression
		) }
		= unpack 'VVVv CC a220 a276', $header;
	
	$self->{'key_record_length'} = $self->{'key_length'} + 4;
	$self->{'key_string'} =~ s/[\000 ].*$//s;
	$self->{'record_len'} = 512;
	$self->{'start_page'} /= $self->{'record_len'};
	$self->{'start_free_list'} /= $self->{'record_len'};
	$self->{'header_len'} = 0;

	if ($opts{'type'} eq 'N') {
		$self->{'key_type'} = 1;
		}

	$self;
}

sub last_record {
	shift->{'total_pages'};
}

sub create {
	my ($class, $table, $filename, $column) = @_;
	my $type = $table->field_type($column);
	if (not defined $type) {
		die "XBase::idx: could determine index type for `$column'\n";
	}
	my $numdate = 0;
	$numdate = 1 if $type eq 'N' or $type eq 'D';

	my $self = bless {}, $class;
	$self->create_file($filename) or die "Error creating `$filename'\n";
	$self->write_to(0, "\000" x 512);
	my $key_length = $table->field_length($column);
	$key_length = 8 if $numdate;

	my $count = int((512 - 12) / ($key_length + 4));
### warn "Key length $key_length, per page $count.\n";

	my $encode_function;
	if ($numdate) {
		$encode_function = sub {
			my $key = pack 'd', shift;
			$key = reverse $key unless $XBase::Index::BIGEND;
			if ((substr($key, 0, 1) & "\200") eq "\200") {
				$key ^= "\377\377\377\377\377\377\377\377";
			} else {
				$key ^= "\200";
			}
			return $key;
		};
	} else {
		$encode_function = sub {
			return sprintf "%-${key_length}s", shift;
		};
	}

	my @data;
	my $last_record = $table->last_record;
	for (my $i = 0; $i <= $last_record; $i++) {
		my ($deleted, $data) = $table->get_record($i, $column);
		push @data, [ $encode_function->($data), $i + 1 ];
	}
	@data = sort { $a->[0] cmp $b->[0] } @data;

	$self->{'header_len'} = 0;	# it is 512 really, but we
					# count from 1, not from 0
	$self->{'record_len'} = 512;

	my $pageno = 1;
	my $level = 1;
	my @newdata;
	while ($level == 1 or @data > 1) {
		last if $pageno > 5;
		my $attributes = 0;
		$attributes = 2 if $level == 1;
		if (scalar(@data) < $count) {
			# we have less than one page, so it's root.
			$attributes++;	
		}

		my $left_page = 0xFFFFFFFF;
		my $current_count = 0;
		my $out = '';
		@newdata = ();
		for (my $i = 0; $i < @data; $i++) {
			my $key = $data[$i][0];
### print STDERR "Page $pageno: $i: @{$data[$i]}\n";
			$out .= pack "a$key_length N", $key, $data[$i][1];
			$current_count++;

			if ($current_count == $count or $i == $#data) {
### print STDERR "Dumping $pageno.\n";
				# time to close this page and move on
				my $right_page = 0xFFFFFFFF;
				if ($i < $#data) {
					$right_page = $pageno + 1;
				}
				$self->write_record($pageno,
					pack 'a512',
						pack('vvVV', $attributes, $current_count,
						$left_page, $right_page)
					. $out);
				push @newdata, [$data[$i][0], $pageno * 512];
				$left_page = $pageno;
				$current_count = 0;
				$pageno++;
				$out = '';
			}
		}

		@data = @newdata;
		$level++;
	}

	my $header = pack 'VVVv CC a220 a276',
		($pageno - 1) * 512, 0xFFFFFFFF, $pageno * 512,
		$key_length, 0, 0, $column, '';
	$self->write_to(0, $header);
	$self->close;

	return new XBase::Index($filename, 'type' => $type);
}

package XBase::idx::Page;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::idx );

*DEBUG = \$XBase::Index::DEBUG;

### $DEBUG = 1;
# Constructor for the idx page
sub new {
	local $^W = 0;
	my ($indexfile, $num) = @_;
	my $parent;
	# we can be called from parent page
	if ((ref $indexfile) =~ /::Page$/) {			
		$parent = $indexfile;
		$indexfile = $parent->{'indexfile'};
	}
	my $data = $indexfile->read_record($num) or return;	# get 512 bytes
	my ($attributes, $noentries, $left_brother, $right_brother)
		= unpack 'vvVV', $data;		# parse header of the page
	my $keylength = $indexfile->{'key_length'};
	my $keyreclength = $indexfile->{'key_record_length'};	# length

	print "page $num, noentries $noentries, keylength $keylength\n" if $DEBUG;
	my $numdate = $indexfile->{'key_type'};		# numeric or string?
	
	my $offset = 12;
	my $i = 0;
	my ($keys, $values, $lefts) = ([], [], []);		# three arrays

	# walk the page
	while ($i < $noentries) {
		# get the values for entry
		my ($key, $recno) = unpack "\@$offset a$keylength N", $data;
		my $left;
		unless ($attributes & 2) {
			$left = $recno / 512;
			$recno = undef;
		}
		print "$i: \@$offset a$keylength N -> ($left, $recno, $key)\n" if $DEBUG > 1;
		### use Data::Dumper; print Dumper $indexfile;
		# some decoding for numbers
		if ($numdate) {			
			if ((substr($key, 0, 1) & "\200") ne "\200") {
				$key ^= "\377\377\377\377\377\377\377\377";
			} else {
				$key ^= "\200";
			}
			if (not $XBase::Index::BIGEND) { $key = reverse $key; }
			$key = unpack 'd', $key;
		}
		print "$i: \@$offset a$keylength N -> ($left, $recno, $key)\n" if $DEBUG > 1;
		push @$keys, $key;
		push @$values, ($recno ? $recno : undef);
		$left = ($left ? $left : undef);
		push @$lefts, $left;
		
		if ($i == 0 and defined $left)
			{ $noentries++; }	# fixup for nonleaf page
				### shouldn't this be for last page only?
	}
	continue {
		$i++;
		$offset += $keyreclength;
	}

	my $self = bless { 'keys' => $keys, 'values' => $values,
		'num' => $num, 'keylength' => $keylength,
		'lefts' => $lefts, 'indexfile' => $indexfile,
		'attributes' => $attributes,
		'left_brother' => $left_brother,
		'right_brother' => $right_brother }, __PACKAGE__;
	$self;
}

# ############
# dBase IV MDX

package XBase::mdx;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::Base XBase::Index );

sub read_header {
	my $self = shift;
	my %opts = @_;
	my $expr_name = $opts{'tag'};

	my $header;
	$self->{'dbf'} = $opts{'dbf'};
	$self->{'fh'}->read($header, 544) == 544 or do
		{ __PACKAGE__->Error("Error reading header of $self->{'filename'}: $!\n"); return; };

	@{$self}{ qw( version created dbf_filename block_size
		block_size_adder production noentries tag_length res
		tags_used res nopages first_free noavail last_update ) }
			= unpack 'Ca3A16vvccccvvVVVa3', $header;
	
	$self->{'record_len'} = 512;
	$self->{'header_len'} = 0;

	for my $i (1 .. $self->{'tags_used'}) {
		my $len = $self->{'tag_length'};
		
		$self->seek_to(544 + ($i - 1) * $len) or do
			{ __PACKAGE__->Error($self->errstr); return; };

		$self->{'fh'}->read($header, $len)  == $len or do
			{ __PACKAGE__->Error("Error reading tag header $i in $self->{'filename'}: $!\n"); return; };
	
		my $tag;
		@{$tag}{ qw( header_page tag_name key_format fwd_low
			fwd_high backward res key_type ) }
				= unpack 'VA11ccccca1', $header;

		$self->{'tags'}{$tag->{'tag_name'}} = $tag;
		$expr_name ||= $tag->{'tag_name'};	# Default to first tag

		$self->seek_to($tag->{'header_page'} * 512) or do
			{ __PACKAGE__->Error($self->errstr); return; };

		$self->{'fh'}->read($header, 24) == 24 or do
			{ __PACKAGE__->Error("Error reading tag definition in $self->{'filename'}: $!\n"); return; };
	
		@{$tag}{ qw( start_page file_size key_format_1
			key_type_1 res key_length max_no_keys_per_page
			second_key_type key_record_length res unique) }
				 = unpack 'VVca1vvvvva3c', $header;
	}

### use Data::Dumper; print Dumper $self;

	if (defined $expr_name) {
		if (defined $self->{'tags'}{$expr_name}) {
			$self->{'active'} = $self->{'tags'}{$expr_name};
			$self->{'start_page'} = $self->{'active'}{'start_page'};
		} else {
			__PACKAGE__->Error("No tag $expr_name found in index file $self->{'filename'}.\n"); return;
		}
	}

	$self;
}

sub last_record {
	-1;
}

sub tags {
	my $self = shift;
	return sort keys %{$self->{'tags'}} if defined $self->{'tags'};
}

package XBase::mdx::Page;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::mdx );

*DEBUG = \$XBase::Index::DEBUG;

# Constructor for the mdx page
sub new {
	my ($indexfile, $num) = @_;

	my $parent;
	### parent page
	if ((ref $indexfile) =~ /::Page$/) {
		$parent = $indexfile;
		$indexfile = $parent->{'indexfile'};
	}
	$indexfile->seek_to_record($num) or return;
	my $data;
	$indexfile->{'fh'}->read($data, 1024) == 1024 or return;

	my $keylength = $indexfile->{'active'}{'key_length'};
	my $keyreclength = $indexfile->{'active'}{'key_record_length'};
	my $offset = 8;

	my ($noentries, $noleaf) = unpack 'VV', $data;

	print "page $num, noentries $noentries, keylength $keylength; noleaf: $noleaf\n" if $DEBUG;

	my ($keys, $values, $lefts, $refs) = ([], [], [], []);

	for (my $i = 0; $i < $noentries; $i++) {
		my ($left, $key)
			= unpack "\@${offset}Va${keylength}", $data;

		push @$keys, $key;

		push @$refs, $left;

		$offset += $keyreclength;
	}

	my $right;

	$right = unpack "\@${offset}V", $data if $offset <= (1024-4);

	if ($right) {
		# It's a branch page and the next ref is for values > last key
		push @$keys, "";
		push @$refs, $right;
		$lefts = $refs;
	} else {
		# It's a leaf page
		$values = $refs;
	}

	my $self = bless { 'num' => $num, 'indexfile' => $indexfile,
		'keys' => $keys, 'values' => $values, 'lefts' => $lefts, },
								__PACKAGE__;
	$self;
}

# ###########
# FoxBase CDX

package XBase::cdx;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::Base XBase::Index );

*DEBUG = \$XBase::Index::DEBUG;

sub prepare_write_header {
	my $self = shift;
	my $data = pack 'VVNv CC @502 vvv @510 v @512 a512',
		$self->{'start_page'} * 512,
		$self->{'start_free_list'} * 512,
		@{$self}{ qw( total_pages
		key_length index_options index_signature
		sort_order total_expr_length for_expression_length
		key_expression_length
		key_string
		) };
	$data;
}
sub write_header {
	my $self = shift;
	my $data = $self->prepare_write_header;
	$self->{'fh'}->seek($self->{'adjusted_offset'} || 0, 0);
	$self->{'fh'}->print($data);
}
sub read_header {
	my ($self, %opts) = @_;
	$self->{'dbf'} = $opts{'dbf'} if not exists $self->{'dbf'};

	my $header;
	$self->{'fh'}->read($header, 1024) == 1024 or do
		{ __PACKAGE__->Error("Error reading header of $self->{'filename'}: $!\n"); return; };

	@{$self}{ qw( start_page start_free_list total_pages
		key_length index_options index_signature
		sort_order total_expr_length for_expression_length
		key_expression_length
		key_string
		) }
		= unpack 'VVNv CC @502 vvv @510 v @512 a512', $header;

	$self->{'total_pages'} = -1;	### the total_pages value 11
		### that found in rooms.cdx is not correct, so we invalidate it

	($self->{'key_string'}, $self->{'for_string'}) =
		($self->{'key_string'} =~ /^([^\000]*)\000([^\000]*)/);

	$self->{'key_record_length'} = $self->{'key_length'} + 4;
	$self->{'record_len'} = 512;
	$self->{'start_page'} /= $self->{'record_len'};
	$self->{'start_free_list'} /= $self->{'record_len'};
	$self->{'header_len'} = 0;
	$self->{'key_type'} = 0;

## my $out = $self->prepare_write_header;
## if ($out ne $header) {
## 	print STDERR "I won't be able to write the header back\n",
## 	unpack("H*", $out), "\n ++\n",
## 	unpack("H*", $header), "\n";
## }

	if (not defined $self->{'tag'}) {	# top level
		$self->prepare_select;
		while (my ($tag) = $self->fetch) {
			push @{$self->{'tags'}}, $tag;
			$opts{'tag'} ||= $tag;	# Default to first tag
		}
	}
### use Data::Dumper; print Dumper \%opts;

	if (defined $opts{'tag'}) {
		$self->prepare_select_eq($opts{'tag'});
		my ($foundkey, $value) = $self->fetch;

		if (not defined $foundkey or $opts{'tag'} ne $foundkey) {
			__PACKAGE__->Error("No tag $opts{'tag'} found in index file $self->{'filename'}.\n"); return; };

		my $subidx = bless { %$self }, ref $self;
		print "Adjusting start_page value by $value for $opts{'tag'}\n" if $DEBUG;
		$subidx->{'fh'}->seek($value, 0);
		$subidx->{'adjusted_offset'} = $value;
		$subidx->{'tag'} = $opts{'tag'};
		$subidx->read_header;

		my $key_string = $subidx->{'key_string'};
		my $field_type;
		if (defined $opts{'type'}) {
			$field_type = $opts{'type'};
		}
		elsif (defined $subidx->{'dbf'}) {
			$field_type = $subidx->{'dbf'}->field_type($key_string);
			if (not defined $field_type) {
				__PACKAGE__->Error("Couldn't find key string `$key_string' in dbf file, can't determine field type\n");
				return;
			}
		}
		else {
			__PACKAGE__->Error("Index type (char/numeric) unknown for $subidx\n");
			return;
		}
		$subidx->{'key_type'} = ($field_type =~ /^[NDIF]$/ ? 1 : 0);
		if ($field_type eq 'D') {
			$subidx->{'key_type'} = 2;
			require Time::JulianDay;
		}

		for (keys %$self) { delete $self->{$_} }
		for (keys %$subidx) { $self->{$_} = $subidx->{$_} }
		$self = $subidx;
### use Data::Dumper; print Dumper $self;
	}
	$self;
}

sub last_record {
	shift->{'total_pages'};
}

package XBase::cdx::Page;
use strict;
use vars qw( @ISA $DEBUG );
@ISA = qw( XBase::cdx );

*DEBUG = \$XBase::Index::DEBUG;

# Constructor for the cdx page
sub new {
	my ($indexfile, $num) = @_;
	my $data = $indexfile->read_record($num)
		or do { print $indexfile->errstr; return; };	# get 512 bytes

	my $origdata = $data;

	my ($attributes, $noentries, $left_brother, $right_brother)
		= unpack 'vvVV', $data;		# parse header of the page
	my $keylength = $indexfile->{'key_length'};
	my $keyreclength = $indexfile->{'key_record_length'};	# length

	print "page $num, attr $attributes, noentries $noentries, keylength $keylength (bro $left_brother, $right_brother)\n" if $DEBUG;
	my $numdate = $indexfile->{'key_type'};		# numeric or string?

	my ($keys, $values, $lefts) = ([], [], undef);

	my %opts = ();

	if ($attributes & 2) {
		print "leaf page, compressed\n" if $DEBUG;
		my ($free_space, $recno_mask, $duplicate_count_mask,
		$trailing_count_mask, $recno_count, $duplicate_count,
		$trailing_count, $holding_recno) = unpack '@12 vVCCCCCC', $data;
		print '$free_space, $recno_mask, $duplicate_count_mask, $trailing_count_mask, $recno_count, $duplicate_count, $trailing_count, $holding_recno) = ',
			"$free_space, $recno_mask, $duplicate_count_mask, $trailing_count_mask, $recno_count, $duplicate_count, $trailing_count, $holding_recno)\n" if $DEBUG > 2;

		@opts{ qw! recno_count duplicate_count trailing_count
				holding_recno !  } =
			( $recno_count, $duplicate_count, $trailing_count,
				$holding_recno);

		my $prevkeyval = '';
		for (my $i = 0; $i < $noentries; $i++) {
			my $one_item = substr($data, 24 + $i * $holding_recno, $holding_recno) . "\0" x 4;
			my $numeric_one_item = unpack 'V', $one_item;
			
			print "one_item: 0x", unpack('H*', $one_item), " ($numeric_one_item)\n" if $DEBUG > 3;

			my $recno = $numeric_one_item & $recno_mask;
			my $bytes_of_recno = int($recno_count / 8);
			$one_item = substr($one_item, $bytes_of_recno);

			$numeric_one_item = unpack 'V', $one_item;
			$numeric_one_item >>= $recno_count - (8 * $bytes_of_recno);
			
			my $dupl = $numeric_one_item & $duplicate_count_mask;
			$numeric_one_item >>= $duplicate_count;
			my $trail = $numeric_one_item & $trailing_count_mask;
			### $numeric_one_item >>= $trailing_count;

			print "Item $i: trail $trail, dupl $dupl, recno $recno\n" if $DEBUG > 6;

			my $getlength = $keylength - $trail - $dupl;
			my $key = substr($prevkeyval, 0, $dupl);
			$key .= substr($data, -$getlength) if $getlength;
			$key .= "\000" x $trail;
			substr($data, -$getlength) = '' if $getlength;
			$prevkeyval = $key;

### print "Numdate $numdate\n";
			if ($numdate) {		# some decoding for numbers
### print " *** In: ", unpack("H*", $key), "\n";
				if (0x80 & unpack('C', $key)) {
					substr($key, 0, 1) &= "\177";
				}
				else { $key = ~$key; }
				if ($keylength == 8) {
					$key = reverse $key unless $XBase::Index::BIGEND;
					$key = unpack 'd', $key;
				} else {
					$key = unpack 'N', $key;
				}
				if ($numdate == 2 and $key) {	# date
					$key = sprintf "%04d%02d%02d",
						Time::JulianDay::inverse_julian_day($key);
				}
			} else {
				substr($key, -$trail) = '' if $trail;
			}

			print "$key -> $recno\n" if $DEBUG > 4;
			push @$keys, $key;
			push @$values, $recno;
		}
	} else {
		for (my $i = 0; $i < $noentries; $i++) {
			my $offset = 12 + $i * ($keylength + 8);
			my ($key, $recno, $page)
				= unpack "\@$offset a$keylength NN", $data;
			# some decoding for numbers
			if ($numdate) {		
				if (0x80 & unpack('C', $key)) {
				### if ("\200" & substr($key, 0, 1)) {
### print STDERR "Declean\n";
### print STDERR unpack("H*", $key), ' -> ';
					substr($key, 0, 1) &= "\177";
### print STDERR unpack("H*", $key), "\n";
				}
				else { $key = ~$key; }
				if ($keylength == 8) {
					$key = reverse $key unless $XBase::Index::BIGEND;
					$key = unpack 'd', $key;
				} else {
					$key = unpack 'N', $key;
				}
				if ($numdate == 2 and $key) {	# date
					$key = sprintf "%04d%02d%02d",
						Time::JulianDay::inverse_julian_day($key);
				}
			} else {
				$key =~ s/\000+$//;
			}
			print "item: $key -> $recno via $page\n" if $DEBUG > 4;
			push @$keys, $key;
			push @$values, $recno;
			$lefts = [] unless defined $lefts;
			push @$lefts, $page / 512;
		}
		$opts{'last_key_is_just_overflow'} = 1;
	}

	my $self = bless { 'keys' => $keys, 'values' => $values,
		'num' => $num, 'keylength' => $keylength,
		'lefts' => $lefts, 'indexfile' => $indexfile,
		'attributes' => $attributes,
		'left_brother' => $left_brother,
		'right_brother' => $right_brother, %opts,
		}, __PACKAGE__;

	my $outdata = $self->prepare_scalar_for_write;
	if (0 and $outdata ne $origdata) {
		print "I won't be able to write this page back.\n",
			unpack("H*", $outdata), "\n ++\n",
			unpack("H*", $origdata), "\n";
	} else {
		### print STDERR " ** Bingo: I will be able to write this page back ($num).\n";
	}

	$self;
}

# Create "new" page -- allocates memory in the file and returns
# structure that can reasonably used as XBase::cdx::Page
sub create {
	my ($class, $indexfile) = @_;
	if (not defined $indexfile and ref $class) {
		$indexfile = $class->{'indexfile'};
	}
	my $fh = $indexfile->{'fh'};
	$fh->seek(0, 2);		# seek to the end;
	my $position = $fh->tell;	# get the length of the file
	if ($position % 512) {
		$fh->print("\000" x (512 - ($position % 512)));
					# pad the file to multiply of 512
		$position = $fh->tell;	# get the length of the file
	}
	$fh->print("\000" x 512);
	return bless { 'num' => $position / 512,
		'keylength' => $indexfile->{'key_length'},
		'indexfile' => $indexfile }, $class;
}

sub prepare_scalar_for_write {
	my $self = shift;

	my ($attributes, $noentries, $left_brother, $right_brother)
		= ($self->{'attributes'}, scalar(@{$self->{'keys'}}),
			$self->{'left_brother'}, $self->{'right_brother'});
		
	my $data = pack 'vvVV', $attributes, $noentries, $left_brother,
		$right_brother;
	
	my $indexfile = $self->{'indexfile'};
	my $numdate = $indexfile->{'key_type'};		# numeric or string?
	my $record_len = $indexfile->{'record_len'};
	my $keylength = $self->{'keylength'};

	if ($attributes & 2) {

		my ($recno_count, $duplicate_count, $trailing_count,
					$holding_recno) = (16, 4, 4, 3);
		if (defined $self->{'recno_count'}) {
			($recno_count, $duplicate_count, $trailing_count,
					$holding_recno) = 
			@{$self}{ qw! recno_count duplicate_count trailing_count
					holding_recno !  };
		}

### print STDERR "Hmmm. We are setting hardcoded values for bitmasks, not good. Write to adelton.\n";
		my ($recno_mask, $duplicate_mask, $trailing_mask)
			= ( 2**$recno_count - 1, 2**$duplicate_count - 1,
				2**$trailing_count - 1);


		my $recno_data = '';

		my $keys_string = '';
		my $prevkey = '';

		my $row = 0;
		for my $key (@{$self->{'keys'}}) {
			my $dupl = 0;

			my $out = $key;
			# some encoding for numbers
			if ($numdate) {		
				if ($keylength == 8) {
					$out = pack 'd', $out;
					$out = reverse $out unless $XBase::Index::BIGEND;
				} else {
					$out = pack 'N', $out;
				}


				unless (0x80 & unpack('C', $out)) {
					substr($out, 0, 1) |= "\200";
				}
				else { $out = ~$out; }
			}

			for my $i (0 .. length($out) - 1) {
				unless (substr($out, $i, 1) eq substr($prevkey, $i, 1)) {
					last;
				}
				$dupl++;
			}	

			my $trail = $keylength - length $out;
			while (substr($out, -1) eq "\000") {
				$out = substr($out, 0, length($out) - 1);
				$trail++;
			}
			$keys_string = substr($out, $dupl) . $keys_string;


			my $numdata =
				(((($trail & $trailing_mask) << $duplicate_count)
				| ($dupl & $duplicate_mask)) << $recno_count)
				| ($self->{'values'}[$row] & $recno_mask);

			$recno_data .= substr(pack('V', $numdata), 0, $holding_recno);

			### print unpack("H*", substr($out, $dupl)), ": trail $trail, dupl $dupl\n";

			$prevkey = $out;
			$row++;
		}
		### print $keys_string, "\n";	

### print STDERR "Hmmm. The \$numdata is really just a hack -- the shifts have to be made 64 bit clean.\n"; 
		$data .= pack 'vVCCCCCC',
			($record_len - length($recno_data) - length($keys_string)
				- 24), $recno_mask, $duplicate_mask,
				$trailing_mask, $recno_count, $duplicate_count,
				$trailing_count, $holding_recno;

		$data .= $recno_data;
		$data .= "\000" x ($record_len - length($data) - length($keys_string));
		$data .= $keys_string;
	} else {
		my $row = 0;
		for my $key (@{$self->{'keys'}}) {
			my $out = $key;
			# some encoding for numbers
			if ($numdate) {		
				if ($keylength == 8) {
					$out = pack 'd', $out;
					$out = reverse $out unless $XBase::Index::BIGEND;
				} else {
					$out = pack 'N', $out;
				}


				unless (0x80 & unpack('C', $out)) {
					substr($out, 0, 1) |= "\200";
				}
				else { $out = ~$out; }
### print " *** Out2: ", unpack("H*", $out), "\n";
			}
			$data .= pack "a$keylength NN", $out,
				$self->{'values'}[$row],
				$self->{'lefts'}[$row] * 512;
			$row++;
		}
		$data .= "\000" x ($record_len - length($data));
	}
	$data;
}

sub write_page {
	my $self = shift;
	my $indexfile = $self->{'indexfile'};

	my $data = $self->prepare_scalar_for_write;
	die "Data is too long in cdx::write_page for $self->{'num'}\n"
						if length $data > 512;
	$indexfile->write_record($self->{'num'}, $data);
}

# Saves current page, taking into account all neighbour and parent
# pages. We can safely assume that this method is called for pages
# that have been loaded using prepare_select_eq and fetch, so they
# have the parent pointers set correctly.
sub write_with_context {
	my $self = shift;		# page to save
	print STDERR "XBase::cdx::Page::write_with_context called ($self->{'num'})\n" if $DEBUG;

	my $indexfile = $self->{'indexfile'};

	my $self_num = $self->{'num'};

	# get the current page as data to be written
	my $data = $self->prepare_scalar_for_write;

	if (not @{$self->{'keys'}}) {
		$indexfile->write_record($self_num, $data);

		# empty root page means no more work, just save
		return if $self_num == $indexfile->{'start_page'};

		print STDERR "The page $self_num is empty, releasing from the chain\n";
		
		# first we update the brothers	
		my $right_brother_num = $self->{'right_brother'};
		my $left_brother_num = $self->{'left_brother'};
		if ($right_brother_num != 0xFFFFFFFF) {
			my $fix_brother = $indexfile->get_record($right_brother_num / 512);
			$fix_brother->{'left_brother'} = $left_brother_num;
			$fix_brother->write_page;
		}
		if ($left_brother_num != 0xFFFFFFFF) {
			my $fix_brother = $indexfile->get_record($left_brother_num / 512);
			$fix_brother->{'right_brother'} = $right_brother_num;
			$fix_brother->write_page;
		}

		# now we need to release ourselves from parent as well
		my $parent = $self->get_parent_page or die "Index corrupt: no parent for page $self ($self_num)\n";

		my $maxindex = $#{$parent->{'lefts'}};
		my $i;
		for ($i = 0; $i <= $maxindex; $i++) {
			if ($parent->{'lefts'}[$i] == $self_num) {
				splice @{$parent->{'keys'}}, $i, 1;
				splice @{$parent->{'values'}}, $i, 1;
				splice @{$parent->{'lefts'}}, $i, 1;
				last;
			}
		}
		if ($i > $maxindex) {
			die "Index corrupt: parent doesn't point to us in write_with_context $self ($self_num)\n";
		}
		$parent->write_with_context;
		return;
	}


	if (length $data > 512) {	# we need to split the page
		print STDERR "Splitting full page $self ($self_num)\n";

		# create will give us brand new empty page
		
		my $new_page = __PACKAGE__->create($indexfile);
		$self->{'attributes'} &= 0xfffe;
		$new_page->{'attributes'} = $self->{'attributes'};

		my $total_rows = scalar(@{$self->{'keys'}});
		my $half_rows = int($total_rows / 2);

		# primary split
		if ($half_rows == 0) { $half_rows++; }
		if ($half_rows == $total_rows) {
			die "Fatal trouble: page $self ($self_num) is full but I'm not able to split it\n";
		}

		# new page is right brother (will get bigger values)
		$new_page->{'right_brother'} = $self->{'right_brother'};
		$new_page->{'left_brother'} = $self_num * 512;
		$self->{'right_brother'} = $new_page->{'num'} * 512;

		if ($new_page->{'right_brother'} != 0xFFFFFFFF) {
			my $fix_brother = $indexfile->get_record($new_page->{'right_brother'} / 512);
			$fix_brother->{'left_brother'} = $new_page->{'num'} * 512;
			$fix_brother->write_page;
		}

		# we'll split keys and values
		$new_page->{'keys'} = [ @{$self->{'keys'}}[$half_rows .. $total_rows - 1] ];
		splice @{$self->{'keys'}}, $half_rows, $total_rows - $half_rows;
		$new_page->{'values'} = [ @{$self->{'values'}}[$half_rows .. $total_rows - 1] ];
		splice @{$self->{'values'}}, $half_rows, $total_rows - $half_rows;

		# and we'll split pointers to lower levels, if there are any
		if (defined $self->{'lefts'}) {
			$new_page->{'lefts'} = [ @{$self->{'lefts'}}[$half_rows ..  $total_rows - 1] ];
			my $new_page_num = $new_page->{'num'};
			for my $q (@{$new_page->{'lefts'}}) {
				if (defined $q and defined $indexfile->{'pages_cache'}{$q}) {
					$indexfile->{'pages_cache'}{$q}{'parent'} = $new_page_num;
				}
			}
			splice @{$self->{'lefts'}}, $half_rows, $total_rows - $half_rows - 1;
		}

		my $parent;
		if ($self_num == $indexfile->{'start_page'}) {
			# we're splitting the root page, so we will
			# create new one
			$parent = __PACKAGE__->create($indexfile);

			$indexfile->{'start_page'} = $parent->{'num'};
			$indexfile->write_header;

			### xxxxxxxxxxxxxxxxxxx
			### And here we should write the header so that
			### the new root page is saved to disk. Not
			### tested yet.
			### xxxxxxxxxxxxxxxxxxx

			$parent->{'attributes'} = 1;	# root page

			$parent->{'keys'} = [ $self->{'keys'}[-1],
						$new_page->{'keys'}[-1] ];
			$parent->{'values'} = [ $self->{'values'}[-1],
						$new_page->{'values'}[-1] ];
			$parent->{'lefts'} = [ $self_num, $new_page->{'num'} ];
		} else {	# update pointers in parent page
			$parent = $self->get_parent_page or die "Index corrupt: no parent for page $self ($self_num)\n";
			my $maxindex = $#{$parent->{'lefts'}};
			my $i = 0;

			# find pointer to ourselves in the parent
			while ($i <= $maxindex) {
				last if $parent->{'lefts'}[$i] == $self_num;
				$i++;
			}
			
			if ($i > $maxindex) {
				die "Index corrupt: parent doesn't point to us in write_with_context $self ($self_num)\n";
			}

			# now $i is index in parent of the record pointing to us

			splice @{$parent->{'keys'}}, $i, 1,
				$self->{'keys'}[-1], $new_page->{'keys'}[-1];
			splice @{$parent->{'values'}}, $i, 1,
				$self->{'values'}[-1], $new_page->{'values'}[-1];
			splice @{$parent->{'lefts'}}, $i, 1,
				$self_num, $new_page->{'num'};
		}

		$self->write_page;

		$new_page->{'parent'} = $self->{'parent'};
		$new_page->write_page;

		$parent->write_with_context;
	}
	elsif ($self_num != $indexfile->{'start_page'}) {
		# the output data is OK, write is out
		# but this is not root page, so we need to make sure the
		# parent is updated as well
		$indexfile->write_record($self_num, $data);

		# now we need to check if the parent page still points
		# correctly to us (the last value might have changed)
		my $parent = $self->get_parent_page or die "Index corrupt: no parent for page $self ($self_num)\n";

		my $maxindex = $#{$parent->{'lefts'}};
		my $i = 0;

		# find pointer to ourselves in the parent
		while ($i <= $maxindex) {
			last if $parent->{'lefts'}[$i] == $self_num;
			$i++;
		}
		
		if ($i > $maxindex) {
			die "Index corrupt: parent doesn't point to us in write_with_context $self ($self_num)\n";
		}

		# now $i is index in parent of the record pointing to us

		if ($parent->{'values'}[$i] != $self->{'values'}[-1]) {
			print STDERR "Will need to update the parent -- last value in myself changed ($self_num)\n";
			$parent->{'values'}[$i] = $self->{'values'}[-1];
			$parent->{'keys'}[$i] = $self->{'keys'}[-1];
			$parent->write_with_context;
		}
		
	} else {	# write out root page
		$indexfile->write_record($self_num, $data);
	}

	print STDERR "XBase::cdx::Page::write_with_context finished ($self->{'num'})\n" if $DEBUG;
}

# finds parent page for the object
sub get_parent_page_num {
	my $self = shift;
	return $self->{'parent'} if defined $self->{'parent'};

	my $indexfile = $self->{'indexfile'};

	return if $self->{'num'} == $indexfile->{'start_page'};

	# this should search to this page, effectivelly setting the
	# level array in such a way that the parent page is there
	$indexfile->prepare_select_eq($self->{'keys'}[0], $self->{'values'}[0]);

### print STDERR "self($self->{'num'}): $self, pages: @{$indexfile->{'pages'}}\n";
### use Data::Dumper; print Dumper $indexfile;
	my $pageindex = $#{$indexfile->{'pages'}};
	while ($pageindex >= 0) {
		if ("$self" eq "$indexfile->{'pages'}[$pageindex]") {
			print STDERR "Parent page for $self->{'num'} is $indexfile->{'pages'}[$pageindex - 1]{'num'}.\n";
			return $indexfile->{'pages'}[$pageindex - 1]->{'num'};
		}
		$pageindex--;
	}
	return undef;
}
sub get_parent_page {
	my $self = shift;
	my $parent_num = $self->get_parent_page_num or return;
	my $indexfile = $self->{'indexfile'};
	return $indexfile->get_record($parent_num);
	}

1;

__END__

=head1 SYNOPSIS

	use XBase;
	my $table = new XBase "data.dbf";
	my $cur = $table->prepare_select_with_index("id.ndx",
		"ID", "NAME);
	$cur->find_eq(1097);

	while (my @data = $cur->fetch()) {
		last if $data[0] != 1097;
		print "@data\n";
	}

This is a snippet of code to print ID and NAME fields from dbf
data.dbf where ID equals 1097. Provided you have index on ID in
file id.ndx. You can use the same code for ntx and idx index files.
For the cdx and mdx, the prepare_select call would be

	prepare_select_with_index(['rooms.cdx', 'ROOMNAME'])

so instead of plain filename you specify an arrayref with filename and
an index tag in that file. The reason is that cdx and mdx can contain
multiple indexes in one file and you have to distinguish, which you
want to use.

=head1 DESCRIPTION

The module XBase::Index is a collection of packages to provide index
support for XBase-like dbf database files.

An index file is generaly a file that holds values of certain database
field or expression in sorted order, together with the record number
that the record occupies in the dbf file. So when you search for
a record with some value, you first search in this sorted list and
once you have the record number in the dbf, you directly fetch the
record from dbf.

=head2 What indexes do

To make the searching in this ordered list fast, it's generally organized
as a tree -- it starts with a root page with records that point to
pages at lower level, etc., until leaf pages where the pointer is no
longer a pointer to the index but to the dbf. When you search for a
record in the index file, you fetch the root page and scan it
(lineary) until you find key value that is equal or grater than that you
are looking for. That way you've avoided reading all pages describing
the values that are lower. Here you descend one level, fetch the page
and again search the list of keys in that page. And you repeat this
process until you get to the leaf (lowest) level and here you finaly
find a pointer to the dbf. XBase::Index does this for you.

Some of the formats also support multiple indexes in one file --
usually there is one top level index that for different field values
points to different root pages in the index file (so called tags).

XBase::Index supports (or aims to support) the following index
formats: ndx, ntx, mdx, cdx and idx. They differ in a way they store
the keys and pointers but the idea is always the same: make a tree of
pages, where the page contains keys and pointer either to pages at
lower levels, or to dbf (or both). XBase::Index only supports
read only access to the index fields at the moment (and if you need
writing them as well, follow reading because we need to have the
reading support stable before I get to work on updating the indexes).

=head2 Testing your index file (and XBase::Index)

You can test your index using the indexdump script in the main
directory of the DBD::XBase distribution (I mean test XBase::Index
on correct index data, not testing corrupted index file, of course ;-)
Just run

	./indexdump ~/path/index.ndx
	./indexdump ~/path/index.cdx tag_name

or

	perl -Ilib ./indexdump ~/path/index.cdx tag_name

if you haven't installed this version of XBase.pm/DBD::XBase yet. You
should get the content of the index file. On each row, there is
the key value and a record number of the record in the dbf file. Let
me know if you get results different from those you expect. I'd
probably ask you to send me the index file (and possibly the dbf file
as well), so that I can debug the problem.

The index file is (as already noted) a complement to a dbf file. Index
file without a dbf doesn't make much sense because the only thing that
you can get from it is the record number in the dbf file, not the
actual data. But it makes sense to test -- dump the content of the
index to see if the sequence is OK.

The index formats usually distinguish between numeric and character
data. Some of the file formats include the information about the type
in the index file, other depend on the dbf file. Since with indexdump
we only look at the index file, you may need to specify the -type
option to indexdump if it complains that it doesn't know the data
type of the values (this is the case with cdx at least). The possible
values are num, char and date and the call would be like

	./indexdump -type=num ~/path/index.cdx tag_name

(this -type option may not work with all index formats at the moment
-- will be fixed and patches always welcome).

You can use C<-ddebug> option to indexdump to see how pages are
fetched and decoded, or run debugger to see the calls and parsing.

=head2 Using the index files to speed up searches in dbf

The syntax for using the index files to access data in the dbf file is
generally

	my $table = new XBase "tablename";
		# or any other arguments to get the XBase object
		# see XBase(3)
	my $cur = $table->prepare_select_with_index("indexfile",
		"list", "of", "fields", "to", "return");

or

	my $cur = $table->prepare_select_with_index(
		[ "indexfile_with_tags", "tag_name" ],
		"list", "of", "fields", "to", "return");

where we specify the tag in the index file (this is necessary with cdx
and mdx). After we have the cursor, we can search to given record and
start fetching the data:

	$cur->find_eq('jezek');
	while (my @data = $cur->fetch) { # do something

=head2 Supported index formats

The following table summarizes which formats are supproted by
XBase::Index. If the field says something else that Yes, I welcome
testers and offers of example index files.

  Reading of index files -- types supported by XBase::Index

  type	string		numeric		date
  ----------------------------------------------------------
  ndx	Yes		Yes		Yes (you need to
  					convert to Julian)

  ntx	Yes		Yes		Untested

  idx	Untested	Untested	Untested
  	(but should be pretty usable)

  mdx	Untested	Untested	Untested

  cdx	Yes		Yes		Untested


  Writing of index files -- not supported untill the reading
  is stable enough.

So if you have access to an index file that is untested or unsupported
and you care about support of these formats, contact me. If you are
able to actually generate those files on request, the better because I
may need specific file size or type to check something. If the file
format you work with is supported, I still appreciate a report that it
really works for you.

B<Please note> that there is very little documentation about the file
formats and the work on XBase::Index is heavilly based on making
assumption based on real life data. Also, the documentation is often
wrong or only describing some format variations but not the others.
I personally do not need the index support but am more than happy to
make it a reality for you. So I need your help -- contact me if it
doesn't work for you and offer me your files for testing. Mentioning
word XBase somewhere in the Subject line will get you (hopefully ;-)
fast response. Mentioning work Help or similar stupidity will probably
make my filters to consider your email as spam. Help yourself by
making my life easier in helping you.

=head2 Programmer's notes

Programmers might find the following information usefull when trying
to debug XBase::Index from their files:

The XBase::Index module contains the basic XBase::Index package and
also packages XBase::ndx, XBase::ntx, XBase::idx, XBase::mdx and
XBase::cdx, and for each of these also a package
XBase::index_type::Page. Reading the file goes like this: you create
as object calling either new XBase::Index or new XBase::ndx (or
whatever the index type is). This can also be done behind the scenes,
for example XBase::prepare_select_with_index calls new XBase::Index.
The index file is opened using the XBase::Base::new/open and then the
XBase::index_type::read_header is called. This function fills the
basic data fields of the object from the header of the file. The new
method returns the object corresponding to the index type.

Then you probably want to do $index->prepare_select or
$index->prepare_select_eq, that would possition you just before record
equal or greater than the parameter (record in the index file, that
is). Then you do a series of fetch'es that return next pair of (key,
pointer_to_dbf). Behind the scenes, prepare_select_eq or fetch call
XBase::Index::get_record which in turn calls
XBase::index_type::Page::new. From the index file perspective, the
atomic item in the file is one index page (or block, or whatever
you call it). The XBase::index_type::Page::new reads the block of data
from the file and parses the information in the page -- pages have
more or less complex structures. Page::new fills the structure, so
that the fetch calls can easily check what values are in the page.

For some examples, please see eg/use_index in the distribution
directory.

=head1 VERSION

1.05

=head1 AVAILABLE FROM

http://www.adelton.com/perl/DBD-XBase/

=head1 AUTHOR

(c) 1998--2013 Jan Pazdziora.

=head1 SEE ALSO

XBase(3), XBase::FAQ(3)

=cut

