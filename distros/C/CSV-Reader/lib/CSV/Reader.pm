package CSV::Reader;
use strict;
use Carp qw(carp croak);
use Text::CSV ();
use Tie::IxHash ();
our $VERSION = 1.10;

=head1 NAME

CSV::Reader - CSV reader class

=head1 DESCRIPTION

Simple CSV reader class that uses Text::CSV internally.
The CSV files are expected to have a header row of column names.
This was designed with the idea of using an iterator interface, but Perl does not support interators (nor interfaces) yet :(

=head1 SYNOPSIS

	use CSV::Reader ();
	use open OUT => ':locale'; # optional; make perl aware of your terminal's encoding

	# Create reader from file name:
	my $reader = new CSV::Reader('/path/to/file.csv');

	# Create reader from a file handle (GLOB):
	open(my $h, '<', $filename) || die("Failed to open $filename: $!");
	# or preferred method that can handle files having a UTF-8 BOM:
	open(my $h, '<:via(File::BOM)', $filename) || die("Failed to open $filename: $!");
	my $reader = new CSV::Reader($h);

	# Create reader from an IO::Handle based object:
	my $io = IO::File->new(); # subclass of IO::Handle
	$io->open($filename, '<:via(File::BOM)') || die("Failed to open $filename: $!");
	my $reader = new CSV::Reader($io);

	# Create reader with advanced options:
	my $reader = new CSV::Reader('/path/to/file.csv',
		'delimiter' => ';',
		'enclosure' => '',
		'field_normalizer' => sub {
			my $nameref = shift;
			$$nameref = lc($$nameref);	# lowercase
			$$nameref =~ s/\s/_/g;	# whitespace to underscore
		},
		'field_aliases'	=> {
			'postal_code' => 'postcode', # applied after normalization
		},
	);

	# Show the field names found in the header row:
	print 'Field names: ' . join("\n", $reader->fieldNames()) . "\n";

	# Iterate over the data rows:
	while (my $row = $reader->nextRow()) {
		# It's recommended to validate the $row hashref first with something such as Params::Validate.
		# Now do whatever you want with the (validated) row hashref...
		require Data::Dumper; local $Data::Dumper::Terse = 1;
		print Data::Dumper::Dumper($row);
	}

=head1 PUBLIC STATIC METHODS

=head2 new($file, %options)

Constructor.

$file can be a string file name, an open file handle (GLOB), or an IO::Handle based object (e.g. IO::File or IO::Scalar).
If a string file name is given, then the file is opened via File::BOM.

The following %options are supported:

	- debug: boolean, if true, then debug messages are emitted using warn().
	- field_aliases: hashref of case insensitive alias (in file) => real name (as expected in code) pairs.
	- field_normalizer: optional callback that receives a field name by reference to normalize (e.g. make lowercase).
	- include_fields: optional arrayref of field names to include. If given, then all other field names are excluded.
	- delimiter: string, default ','
	- enclosure: string, default '"'
	- escape: string, default backslash

Note: the option field_aliases is processed after the option field_normalizer if given.

=cut

sub new {
	my $proto = shift;
	my $file = shift;
	my %options = @_;
	my $self = {
		'h'				=> undef,	# File handle.
		'own_h'			=> undef,	# Does this class own the file handle.
		'field_cols'	=> {},		# Hashref of fieldname => column index pairs.
		'row'			=> undef,	# Current ReaderRow object.
		'linenum'		=> 0,		# Data row index.
		'text_csv'		=> undef,	# The Text::CSV object

		# Options:
		'debug'			=> 0,
		'delimiter'		=> ',',
		'enclosure'		=> '"',
		'escape'		=> '\\',
		'skip_empty_lines'	=> 0, # TODO: implement this
	};
	tie(%{$self->{'field_cols'}}, 'Tie::IxHash');

	unless(defined($file) && length($file)) {
		croak('Missing $file argument');
	}
	if (ref($file)) {
		unless ((ref($file) eq 'GLOB') || UNIVERSAL::isa($file, 'IO::Handle')) {
			croak(ref($file) . ' is not a legal file argument type');
		}
		$self->{'h'} = $file;
		$self->{'own_h'} = 0;
	}
	else {
		my $h;
		eval {
			require File::BOM;
		};
		my $mode = $@ ? '<' : '<:via(File::BOM)';
		$options{'debug'} && warn(__PACKAGE__ . "::new file open mode is $mode\n");
		open($h, $mode, $file) || croak('Failed to open "' . $file . '" for reading using mode "' . $mode . '": ' . $!);
		$self->{'h'} = $h;
		$self->{'own_h'} = 1;
	}

	# Get the options.
	my %opt_field_aliases;
	my $opt_field_normalizer;
	my %opt_include_fields;
	if (%options) {
		foreach my $key (keys %options) {
			my $value = $options{$key};
			if (($key eq 'debug') || ($key eq 'skip_empty_lines')) {
				$self->{$key} = $value;
			}
			elsif (($key eq 'enclosure') || ($key eq 'escape')) {
				if (!defined($value) || ref($value)) {
					croak("The '$key' option must be a string");
				}
				$self->{$key} = $value;
			}
			elsif ($key eq 'delimiter') {
				if (!defined($value) || ref($value) || !length($value)) {
					croak("The '$key' option must be a non-empty string");
				}
				$self->{$key} = $value;
			}

			elsif ($key eq 'include_fields') {
				if (ref($value) ne 'ARRAY') {
					croak("The '$key' option must be an arrayref");
				}
				%opt_include_fields = map { $_ => undef } @$value;
			}
			elsif ($key eq 'field_aliases') {
				if (ref($value) ne 'HASH') {
					croak("The '$key' option must be a hashref");
				}
				%opt_field_aliases = map { lc($_) => $value->{$_} } keys %$value;
			}
			elsif ($key eq 'field_normalizer') {
				if (ref($value) ne 'CODE') {
					croak("The '$key' option must be a code ref");
				}
				$opt_field_normalizer = $value;
			}
			else {
				croak("Unknown option '$key'");
			}
		}
	}

	my $text_csv = $self->{'text_csv'} = Text::CSV->new({
		'auto_diag'			=> 1,
		'binary'			=> 1,
		'blank_is_undef'	=> 1,
		'empty_is_undef'	=> 1,
		'sep_char'			=> $self->{'delimiter'},
		'escape_char'		=> $self->{'escape'},
		'quote_char'		=> $self->{'enclosure'},
	});

	# Emulate the original Text::CSV error message format but without the LF and with the caller script/module.
	if (0) {
		$text_csv->callbacks(
			'error' => sub {
				my ($err, $msg, $pos, $recno, $fldno) = @_;	# This is dumb because the object itself is not given.
				if ($err eq '2012') { # EOF
					return;
				}
				#CSV_XS ERROR: 2021 - EIQ - NL char inside quotes, binary off @ rec 10 pos 51 field 6
				#die 'error args: ' . Data::Dumper::Dumper(\@_);
				local $Carp::CarpInternal{'Text::CSV'} = 1;
				local $Carp::CarpInternal{'Text::CSV_PP'} = 1;
				local $Carp::CarpInternal{'Text::CSV_XS'} = 1;
				carp(ref($text_csv) . " ERROR: $err - $msg \@ rec $recno pos $pos field $fldno");
				return;
			},
		);
	}

	# Read header row.
	if (my $row = $self->{'text_csv'}->getline($self->{'h'})) {
		# Get the fieldname => column indices
		for (my $x = 0; $x < @$row; $x++) {
			my $name = $row->[$x];
			unless(defined($name)) {
				next;
			}
			$name =~ s/^\s+|\s+$//g;
			unless(length($name)) {
				next;
			}
			if ($opt_field_normalizer) {
				&$opt_field_normalizer(\$name);
			}
			if (%opt_field_aliases) {
				my $key = lc($name);
				if (defined($opt_field_aliases{$key})) {
					$name = $opt_field_aliases{$key};
				}
			}
			if (%opt_include_fields && !exists($opt_include_fields{$name})) {
				next;
			}
			if (exists($self->{'field_cols'}->{$name})) {
				croak('Duplicate field "' . $name . '" detected');
			}
			$self->{'field_cols'}->{$name} = $x;
		}
		unless(%{$self->{'field_cols'}}) {
			croak(%opt_include_fields ? 'No fields found in header row to include' : 'No fields found in header row');
		}
		# If include_fields option was given, reorder keys of field_cols to match it.
		if (%opt_include_fields) {
			my %field_cols;
			#{$self->{'field_cols'}}
			tie(%field_cols, 'Tie::IxHash');
			foreach my $key (@{$options{'include_fields'}}) {
				if (exists($self->{'field_cols'}->{$key})) {
					$field_cols{$key} = $self->{'field_cols'}->{$key};
				}
			}
			$self->{'field_cols'} = \%field_cols;
		}
	}
	else {
		croak('No header line found in CSV');
	}

	# Check that all the required header fields are present.
	if (%opt_include_fields) {
		my @missing;
		foreach my $name (keys %opt_include_fields) {
			if (!exists($self->{'field_cols'}->{$name})) {
				push(@missing, $name);
			}
		}
		if (@missing) {
			croak('The following column headers are missing: ' . join(', ', @missing));
		}
	}
	bless($self, ref($proto) || $proto);
	return $self;
}




=head2 DESTROY

Closes the private file handle, if any.

=cut

sub DESTROY {
	my $self = shift;
	if ($self->{'own_h'}) {
		close($self->{'h'});
	}
}






=head1 PROTECTED OBJECT METHODS

=head2 _read()

Reads the next CSV data row and sets internal variables.

=cut

sub _read {
	my $self = shift;
	if (my $csv_row = $self->{'text_csv'}->getline($self->{'h'})) {
		if ($self->{'debug'}) {
			require Data::Dumper;
			local $Data::Dumper::Terse = 1;
			warn(__PACKAGE__ . '::_read ' . Data::Dumper::Dumper($csv_row));
		}
		tie(my %row, 'Tie::IxHash');
		my $field_cols = $self->{'field_cols'};	# name to index map
		foreach my $k ($self->fieldNames()) {
			my $i = $field_cols->{$k};
			my $v = $csv_row->[$i];
			if (defined($v)) {
				$v =~ s/^\s+|\s+$//g;
				unless(length($v)) {
					$v = undef;
				}
			}
			$row{$k} = $v;
		}
		$self->{'row'} = \%row;
		$self->{'linenum'}++;
	}
	else {
		$self->{'row'} = undef;
		$self->{'linenum'} = 0;
	}
}






=head1 PUBLIC OBJECT METHODS

=head2 fieldNames()

Returns the field names as an array.

=cut

sub fieldNames {
	my $self = shift;
	return keys(%{$self->{'field_cols'}});
}





=head2 current()

Returns the current row.

=cut

sub current {
	my $self = shift;
	return $self->{'row'};
}





=head2 linenum()

Returns the current row index.

=cut

sub linenum {
	my $self = shift;
	return $self->{'linenum'};
}





=head2 nextRow()

Reads the next row.

=cut

sub nextRow {
	my $self = shift;
	$self->_read();
	return $self->{'row'};
}





=head2 eof()

Returns boolean

=cut

sub eof {
	my $self = shift;
	return $self->{'text_csv'}->eof();
}




=head2 rewind()

Rewinds the file handle.

=cut

sub rewind {
	my $self = shift;
	seek($self->{'h'},0,0) || croak('Failed to rewind file handle');
	$self->{'text_csv'}->getline($self->{'h'}); # skip the header row
}



1;


__END__

=head1 SEE ALSO

L<Text::CSV> used by this class internally.

=head1 AUTHOR

Craig Manley

=head1 COPYRIGHT

Copyright (C) 2020 Craig Manley. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
