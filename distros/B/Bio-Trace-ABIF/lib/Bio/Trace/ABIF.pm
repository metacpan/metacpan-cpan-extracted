package Bio::Trace::ABIF;

use warnings;
use strict;

=head1 NAME

Bio::Trace::ABIF - Perl extension for reading and parsing ABIF (Applied
Biosystems, Inc. Format) files
       
=head1 VERSION

Version 1.05

=cut

our $VERSION = '1.06';

=head1 SYNOPSIS

The ABIF file format is a binary format for storing data (especially, those
produced by sequencers), developed by Applied Biosystems, Inc. Typical file
suffixes for such files are C<.ab1> and C<.fsa>.

The data inside ABIF files is organized in records, in the following referred
to as either I<directory entries> or I<data items>. Each data item is uniquely
identified by a pair made of a four character string and a number: we call such
pair a I<tag> and its components the I<tag name> and the I<tag number>,
respectively. Tags are defined in the official documentation for ABIF files
(see the L</"SEE ALSO"> Section at the end of this document).

This module provides methods for accessing any data item contained into an ABIF
file (with or without knowledge of the corresponding tag) and methods for
assessing the quality of the data (e.g., for computing LOR scores, clear ranges,
and so on). The module has also support for ABIF file modification, that is,
any directory entry can be overwritten (it is not possible, however, to add
new directory entries corresponding to tags not already present in the file).

  use Bio::Trace::ABIF;
  
  my $abif = Bio::Trace::ABIF->new();
  $abif->open_abif('/Path/to/my/file.ab1');
  
  print $abif->sample_name(), "\n";
  my @quality_values = $abif->quality_values();
  my $sequence = $abif->sequence();
  # etc...

  $abif->close_abif();

=cut

#use 5.008006;
use Carp;

require Exporter;

our @ISA = qw(Exporter);
my $Debugging = 0;
my $DIR_SIZE = 28; # Size, in bytes, of a directory entry in an ABIF file
my $IS_BIG_ENDIAN = unpack("h*", pack("s", 1)) =~ /01/; # See perlport
my $IS_LITTLE_ENDIAN = unpack("h*", pack("s", 1)) =~ /^1/;
my $SHORT_MAX = 2**16;
my $SHORT_MID = 2**15;
my $LONG_MAX = 2**32;
my $LONG_MID = 2**31;
my $sshort_tmpl = ($IS_BIG_ENDIAN) ? 's' : 'C2';
my $slong_tmpl = ($IS_BIG_ENDIAN) ? 'l' : 'C4';

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Bio::Trace::ABIF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

# Standard types
our %TYPES = (
		1 => 'byte', 2 => 'char', 3 => 'word', 4 => 'short', 5 => 'long',
		7 => 'float', 8 => 'double', 10 => 'date', 11 => 'time', 18 => 'pString',
		19 => 'cString', 12 => 'thumb', 13 => 'bool', 6 => 'rational', 9 => 'BCD',
		14 => 'point', 15 => 'rect', 16 => 'vPoint', 17 => 'vRect', 20 => 'tag',
		128 => 'deltaComp', 256 => 'LZWComp', 384 => 'deltaLZW'
	); # User defined data types have tags numbers >= 1024


# Specifies how to pack each data type
our %PACK_TMPL = (
	'byte' => 'C', 'char' => 'c', 'word' => 'n', 'short' => 'n', 'long' => 'N',
	# float and double needs special treatment
	'date' => 'nCC', 'time' => 'CCCC', 'pString' => 'CA*', 'cString' => 'Z*',
	'bool' => 'C', 'thumb' => 'NNCC', 'rational' => 'NN', 'point' => 'nn', 
	'rect' => 'nnnn', 'vPoint' => 'NN', 'vRect' => 'NNNN', 'tag' => 'NN'
);

=head2 module_version()

  Usage    : $version = Bio::Trace::ABIF->module_version();
  Returns  : This module's version number.
  
=cut

sub module_version {
	return $VERSION;
}

sub _endianness {
	return ($IS_BIG_ENDIAN) ? 'big' : 'little';
}

=head1 CONSTRUCTOR

Creates a new ABIF object.

=head2 new()

  Usage    : my $abif = Bio::Trace::ABIF->new();
  Returns  : An instance of ABIF.

Creates an ABIF object.

=cut
	
sub new {
	my $class = shift;
	my $foo = shift;
	my $self = {};
	$self->{'_FH'} = undef; # ABIF file handle
	$self->{'_NUMELEM'} = undef;
	$self->{'_DATAOFFSET'} = undef;
	# Data type codes as specified by AB specification
	$self->{'TYPES'} = \%TYPES;
	bless($self, $class);
	
	return $self;
}

=head1 OPENING AND CLOSING ABIF FILES

The methods in this section allow you to open an ABIF file
(either read-only or for modification), to close it or
to verify the ABIF format version number.

=cut

=head2 open_abif()

  Usage    : $abif->open_abif($pathname);
             $abif->open_abif($pathname, 1); # Read/Write mode
  Returns  : 1 if the file is opened;
             0 otherwise. 

Opens the specified file in binary format and checks whether it is in ABIF
format. If the second optional argument is not false then the file is opened in
read/write mode (by default, the file is opened in read only mode). Opening in
read/write mode is necessary only if you want to use C<write_tag()> (see below).

=cut

sub open_abif {
	my $self = shift;
	my $filename = shift;
	my $rw = '<';
	if (@_) {
		$rw = '+<' if (shift);
	}
	
	# Close previously opened file, if any
	$self->close_abif();
	
	open($self->{'_FH'}, $rw, $filename) or return 0;
	binmode($self->{'_FH'});
	unless ($self->is_abif_format()) {
		print STDERR "$filename is not an AB file...\n";
		close($self->{'_FH'});
		$self->{'_FH'} = undef;
		return 0;
	}
	# Determine the number of items (stored in bytes 18-21)
 	# and the offset of the data (stored in bytes 26-29)
	my $bytes;
	unless (seek($self->{'_FH'}, 18, 0)) {
		carp "Error on seeking file $filename";
		return 0;
	}
	# Read bytes 18-29
	unless (read($self->{'_FH'}, $bytes, 12)) {
		carp  "Error on reading $filename";
		return 0;
	}
	# Unpack a 32 bit integer, skip four bytes and unpack another 32 bit integer
	($self->{'_NUMELEM'}, $self->{'_DATAOFFSET'}) = 
		map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX } unpack('Nx4N', $bytes);
		
	# Cache tags positions
	return $self->_scan_tags();
}

# Performs a linear scan of the file,
# and stores the tags's offsets in a hash, for fast retrieval
sub _scan_tags {
	my $self = shift;
	my ($tag_name, $tag_number, $field);
	my $i = 0;
	$self->{'_TAG_INDEX'} = { };
	do {
		my $offset = $self->{'_DATAOFFSET'} + ($DIR_SIZE * $i);
		unless (seek($self->{'_FH'}, $offset, 0)) {
			carp "IO Error (wrong offset within file)";
			return 0;
		}
		# Read Tag name and number (8 bytes)
		unless (read($self->{'_FH'}, $field, 8)) {
			carp "IO Error (failed to read tag index)";
			return 0;
		}
		($tag_name, $tag_number) = unpack('A4N', $field);
		$tag_number -= $LONG_MAX if ($tag_number >= $LONG_MID);
		${$self->{'_TAG_INDEX'}}{$tag_name . $tag_number} = $offset;
		$i++;
	}
	while ($i < $self->{'_NUMELEM'});  

	return 1;
}

=head2 close_abif()

  Usage    : $abif->close_abif();
  Returns  : Nothing.

Closes the currently opened file.

=cut

sub close_abif {
	my $self = shift;
	close($self->{'_FH'}) if defined $self->{'_FH'};
	foreach my $k (keys %$self) {
		$self->{$k} = undef if $k =~ /^\_/;
	}
}

=head2 is_abif_open()

  Usage    : if ($abif->is_abif_open()) { # ...
  Returns  : 1 if an ABIF file is open;
             0 otherwise.

=cut

sub is_abif_open {
	my $self = shift;
	return defined $self->{'_FH'};
}


=head2 is_abif_format()

  Usage    : if ($abif->is_abif_format()) { # ...
  Returns  : 1 if the file is in ABIF format;
             0 otherwise.

Checks that the file is in ABIF format.

=cut

sub is_abif_format {
	my $self = shift;
	my $file_signature;

	# Move to the beginning of the file
	unless (seek($self->{'_FH'}, 0, 0)) {
		carp "Error on reading file";
		return 0;
	}
	# Read the first four bytes of the file
	# and interpret them as ASCII characters
	read($self->{'_FH'}, $file_signature, 4) or return 0;
	$file_signature = unpack('A4', $file_signature);
	if ($file_signature eq 'FIBA') {
		print STDERR "Probably, an ABIF file stored in little endian order\n";
		print STDERR "Unsupported ABIF file structure (because deprecated)\n";
	}
	return ($file_signature eq 'ABIF');
}

=head2 abif_version()

  Usage    : $v = $abif->abif_version();
  Returns  : The ABIF file version number (e.g., '1.01').

Used to determine the ABIF file version number.
  
=cut

sub abif_version {
	my $self = shift;
	my $version;

	unless (defined $self->{'_ABIF_VERSION'}) {
		# Version number is stored in bytes 4 and 5
		seek($self->{'_FH'}, 4, 0) or croak "Error on reading file";
		read($self->{'_FH'}, $version, 2) or croak "Error on reading file";
		$version = unpack('n', $version);
		$self->{'_ABIF_VERSION'} = $version / 100;
	}
	return $self->{'_ABIF_VERSION'};
}

=head1 GENERAL METHODS

The "low-level" methods of this section allow you to access
any directory entry in a file. It is up to the caller to correctly
interpret the values returned by these methods, so they should
be used only if the caller knows what (s)he is doing. In any case, it is
strongly recommended to use the accessor methods defined later
in this document: in most cases, they will do just fine.

=cut

=head2 num_dir_entries()

  Usage    : $n = $abif->num_dir_entries();
  Returns  : The number of data items in the file.
  
Used to determine the number of directory entries in the ABIF file.

=cut

sub num_dir_entries {
	my $self = shift;
	return $self->{'_NUMELEM'};
}

=head2 data_offset()

  Usage    : $n = $abif->data_offset();
  Returns  : The offset of the first data item, in bytes.
  
Used to determine the offset of the first directory entry from the beginning
of the file.

=cut

sub data_offset {
	my $self = shift;
	return $self->{'_DATAOFFSET'};
}

=head2 tags()

  Usage    : @tags = $abif->tags();
  Returns  : A list of the tags in the file.

=cut

sub tags {
	my $self = shift;
	return keys %{$self->{'_TAG_INDEX'}};
}

=head2 get_directory()

  Usage    : %D = $abif->get_directory($tagname, $tagnum);
  Returns  : A hash of the content of the given data item;
             () if the given tag is not found.
             
Retrieves the directory entry identified by the pair (C<$tag_name>, C<$tag_num>).
The C<$tagname> must be a four letter ASCII code and C<$tagnum> must be an
integer (typically, 1 <= C<$tag_num> <= 1000). The returned hash has the
following keys:

  TAG_NAME: the tag name;
  TAG_NUMBER: the tag number;
  ELEMENT_TYPE: a string denoting the type of the data item
                ('char', 'byte', 'float', etc...);
  ELEMENT_SIZE: the size, in bytes, of one element;
  NUM_ELEMENTS: the number of elements in the data item;
  DATA_SIZE: the size, in bytes, of the data item;
  DATA_ITEM: the raw sequence of bytes of the data item.

Nota Bene: it is upon the caller to interpret the data item field correctly
(typically, by C<unpack()>ing the item).

Refer to the L</"SEE ALSO"> Section for further information.

=cut

sub get_directory {
	my ($self, $tag_name, $tag_number) = @_;
	my %DirEntry;
	my $field;
	my ($et, $es, $ne, $ds);
	my $raw_data;

	if ($self->search_tag($tag_name, $tag_number)) { # Found!
		$DirEntry{TAG_NAME} = $tag_name;
		$DirEntry{TAG_NUMBER} = $tag_number;
		# Read and unpack the remaining bytes
		read($self->{'_FH'}, $field, 4);
		($et, $es) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			unpack('nn', $field);
		read($self->{'_FH'}, $field, 8);		
		($ne, $ds) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			unpack('NN', $field);
		# Element type code (signed 16 bit integer)		
		if ($et > 1023) {
			$DirEntry{ELEMENT_TYPE} = 'user';
		}
		else {
			$DirEntry{ELEMENT_TYPE} = $self->{TYPES}{$et};
		}
		# Element size (signed 16 bit integer)
		$DirEntry{ELEMENT_SIZE} = $es;
		# Number of element in this item (signed 32 bit integer)
		$DirEntry{NUM_ELEMENTS} = $ne;
		# Size of the item in bytes (signed 32 bit integer)
		$DirEntry{DATA_SIZE} = $ds;
		# Get data item
		if ($DirEntry{DATA_SIZE} > 4) {
		 	# The data item position is given by the data offset field
		 	read($self->{'_FH'}, $field, 4);
		 	($field) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
		 		unpack('N', $field);
			seek($self->{'_FH'}, $field, 0);
			read($self->{'_FH'}, $raw_data, $DirEntry{DATA_SIZE});
		}
		else {
			# if data size <= 4 then the data item is stored in the data offset field itself
			# (the current file handle position)
			read($self->{'_FH'}, $raw_data, $DirEntry{DATA_SIZE});
		}
		$DirEntry{DATA_ITEM} = $raw_data; # Return raw data

		return %DirEntry;
	}
	
	return ();
}

=head2 get_data_item()

  Usage    : @data = $abif->get_data_item($tagname,
                                             $tagnum,
                                             $template
                                            );
  Returns  : A list of elements unpacked according to $template;
             (), if the tag is not found.
             
  
Retrieves the data item specified by the pair (C<$tagname>, C<$tagnum>) and
unpacks it according to C<$template>. The C<$tagname> is a four letter
ASCII code and C<$tagnum> is an integer (typically, 1 <= C<$tagnum> <= 1000).
The C<$template> has the same format as in the C<pack()> function.

Refer to the L</"SEE ALSO"> Section for further information.

=cut

sub get_data_item {
	my $self = shift;
	my $tag_name = shift;
	my $tag_number = shift;
	my $template = shift;
	my $field;
	my $data_size;
	my $raw_data;
	my @data;

	if ($self->search_tag($tag_name, $tag_number)) { # Found!
		# Read the remaining bytes of the current directory entry
		read($self->{'_FH'}, $field, 12);
		# Unpack data size
		($data_size) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			unpack('x8N', $field);
		if ($data_size > 4) {
		 	# The data item position is given by the data offset field
		 	read($self->{'_FH'}, $field, 4);
		 	($field) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
		 		unpack('N', $field);
			seek($self->{'_FH'}, $field, 0);
			read($self->{'_FH'}, $raw_data, $data_size);
		}
		else {
			# if data size <= 4 then the data item is stored in the data offset field itself
			# (the current file handle position)
			read($self->{'_FH'}, $raw_data, $data_size);			
		}
		@data = unpack($template, $raw_data);
		return @data;
	}	
	return ();
}

=head1 SEARCHING AND OVERWRITING DATA

The methods in this section allow you to search for a specific tag
and to overwrite existing data corresponding to a given tag.

=head2 search_tag()

  Usage    : $abif->search_tag($tagname, $tagnum)
  Returns  : 1 if the tag is found;
             0, otherwise

Searches for the the specified data tag. If the tag is found, then the file
handle is positioned just after the tag number (ready to read the element type).

=cut

sub search_tag {
	my ($self, $tag_name, $tag_number) = @_;
	my ($t1, $t2, $field);
	my $offset = ${$self->{'_TAG_INDEX'}}{$tag_name . $tag_number};
	if (defined $offset) {
		seek($self->{'_FH'}, $offset + 8, 0);
		return 1;
	}
	else {
		return 0;
	}
}

=head2 write_tag()

  Usage    : $abif->write_tag($tagname, $tagnum, $data);
             $abif->write_tag($tagname, $tagnum, \@data);
             $abif->write_tag($tagname, $tagnum, \$data_str);
  Returns  : 1 if the data item is overwritten;
             0, otherwise.

Overwrites an existing tag with the given data. You may find the tag name and
the tag number of each piece of data in an ABIF file in the documentation of the
corresponding method (see below). You must open the file in read/write mode if
you want to overwrite it (see C<open_abif()>).

REMEMBER TO BACKUP YOUR FILE BEFORE OVERWRITING IT!

You must be careful when you overwrite data: the type of the new data must
match the type of the old one. There is no restriction on the length of the
data, e.g. you may overwrite the basecalled sequence with a longer or shorter
one. Examples of how to use this method follow.

To overwrite the basecalled sequence:

  my $new_sequence = 'GATGCATCT...';
  $abif->write_tag('PBAS', 1, \$new_sequence);
  # ($new_sequence can be passed also by value)
  print 'New sequence is: ', $abif->edited_sequence();

To overwrite the quality values:

  my @qv = (10, 20, 30, ...); # All values must be < 128
  $abif->write_tag('PCON', 1, \@qv); # Pass by reference!
  print 'New qv's: ', $abif->edited_quality_values();
  
To overwrite a date:

  # Date format: yyyy-mm-dd
  $abif->write_tag('RUND', 3, '2007-01-22');
  print 'New date: ', $abif->data_collection_start_date();

To overwrite a time stamp:

  # Time format: hh:mm:ss.nn
  $abif->write_tag('RUNT', 4, '16:01:30.45');
  print 'New time: ', $abif->data_collection_stop_time();

To overwrite a comment:

  $abif->write_tag('CMNT', 1, 'New comment');
  print 'New comment: ', $abif->comment();
  
To overwrite noise values:

  my @noise = (3.14, 2.71, ...);
  $abif->write_tag('NOIS', 1, \@noise);
  print 'Noise values: ', $abif->noise();
  
To overwrite the capillary number:

  $abif->write_tag('LANE', 1, 95);
  print 'Capillary number: ', $abif->capillary_number();
  
and so on.

=cut

sub write_tag {
	my ($self, $tag_name, $tag_number, $data) = @_;
	my ($elem_type, $elem_size, $num_elems, $data_size);
	my $field;
	my $data_offset;
	my $packed_data;
	my $n_data; # Number of new elements
	my $n_bytes; # New data size in bytes

	if ($self->search_tag($tag_name, $tag_number)) {
		read($self->{'_FH'}, $field, 4);
		my ($et, $elem_size) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			unpack('nn', $field);
		read($self->{'_FH'}, $field, 8);
		my ($num_elems, $data_size) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			unpack('NN', $field);
		# Element type code (signed 16 bit integer)
		return 0 if ($et > 1023); # User data type: don't know how to pack
		# Unsupported data types
		return 0 if ($et == 9 or $et == 128 or $et == 256 or $et == 384);
		$elem_type = $self->{TYPES}{$et};
		return 0 unless (defined $elem_type); # Unknown data type

		#############
		# Pack data #
		#############
		if ($elem_type eq 'float') {
			if (ref($data) eq 'ARRAY') { # $data is reference to array
				$packed_data = '';
				foreach my $fl (@$data) {
					$packed_data .= $self->_decimal2ieee($fl);
				}
				$packed_data = pack('B*', $packed_data);
				$n_data = scalar(@$data);
			}
			elsif (ref($data)) { # Reference to what?!
				return 0;
			}
			else { # $data is scalar
				$packed_data = pack('B32', $self->_decimal2ieee($data));
				$n_data = 1;
			}
		}
		elsif ($elem_type eq 'double') { # currently, double is never used in ABIF
			if (ref($data) eq 'ARRAY') {
				$packed_data = pack('d*', @$data); # NOT PORTABLE!!!
				$n_data = scalar(@$data);
			}
			elsif (ref($data)) {
				return 0;
			}
			else {
				$packed_data = pack('d', $data); # NOT PORTABLE!!!
				$n_data = 1;
			}
		}
		elsif ($elem_type eq 'date') {
			return 0 if (ref($data));
			my ($yy, $mm, $dd) = ($data =~ /^(\d+)[^\d](\d+)[^\d](\d+)$/);
			return 0 unless (defined $yy and defined $mm and defined $dd);
			$packed_data = pack('nCC', $yy, $mm, $dd); # Assume $yy is non-negative
			$n_data = 1;
		}
		elsif ($elem_type eq 'time') {
			return 0 if (ref($data));
			my ($hh, $min, $sec, $ms) = ($data =~ /^(\d+)[^\d](\d+)[^\d](\d+)[^\d](\d+)$/);
			return 0 unless (defined $hh and defined $min and defined $sec and defined $ms);
			$packed_data = pack('C4', $hh, $min, $sec, $ms);
			$n_data = 1;
		}
		elsif ($elem_type eq 'pString') {
			if (ref($data) eq 'SCALAR') {
				return 0 if (length($$data) > 255);
				$n_data = length($$data);
				$packed_data = pack('CA*', $n_data, $$data);
				$n_data++;
			}
			elsif (ref($data)) {
				return 0;
			}
			else { # Assume $data is scalar
				return 0 if (length($data) > 255);
				$n_data = length($data);
				$packed_data = pack('CA*', $n_data, $data);
				$n_data++;			
			}
		}
		elsif ($elem_type eq 'cString') {
			if (ref($data) eq 'SCALAR') {
				$packed_data = pack('Z*', $$data);
				$n_data = scalar($$data);
			}
			elsif (ref($data)) {
				return 0;
			}
			else { # Assume $data is scalar
				$packed_data = pack('Z*', $data);
				$n_data = scalar($data);				
			}
		}
		elsif ($elem_type eq 'char') {
			if (ref($data) eq 'ARRAY') { # Assume it's an array of numerical values
				$packed_data = pack('c*', @$data);
				$n_data = scalar(@$data);
			}
			elsif (ref($data) eq 'SCALAR') { # Assume it's a string
				$packed_data = pack('A*', $$data);
				$n_data = length($$data);
			}
			elsif (ref($data)) {
				return 0;
			}
			else {
				$packed_data = pack('A*', $data);
				$n_data = length($data);
			}
		}
		else {
			if (ref($data) eq 'ARRAY') {
				$packed_data = pack($PACK_TMPL{$elem_type} . '*', @$data);
				$n_data = scalar(@$data);
			}
			elsif (ref($data)) {
				return 0;
			}
			else {
				$packed_data = pack($PACK_TMPL{$elem_type}, $data);
				$n_data = 1;
			}
		}
		$n_bytes = length($packed_data);

		##############
		# Write data #
		##############
		seek($self->{'_FH'}, -8, 1); # Go back to numelements field...
		print { $self->{'_FH'} } pack('NN', $n_data, $n_bytes); # ...and write new sizes
		# Current file handle position is at dataoffset field
		if ($n_bytes <= 4) { # Data can be stored in the data offset field
			print { $self->{'_FH'} } $packed_data;
			# Not necessary, but let's zero remaining bytes in the field, if any
			for (my $pad = $n_bytes; $pad < 4; $pad++) {
				print { $self->{'_FH'} } pack('x', 0);
			}
		}
		# If data is bigger than 4 bytes, we must check whether it fits
		# in the current position
		elsif ($n_bytes <= $data_size) { # It fits!
			# IMPORTANT: the following is from
			#
			#   http://perldoc.perl.org/functions/seek.html
			#
			# "Due to the rules and rigors of ANSI C, on some systems you have
			#  to do a seek whenever you switch between reading and writing."
			#
			# Since the last i/o operation done at this point may well be a write,
			# to be safe we perform a seek that does not change position:
			seek($self->{'_FH'}, 0, 1); # Don't move, please :)
			# The old data item position is in the data offset field
			read($self->{'_FH'}, $field, 4);
	 		$data_offset = unpack('N', $field);
			seek($self->{'_FH'}, $data_offset, 0);
			print { $self->{'_FH'} } $packed_data;
			# Not really necessary, but let's make some cleaning
			for (my $pad = $n_bytes; $pad < $data_size; $pad++) {
				print { $self->{'_FH'} } pack('x', 0);
			}
		}
		else { # It doesn't fit: append to the end of the file
			my $curr_pos = tell($self->{'_FH'}); # Save current position
			seek($self->{'_FH'}, 0, 2); # Seek the end of the file
			my $new_offset = tell($self->{'_FH'}); # Save new offset
			print { $self->{'_FH'} } $packed_data; # Append new data
			seek($self->{'_FH'}, $curr_pos, 0); # Go back to offset field
			print { $self->{'_FH'} } pack('N', $new_offset); # Update offset			
		}

		$self->{'_' . $tag_name . $tag_number} = undef; # To be re-read next time
		return 1;
	}
	
	return 0;
}

=head1 ACCESSOR METHODS

The methods in this section can be used to retrieve specific
information from a file without having to specify a tag.
It is strongly recommended that you read data from a file
by using one or more of these methods.

=head2 analyzed_data_for_channel()

  Usage     : @data = analyzed_data_for_channel($ch_num);
  Returns   : The channel analyzed data;
              () if the channel number is out of range
              or the data item is not in the file.
  ABIF Tag  : DATA9, DATA10, DATA11, DATA12, DATA205
  ABIF Type : short array
  File Type : ab1
  
There are four channels in an ABIF file, numbered from 1 to 4. An optional
channel number 5 exists in some files. The channel number is the argument of
the method.

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub analyzed_data_for_channel {
	my ($self, $channel_number) = @_;
	if ($channel_number == 5) {
		$channel_number = 205;
	}
	else {
		$channel_number += 8;
	}
	if ($channel_number < 9 or
		($channel_number > 12 and $channel_number != 205)) {
		return ();	
	}
	my $key = '_DATA' . $channel_number;
	unless (defined $self->{$key}) {
		my @data = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', $channel_number, 'n*');
		$self->{$key} = (@data) ? [ @data ] : [ ];
	}
	return @{$self->{$key}};
}

=head2 analysis_protocol_settings_name()

  Usage     : $s = $abif->analysis_protocol_settings_name();
  Returns   : The Analysis Protocol settings name;
              undef if the data item is not in the file.
  ABIF Tag  : APrN1
  ABIF Type : cString
  File Type : ab1
  
=cut

sub analysis_protocol_settings_name {
	my $self = shift;
	unless (defined $self->{'_APrN1'}) {
		($self->{'_APrN1'}) = $self->get_data_item('APrN', 1, 'Z*');
	}
	return $self->{'_APrN1'};
}

=head2 analysis_protocol_settings_version()

  Usage     : $s = $abif->analysis_protocol_settings_version();
  Returns   : The Analysis Protocol settings version;
              undef if the data item is not in the file.
  ABIF Tag  : APrV1
  ABIF Type : cString
  File Type : ab1

=cut

sub analysis_protocol_settings_version {
	my $self = shift;
	unless (defined $self->{'_APrV1'}) {
		($self->{'_APrV1'}) = $self->get_data_item('APrV', 1, 'Z*');
	}
	return $self->{'_APrV1'};
}

=head2 analysis_protocol_xml()

  Usage     : $xml = $abif->analysis_protocol_xml();
  Returns   : The Analysis Protocol XML string;
              undef if the data item is not in the file.
  ABIF Tag  : APrX1
  ABIF Type : char array
  File Type : ab1
  
=cut

sub analysis_protocol_xml {
	my $self = shift;
	unless (defined $self->{'_APrX1'}) {
		($self->{'_APrX1'}) = $self->get_data_item('APrX', 1, 'A*');
	}
	return $self->{'_APrX1'};
}

=head2 analysis_protocol_xml_schema_version()

  Usage     : $s = $abif->analysis_protocol_xml_schema_version();
  Returns   : The Analysis Protocol XML schema version;
              undef if the data item is not in the file.
  ABIF Tag  : APXV1
  ABIF Type : cString
  File Type : ab1
 
=cut

sub analysis_protocol_xml_schema_version {
	my $self = shift;
	unless (defined $self->{'_APXV1'}) {
		($self->{'_APXV1'}) = $self->get_data_item('APXV', 1, 'Z*');
	}
	return $self->{'_APXV1'};
}

=head2 analysis_return_code()

  Usage     : $rc = $abif->analysis_return_code();
  Returns   : The analysis return code;
              undef if the data item is not in the file.
  ABIF Tag  : ARTN1
  ABIF Type : long
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub analysis_return_code {
	my $self = shift;
	unless (defined $self->{'_ARTN1'}) {
		($self->{'_ARTN1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('ARTN', 1, 'N');
	}
	return $self->{'_ARTN1'};
}

=head2 avg_peak_spacing()

  Usage     : $aps = $abif->avg_peak_spacing();
  Returns   : The average peak spacing used in last analysis;
              undef if the data item is not in the file.
  ABIF Tag  : SPAC1
  ABIF Type : float
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub avg_peak_spacing() {
	my $self = shift;
	unless (defined $self->{'_SPAC1'}) {
		my $s = undef;
		($s) = $self->get_data_item('SPAC', 1, 'B32');
		$self->{'_SPAC1'} = $self->_ieee2decimal($s) if (defined $s);
	}
	return $self->{'_SPAC1'};
}

=head2 basecaller_apsf()

  Usage     : $n = $abif->basecaller_apsf();
  Returns   : The basecaller adaptive processing success flag;
              undef if the data item is not in the file.
  ABIF Tag  : ASPF1
  ABIF Type : short
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub basecaller_apsf {
	my $self = shift;
	unless (defined $self->{'_ASPF1'}) {
		($self->{'_ASPF1'}) =  map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('ASPF', 1, 'n');
	}
	return $self->{'_ASPF1'};
}

=head2 basecaller_bcp_dll()

  Usage     : $v = basecaller_bcp_dll();
  Returns   : A string with the basecalled BCP/DLL;
              undef if the data item is not in the file.
  ABIF Tag  : SPAC2
  ABIF Type : pString
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub basecaller_bcp_dll {
	my $self = shift;
	unless (defined $self->{'_SPAC2'}) {
		($self->{'_SPAC2'}) = $self->get_data_item('SPAC', 2, 'xA*');
	}
	return $self->{'_SPAC2'};	
}

=head2 basecaller_version()

  Usage     : $v = $abif->basecaller_version();
  Returns   : The basecaller version (e.g., 'KB 1.3.0');
              undef if the data item is not in the file.
  ABIF Tag  : SVER2
  ABIF Type : pString
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub basecaller_version {
	my $self = shift;
	unless (defined $self->{'_SVER2'}) {
		($self->{'_SVER2'}) = $self->get_data_item('SVER', 2, 'xA*');
	}
	return $self->{'_SVER2'};
}

=head2 basecalling_analysis_timestamp()

  Usage     : $s = $abif->basecalling_analysis_timestamp();
  Returns   : A time stamp;
              undef if the data item is not in the file.
  ABIF Tag  : BCTS1
  ABIF Type : pString
  File Type : ab1

Returns the time stamp for last successful basecalling analysis.

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub basecalling_analysis_timestamp {
	my $self = shift;
	unless (defined $self->{'_BCTS1'}) {
		($self->{'_BCTS1'}) = $self->get_data_item('BCTS', 1, 'xA*');
	}
	return $self->{'_BCTS1'};
}

=head2 base_locations()

  Usage     : @bl = $abif->base_locations();
  Returns   : The list of base locations;
              () if the data item is not in the file.
  ABIF Tag  : PLOC2
  ABIF Type : short array
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub base_locations {
	my $self = shift;
	unless (defined $self->{'_PLOC2'}) {
		my @bl = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('PLOC', 2, 'n*');
		$self->{'_PLOC2'} = (@bl) ? [ @bl ] : [ ];
	}
	return @{$self->{'_PLOC2'}};
}

=head2 base_locations_edited()

  Usage     : @bl = $abif->base_locations_edited();
  Returns   : The list of base locations (edited);
              () if the data item is not in the file.
  ABIF Tag  : PLOC1
  ABIF Type : short array
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub base_locations_edited {
	my $self = shift;
	unless (defined $self->{'_PLOC1'}) {
		my @bl = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('PLOC', 1, 'n*');
		$self->{'_PLOC1'} = (@bl) ? [ @bl ] : [ ];
	}
	return @{$self->{'_PLOC1'}};
}

=head2 base_order()

  Usage     : @bo = $abif->base_order();
  Returns   : An array of characters sorted by channel number;
              () if the data item is not in the file.
  ABIF Tag  : FWO_1
  ABIF Type : char array
  File Type : ab1

Returns an array of characters sorted by increasing channel number.
For example, if the list is C<('G', 'A', 'T', 'C')>
then G is channel 1, A is channel 2, and so on. If you want to do
the opposite, that is, mapping bases to their channels, use C<order_base()>
instead. See also the C<channel()> method.

=cut

sub base_order {
	my $self = shift;
	unless (defined $self->{'_FWO_1'}) {
		my ($bases) = $self->get_data_item('FWO_', 1, 'A*');
		if (defined $bases) {
			my @bo = split('', $bases);
			$self->{'_FWO_1'} = [ @bo ];			
		}
		else {
			$self->{'_FWO_1'} = [ ];
		}
	}
	return @{$self->{'_FWO_1'}};
}

=head2 base_spacing()

  Usage     : $spacing = $abif->base_spacing();
  Returns   : The spacing;
              undef if the data item is not in the file.
  ABIF Tag  : SPAC3
  ABIF Type : float
  File Type : ab1
 
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub base_spacing() {
	my $self = shift;
	unless (defined $self->{'_SPAC3'}) {
		my $s = undef;
		($s) = $self->get_data_item('SPAC', 3, 'B32');
		$self->{'_SPAC3'} = $self->_ieee2decimal($s) if (defined $s);

	}
	return $self->{'_SPAC3'};
}

=head2 buffer_tray_temperature()

  Usage     : @T = $abif->buffer_tray_temperature();
  Returns   : The buffer tray heater temperature in °C;
              () if the data item is not in the file.
  ABIF Tag  : BufT1
  ABIF Type : short array
  File Type : ab1

=cut

sub buffer_tray_temperature {
	my $self = shift;
	unless (defined $self->{'_BufT1'}) {
		my @T = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('BufT', 1, 'n*');
		$self->{'_BufT1'} = (@T) ? [ @T ] : [ ];
	}
	return @{$self->{'_BufT1'}};
}

=head2 capillary_number()

  Usage     : $cap_n = $abif->capillary_number();
  Returns   : The LANE/Capillary number;
              undef if the data item is not in the file.
  ABIF Tag  : LANE1
  ABIF Type : short
  File Type : ab1, fsa
  
=cut

sub capillary_number {
	my $self = shift;
	unless (defined $self->{'_LANE1'}) {
		($self->{'_LANE1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('LANE', 1, 'n');
	}
	return $self->{'_LANE1'};
}

=head2 channel()

  Usage     : $n = $abif->channel($base);
  Returns   : The channel number corresponding to a given base.
              undef if the data item is not in the file.
              
Returns the channel number corresponding to the given base.

The possible values for C<$base> are 'A', 'C', 'G' and 'T' (case insensitive).

=cut
sub channel {
	my $self = shift;
	my $base = shift;
	my %ob = ();
	
	$base =~ /^[ACGTacgt]$/ or return undef;
	%ob = $self->order_base();
	return $ob{uc($base)};
}

=head2 chem()

  Usage     : $s = $abif->chem();
  Returns   : The primer or terminator chemistry;
              undef if the data item is not in the file.
  ABIF Tag  : phCH1
  ABIF Type : pString
  File Type : ab1

Returns the primer or terminator chemistry (equivalent to CHEM in phd1 file).

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub chem {
	my $self = shift;
	unless (defined $self->{'_phCH1'}) {
		($self->{'_phCH1'}) = $self->get_data_item('phCH', 1, 'xA*');
	}
	return $self->{'_phCH1'};
}

=head2 comment()

  Usage     : $comment = $abif->comment();
              $comment = $abif->comment($n);
  Returns   : The comment about the sample;
              undef if the data item is not in the file.
  ABIF Tag  : CMNT1 ... CMNT 'N'
  ABIF Type : pString
  File Type : ab1, fsa

This is an optional data item. In some files there is more than one comment: the
optional argument is used to specify the number of the comment.

=cut

sub comment {
	my $self = shift;
	my $n = 1;
	$n = shift if (@_);
	my $tag_code = '_CMNT' . $n;
	unless (defined $self->{$tag_code}) {
		($self->{$tag_code}) = $self->get_data_item('CMNT', $n, 'xA*');
	}
	return $self->{$tag_code};
}

=head2 comment_title()

  Usage     : $comment_title = $abif->comment_title();
  Returns   : The comment title;
              undef if the data item is not in the file.
  ABIF Tag  : CTTL1
  ABIF Type : pString
  File Type : ab1, fsa

=cut

sub comment_title {
	my $self = shift;
	unless (defined $self->{'_CTTL1'}) {
		($self->{'_CTTL1'}) = $self->get_data_item('CTTL', 1, 'xA*');
	}
	return $self->{'_CTTL1'};
}

=head2 container_identifier()

  Usage     : $id = $abif->container_identifier();
  Returns   : The container identifier, a.k.a. plate barcode;
              undef if the data item is not in the file.
  ABIF Tag  : CTID1
  ABIF Type : cString
  File Type : ab1, fsa

=cut

sub container_identifier {
	my $self = shift;
	unless (defined $self->{'_CTID1'}) {
		($self->{'_CTID1'}) = $self->get_data_item('CTID', 1, 'Z*');
	}
	return $self->{'_CTID1'};
}

=head2 container_name()

  Usage     : $name = $abif->container_name();
  Returns   : The container name;
              undef if the data item is not in the file.
  ABIF Tag  : CTNM1
  ABIF Type : cString
  File Type : ab1, fsa

Usually, this is identical to the container identifier.

=cut

sub container_name {
	my $self = shift;
	unless (defined $self->{'_CTNM1'}) {
		($self->{'_CTNM1'}) = $self->get_data_item('CTNM', 1, 'Z*');
	}
	return $self->{'_CTNM1'};
}

=head2 container_owner()

  Usage     : $owner = $abif->container_owner();
  Returns   : The container's owner;
            : undef if the data item is not in the file.
  ABIF Tag  : CTow1
  ABIF Type : cString
  File Type : ab1
  
=cut

sub container_owner {
	my $self = shift;
	unless (defined $self->{'_CTOw1'}) {
		($self->{'_CTOw1'}) = $self->get_data_item('CTOw', 1, 'Z*');
	}
	return $self->{'_CTOw1'};
}

=head2 current()

  Usage     : @c = $abif->current();
  Returns   : Current, measured in milliamps;
              () if the data item is not in the file.
  ABIF Tag  : DATA6
  ABIF Type : short array
  File Type : ab1, fsa
  
=cut

sub current {
	my $self = shift;
	unless (defined $self->{'_DATA6'}) {
		my @c = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', 6, 'n*');
		$self->{'_DATA6'} = (@c) ? [ @c ] : [ ];
	}
	return @{$self->{'_DATA6'}};
}

=head2 data_collection_module_file()

  Usage     : $s = $abif->data_collection_module_file();
  Returns   : The data collection module file;
              undef if the data item is not in the file.
  ABIF Tag  : MODF1
  ABIF Type : pString
  File Type : ab1, fsa

=cut

sub data_collection_module_file {
	my $self = shift;
	unless (defined $self->{'_MODF1'}) {
		($self->{'_MODF1'}) = $self->get_data_item('MODF', 1, 'xA*');
	}
	return $self->{'_MODF1'};
}

=head2 data_collection_software_version()

  Usage     : $v = $abif->data_collection_software_version();
  Returns   : The data collection software version.
              undef if the data item is not in the file.
  ABIF Tag  : SVER1
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub data_collection_software_version {
	my $self = shift;
	unless (defined $self->{'_SVER1'}) {
		($self->{'_SVER1'}) = $self->get_data_item('SVER', 1, 'xA*');
	}
	return $self->{'_SVER1'};
}

=head2 data_collection_firmware_version()

  Usage     : $v = $abif->data_collection_firmware_version();
  Returns   : The data collection firmware version;
              undef if the data item is not in the file.
  ABIF Tag  : SVER3
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub data_collection_firmware_version {
	my $self = shift;
	unless (defined $self->{'_SVER3'}) {
		($self->{'_SVER3'}) = $self->get_data_item('SVER', 3, 'xA*');
	}
	return $self->{'_SVER3'};
}

=head2 data_collection_start_date()

  Usage     : $date = $abif->data_collection_start_date();
  Returns   : The Data Collection start date (yyyy-mm-dd);
              undef if the data item is not in the file.
  ABIF Tag  : RUND3
  ABIF Type : date
  File Type : ab1, fsa

=cut

sub data_collection_start_date {
	my $self = shift;
	unless (defined $self->{'_RUND3'}) {
		my ($y, $m, $d) = $self->get_data_item('RUND', 3, 'nCC');
		if (defined $d) {
			# Ehm, the year is specified as a signed integer...
			$y -= $SHORT_MAX if ($y >= $SHORT_MID);
			$self->{'_RUND3'} =  _make_date($y, $m, $d);
		}
	}
	return $self->{'_RUND3'};	
}

=head2 data_collection_start_time()

  Usage     : $time = $abif->data_collection_start_time();
  Returns   : The Data Collection start time (hh:mm:ss.nn);
              undef if the data item is not in the file.
  ABIF Tag  : RUNT3
  ABIF Type : time
  File Type : ab1, fsa

=cut

sub data_collection_start_time {
	my $self = shift;
	unless (defined $self->{'_RUNT3'}) {
		my ($hh, $mm, $ss, $nn) = $self->get_data_item('RUNT', 3, 'C4');
		$self->{'_RUNT3'} = _make_time($hh, $mm, $ss, $nn) if (defined $nn);
	}
	return $self->{'_RUNT3'};	
}

=head2 data_collection_stop_date()

  Usage     : $date = $abif->data_collection_stop_date();
  Returns   : The Data Collection stop date (yyyy-mm-dd);
              undef if the data item is not in the file.
  ABIF Tag  : RUND4
  ABIF Type : date
  File Type : ab1, fsa

=cut

sub data_collection_stop_date {
	my $self = shift;
	unless (defined $self->{'_RUND4'}) {
		my ($y, $m, $d) = $self->get_data_item('RUND', 4, 'nCC');
		if (defined $d) {
			$y -= $SHORT_MAX if ($y >= $SHORT_MID);
			$self->{'_RUND4'} =  _make_date($y, $m, $d);
		}
	}
	return $self->{'_RUND4'};	
}

=head2 data_collection_stop_time()

  Usage     : $time = $abif->data_collection_stop_time();
  Returns   : The Data Collection stop time (hh:mm:ss.nn);
              undef if the data item is not in the file.
  ABIF Tag  : RUNT4
  ABIF Type : time
  File Type : ab1, fsa

=cut

sub data_collection_stop_time {
	my $self = shift;
	unless (defined $self->{'_RUNT4'}) {
		my ($hh, $mm, $ss, $nn) = $self->get_data_item('RUNT', 4, 'C4');
		$self->{'_RUNT4'} =  _make_time($hh, $mm, $ss, $nn) if (defined $nn);
	}
	return $self->{'_RUNT4'};	
}

=head2 detector_heater_temperature()

  Usage     : $dt = $abif->detector_heater_temperature();
  Returns   : The detector cell heater temperature in °C;
              undef if the data item is not in the file.
  ABIF Tag  : DCHT1
  ABIF Type : short
  File Type : ab1

=cut

sub detector_heater_temperature {
	my $self = shift;
	unless (defined $self->{'_DCHT1'}) {
		($self->{'_DCHT1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DCHT', 1, 'n');
	}
	return $self->{'_DCHT1'};
}

=head2 downsampling_factor()

  Usage     : $df = $abif->downsampling_factor();
  Returns   : The downsampling factor;
              undef if the data item is not in the file.
  ABIF Tag  : DSam1
  ABIF Type : short
  File Type : ab1, fsa

=cut

sub downsampling_factor {
	my $self = shift;
	unless (defined $self->{'_DSam1'}) {
		($self->{'_DSam1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DSam', 1, 'n');
	}
	return $self->{'_DSam1'};
}

=head2 dye_name()

  Usage     : $n = $abif->dye_name($n);
  Returns   : The name of dye number $n;
              undef if the data item is not in the file;
              undef if $n is not in the range [1..5].
  ABIF Tag  : DyeN1, DyeN2, DyeN3, DyeN4, DyeN5
  ABIF Type : pString
  File Type : ab1, fsa

Dye 5 name is an optional tag.

=cut

sub dye_name {
	my ($self, $n) = @_;
	my $k = '_DyeN'. $n;
	unless (defined $self->{$k}) {
		if ($n > 0 and $n <= 5) {
			($self->{$k}) = $self->get_data_item('DyeN', $n, 'xA*');
		}
	}
	return $self->{$k};
}

=head2 dye_set_name()

  Usage     : $dsn = $abif->dye_set_name();
  Returns   : The dye set name;
              undef if the data item is not in the file.
  ABIF Tag  : DySN1
  ABIF Type : pString
  File Type : ab1, fsa

=cut

sub dye_set_name {
	my $self = shift;
	unless (defined $self->{'_DySN1'}) {
		($self->{'_DySN1'}) = $self->get_data_item('DySN', 1, 'xA*');
	}
	return $self->{'_DySN1'};
}

=head2 dye_significance()

  Usage     : $dsn = $abif->dye_significance($n);
  Returns   : The $n-th dye significance;
              undef if the data item is not in the file
  ABIF Tag  : DyeB1, DyeB2, DyeB3, DyeB4, DyeB5
  ABIF Type : char
  File Type : fsa

The argument must be an integer from 1 to 5. Dye significance 5 is optional.
The returned value is 'S' for standard, ' ' for sample;

=cut

sub dye_significance {
	my ($self, $n) = @_;
	my $k = '_DyeB' . $n;
	unless (defined $self->{$k}) {
		if ($n > 0 and $n <= 5) {
			($self->{$k}) = $self->get_data_item('DyeB', $n, 'A');
		}
	}
	return $self->{$k};
}

=head2 dye_type()

  Usage     : $dsn = $abif->dye_type();
  Returns   : The dye type;
              undef if the data item is not in the file.
  ABIF Tag  : phDY1
  ABIF Type : pString
  File Type : ab1

The dye type is equivalent to DYE in C<phd1> files.

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub dye_type {
	my $self = shift;
	unless (defined $self->{'_phDY1'}) {
		($self->{'_phDY1'}) = $self->get_data_item('phDY', 1, 'xA*');
	}
	return $self->{'_phDY1'};
}

=head2 dye_wavelength()

  Usage     : $n = $abif->dye_wavelength($n);
  Returns   : The wavelength of dye number $n;
              undef if the data item is not in the file;
              undef if $n is not in the range [1..5].
  ABIF Tag  : DyeW1, DyeW2, DyeW3, DyeW4, DyeW5
  ABIF Type : short
  File Type : ab1, fsa
  
Dye 5 wavelength is an optional data item.
  
=cut

sub dye_wavelength {
	my ($self, $n) = @_;
	my $k = '_DyeW'. $n;
	unless (defined $self->{$k}) {
		if ($n > 0 and $n <= 5) {
			($self->{$k}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DyeW', $n, 'n');
		}
	}
	return $self->{$k};
}

=head2 edited_quality_values()

  Usage     : @qv = $abif->edited_quality_values();
  Returns   : The list of edited quality values;
              () if the data item is not in the file.
  ABIF Tag  : PCON1
  ABIF Type : char array
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub edited_quality_values {
	my $self = shift;
	unless (defined $self->{'_PCON1'}) {
		my @qv = $self->get_data_item('PCON', 1, 'c*');
		$self->{'_PCON1'} = (@qv) ? [ @qv ] : [ ];
	}
	return @{$self->{'_PCON1'}};
}

=head2 edited_quality_values_ref()

  Usage    : $ref_to_qv = $abif->edited_quality_values_ref();
  Returns  : A reference to the list of edited quality values;
             a reference to the empty list if the data item
             is not in the file.
  ABIF Tag : PCON1
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub edited_quality_values_ref {
	my $self = shift;
	unless (defined $self->{'_PCON1'}) {
		my @qv = $self->get_data_item('PCON', 1, 'c*');
		$self->{'_PCON1'} = (@qv) ? [ @qv ] : [ ];
	}
	return $self->{'_PCON1'};
}

=head2 edited_sequence()

  Usage     : $sequence = edited_sequence();
  Returns   : The string of the edited basecalled sequence;
              undef if the data item is not in the file.
  ABIF Tag  : PBAS1
  ABIF Type : char array
  File Type : ab1
 
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
 
=cut

sub edited_sequence {
	my $self = shift;
	unless (defined $self->{'_PBAS1'}) {
		($self->{'_PBAS1'}) = $self->get_data_item('PBAS', 1, 'A*');
	}
	return $self->{'_PBAS1'};
}

=head2 edited_sequence_length()

  Usage     : $l = edited_sequence_length();
  Returns   : The length of the basecalled sequence;
              0 if the sequence is not in the file.
  File Type : ab1
  
=cut

sub edited_sequence_length() {
	my $self = shift;
	my $seq = $self->edited_sequence();
	return 0 unless defined $seq;
	return length($seq);
}

=head2 electrophoresis_voltage()

  Usage     : $v = $abif->electrophoresis_voltage();
  Returns   : The electrophoresis voltage setting in volts;
              undef if the data item is not found.
  ABIF Tag  : EPVt1
  ABIF Type : long
  File Type : ab1, fsa

=cut

sub electrophoresis_voltage {
	my $self = shift;
	unless (defined $self->{'_EPVt1'}) {
		($self->{'_EPVt1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('EPVt', 1, 'N');
	}
	return $self->{'_EPVt1'};
}

=head2 gel_type()

  Usage     : $s = $abif->gel_type();
  Returns   : The gel type description;
              undef if the data item is not in the file.
  ABIF Tag  : GTyp1
  ABIF Type : pString
  File Type : ab1, fsa

=cut

sub gel_type {
	my $self = shift;
	unless (defined $self->{'_GTyp1'}) {
		($self->{'_GTyp1'}) = $self->get_data_item('GTyp', 1, 'xA*');
	}
	return $self->{'_GTyp1'};
}

=head2 gene_mapper_analysis_method()

  Usage     : $s = $abif->gene_mapper_analysis_method();
  Returns   : The GeneMapper(R) software analysis method name;
              undef if the data item is not in the file.
  ABIF Tag  : ANME1
  ABIF Type : cString
  File Type : fsa

=cut

sub gene_mapper_analysis_method {
	my $self = shift;
	unless (defined $self->{'_ANME1'}) {
		($self->{'_ANME1'}) = $self->get_data_item('ANME', 1, 'Z*');
	}
	return $self->{'_ANME1'};
}

=head2 gene_mapper_panel_name()

  Usage     : $s = $abif->gene_mapper_panel_name();
  Returns   : The GeneMapper(R) software panel name;
              undef if the data item is not in the file.
  ABIF Tag  : PANL1
  ABIF Type : cString
  File Type : fsa

=cut

sub gene_mapper_panel_name {
	my $self = shift;
	unless (defined $self->{'_PANL1'}) {
		($self->{'_PANL1'}) = $self->get_data_item('PANL', 1, 'Z*');
	}
	return $self->{'_PANL1'};
}

=head2 gene_mapper_sample_type()

  Usage     : $s = $abif->gene_mapper_sample_type();
  Returns   : The GeneMapper(R) software Sample Type;
              undef if the data item is not in the file.
  ABIF Tag  : STYP1
  ABIF Type : cString
  File Type : fsa

=cut

sub gene_mapper_sample_type {
	my $self = shift;
	unless (defined $self->{'_STYP1'}) {
		($self->{'_STYP1'}) = $self->get_data_item('STYP', 1, 'Z*');
	}
	return $self->{'_STYP1'};
}

=head2 gene_scan_sample_name()

  Usage     : $s = $abif->gene_scan_sample_name();
  Returns   : The sample name for GeneScan(R) sample files;
              undef if the data item is not in the file.
  ABIF Tag  : SpNm1
  ABIF Type : pString
  File Type : fsa

=cut

sub gene_scan_sample_name {
	my $self = shift;
	unless (defined $self->{'_SpNm1'}) {
		($self->{'_SpNm1'}) = $self->get_data_item('SpNm', 1, 'xA*');
	}
	return $self->{'_SpNm1'};
}

=head2 injection_time()

  Usage     : $t = $abif->injection_time();
  Returns   : The injection time in seconds;
              undef if the data item is not in the file.
  ABIF Tag  : InSc1
  ABIF Type : long
  File Type : ab1, fsa

=cut

sub injection_time {
	my $self = shift;
	unless (defined $self->{'_InSc1'}) {
		($self->{'_InSc1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('InSc', 1, 'N');
	}
	return $self->{'_InSc1'};
}

=head2 injection_voltage()

  Usage     : $t = $abif->injection_voltage();
  Returns   : The injection voltage in volts;
              undef if the data item is not in the file
  ABIF Tag  : InVt1
  ABIF Type : long
  File Type : ab1, fsa

=cut

sub injection_voltage {
	my $self = shift;
	unless (defined $self->{'_InVt1'}) {
		($self->{'_InVt1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('InVt', 1, 'N');
	}
	return $self->{'_InVt1'};
}

=head2 instrument_class()

  Usage     : $class = $abif->instrument_class();
  Returns   : The instrument class;
              undef if the data item is not in the file.
  ABIF Tag  : HCFG1
  ABIF Type : cString
  File Type : ab1

=cut

sub instrument_class {
	my $self = shift;
	unless (defined $self->{'_HCFG1'}) {
		($self->{'_HCFG1'}) = $self->get_data_item('HCFG', 1, 'Z*');
	}
	return $self->{'_HCFG1'};	
}

=head2 instrument_family()

  Usage     : $class = $abif->instrument_family();
  Returns   : The instrument family;
              undef if the data item is not in the file.
  ABIF Tag  : HCFG2
  ABIF Type : cString
  File Type : ab1

=cut

sub instrument_family {
	my $self = shift;
	unless (defined $self->{'_HCFG2'}) {
		($self->{'_HCFG2'}) = $self->get_data_item('HCFG', 2, 'Z*');
	}
	return $self->{'_HCFG2'};	
}

=head2 instrument_name_and_serial_number()

  Usage     : $sn = instrument_name_and_serial_number()
  Returns   : The instrument name and the serial number;
              undef if the data item is not in the file.
  ABIF Tag  : MCHN1
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub instrument_name_and_serial_number {
	my $self = shift;
	unless (defined $self->{'_MCHN1'}) {
		($self->{'_MCHN1'}) = $self->get_data_item('MCHN', 1, 'xA*');
	}
	return $self->{'_MCHN1'};
}

=head2 instrument_param()

  Usage     : $param = $abif->instrument_param();
  Returns   : The instrument parameters;
              undef if the data item is not in the file.
  ABIF Tag  : HCFG4
  ABIF Type : cString
  File Type : ab1

=cut

sub instrument_param {
	my $self = shift;
	unless (defined $self->{'_HCFG4'}) {
		($self->{'_HCFG4'}) = $self->get_data_item('HCFG', 4, 'Z*');
	}
	return $self->{'_HCFG4'};	
}

=head2 is_capillary_machine()

  Usage     : $bool = $abif->is_capillary_machine();
  Returns   : A value > 0 if the data item is true;
              0 if the data item is false;
              undef if the data item is not in the file.
  ABIF Tag  : CpEP1
  ABIF Type : byte
  File Type : ab1, fsa

=cut

sub is_capillary_machine {
	my $self = shift;
	unless (defined $self->{'_CpEP1'}) {
		($self->{'_CpEP1'}) = $self->get_data_item('CpEP', 1, 'C');
	}
	return $self->{'_CpEP1'};
}

=head2 laser_power()

  Usage     : $n = $abif->laser_power();
  Returns   : The laser power setting in microwatt;
              undef if the data item is not in the file.
  ABIF Tag  : LsrP1
  ABIF Type : long
  File Type : ab1, fsa
  
=cut

sub laser_power {
	my $self = shift;
	unless (defined $self->{'_LsrP1'}) {
		($self->{'_LsrP1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('LsrP', 1, 'N');
	}
	return $self->{'_LsrP1'};
}

=head2 length_to_detector()

  Usage     : $n = $abif->length_to_detector();
  Returns   : The length of detector in cm;
              undef if the data item is not in the file.
  ABIF Tag  : LNTD1
  ABIF Type : short
  File Type : ab1, fsa
  
=cut

sub length_to_detector {
	my $self = shift;
	unless (defined $self->{'_LNTD1'}) {
		($self->{'_LNTD1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('LNTD', 1, 'n');
	}
	return $self->{'_LNTD1'};
}

=head2 mobility_file()

  Usage     : $mb = $abif->mobility_file()
  Returns   : The mobility file;
              undef if the data item is not in the file.
  ABIF Tag  : PDMF2
  ABIF Type : pString
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub mobility_file {
	my $self = shift;
	unless (defined $self->{'_PDMF2'}) {
		($self->{'_PDMF2'}) = $self->get_data_item('PDMF', 2, 'xA*');
	}
	return $self->{'_PDMF2'};
}


=head2 mobility_file_orig()

  Usage     : $mb = $abif->mobility_file_orig()
  Returns   : The mobility file (orig);
              undef if the data item is not in the file.
  ABIF Tag  : PDMF1
  ABIF Type : pString
  File Type : ab1
  
=cut

sub mobility_file_orig {
	my $self = shift;
	unless (defined $self->{'_PDMF1'}) {
		($self->{'_PDMF1'} ) = $self->get_data_item('PDMF', 1, 'xA*');
	}
	return $self->{'_PDMF1'};
}

=head2 model_number()

  Usage     : $mn = $abif->model_number();
  Returns   : The model number;
              undef if the data item is not in the file.
  ABIF Tag  : MODL1
  ABIF Type : char[4]
  File Type : ab1, fsa
  
=cut

sub model_number {
	my $self = shift;
	unless (defined $self->{'_MODL1'}) {
		($self->{'_MODL1'}) = $self->get_data_item('MODL', 1, 'A4');
	}
	return $self->{'_MODL1'};
}

=head2 noise()

  Usage     : %noise = $abif->noise();
  Returns   : The estimated noise for each dye;
              () if the data item is not in the file.
  ABIF Tag  : NOIS1
  ABIF Type : float array
  File Type : ab1

The keys of the returned hash are the values retrieved with C<base_order()>.
This is an optional data item. This method works only with files containing data
processed by the KB(tm) Basecaller.

=cut

sub noise {
	my $self = shift;
	unless (defined $self->{'_NOIS1'}) {
		my %noise = ();	
		my ($bits) = $self->get_data_item('NOIS', 1, 'B*');
		unless (defined $bits) {
			$self->{'_NOIS1'} = { };
		}
		else {
			my @bo = $self->base_order();
			for (my $i = 0; $i < length($bits); $i += 32) {
				# Convert to float
				$noise{$bo[$i / 32]} = $self->_ieee2decimal(substr($bits, $i, 32));
			}
			$self->{'_NOIS1'} = { %noise };
		}
	}	
	return %{$self->{'_NOIS1'}};
}

=head2 num_capillaries()

  Usage     : $nc = $abif->num_capillaries();
  Returns   : The number of capillaries;
              undef if the data item is not in the file.
  ABIF Tag  : NLNE1
  ABIF Type : short
  File Type : ab1, fsa
  
=cut

sub num_capillaries {
	my $self = shift;
	unless (defined $self->{'_NLNE1'}) {
		($self->{'_NLNE1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('NLNE', 1, 'n');
	}
	return $self->{'_NLNE1'};
}

=head2 num_dyes()

  Usage     : $n = $abif->num_dyes();
  Returns   : The number of dyes;
              undef if the data item is not in the file.
  ABIF Tag  : Dye#1
  ABIF Type : short
  File Type : ab1, fsa
  
=cut

sub num_dyes {
	my $self = shift;
	unless (defined $self->{'_Dye#1'}) {
		($self->{'_Dye#1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('Dye#', 1, 'n');
	}
	return $self->{'_Dye#1'};
}

=head2 num_scans()

  Usage     : $n = $abif->num_scans();
  Returns   : The number of scans;
              undef if the data item is not in the file.
  ABIF Tag  : SCAN1
  ABIF Type : long
  File Type : ab1, fsa
  
=cut

sub num_scans {
	my $self = shift;
	unless (defined $self->{'_SCAN1'}) {
		($self->{'_SCAN1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('SCAN', 1, 'N');
	}
	return $self->{'_SCAN1'};
}

=head2 official_instrument_name()

  Usage     : $name = $abif->official_instrument_name();
  Returns   : The official instrument name;
              undef if the data item is not in the file.
  ABIF Tag  : HCFG3
  ABIF Type : cString
  File Type : ab1

=cut

sub official_instrument_name {
	my $self = shift;
	unless (defined $self->{'_HCFG3'}) {
		($self->{'_HCFG3'}) = $self->get_data_item('HCFG', 3, 'Z*');
	}
	return $self->{'_HCFG3'};	
}

=head2 offscale_peaks()

  Usage     : @bytes = $abif->offscale_peaks($n);
  Returns   : The range of offscale peaks.
              () if the data item is not in the file.
  ABIF Tag  : OffS1 ... OffS 'N'
  ABIF Type : user
  File Type : fsa

This data item's type is a user defined data structure. As such, it is returned
as a list of bytes that must be interpreted by the caller. This is an optional
data item.

=cut

sub offscale_peaks {
	my $self = shift;
	my $n = shift;
	my $t = '_OffS' . $n;
	unless (defined $self->{$t}) {
		my (@bytes) = $self->get_data_item('OffS', $n, 'C*');
		$self->{$t} = (@bytes) ? [ @bytes ] : [ ];
	}\
	return @{$self->{$t}};
}


=head2 offscale_scans()

  Usage     : @p = $abif->offscale_scans();
  Returns   : A list of scans.
              () if the data item is not in the file.
  ABIF Tag  : OfSc1
  ABIF Type : long array
  File Type : ab1, fsa
  
Returns the list of scans that are marked off scale in Collection. This is an
optional data item.

=cut

sub offscale_scans {
	my $self = shift;
	unless (defined $self->{'_OfSc1'}) {
		my @off = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('OfSc', 1, 'N*');
		$self->{'_OfSc1'} = (@off) ? [ @off ] : [ ];
	}
	return @{$self->{'_OfSc1'}};
}

=head2 order_base()

  Usage     : %bases = $abif->order_base();
  Returns   : A mapping of the four bases to their channel numbers;
              () if the base order is not in the file.
  File Type : ab1

Returns the channel numbers corresponding to the bases.
This method does the opposite as C<base_order()> does.
See also the C<channel()> method.
  
=cut

sub order_base {
	my $self = shift;
	unless (defined $self->{'_OB'}) {
		my @bo = $self->base_order();
		my %ob = ();
		for (my $i = 0; $i < scalar(@bo); $i++) {
			$ob{$bo[$i]} = $i+1;
		}
		$self->{'_OB'} = { %ob };
	}
	return %{$self->{'_OB'}};
}

=head2 peak1_location()

  Usage     : $pl = peak1_location();
  Returns   : The peak 1 location;
              undef if the data item is not in the file.
  ABIF Tag  : B1Pt2
  ABIF Type : short
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub peak1_location {
	my $self = shift;
	unless (defined $self->{'_B1Pt2'}) {
		($self->{'_B1Pt2'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('B1Pt', 2, 'n');
	}
	return $self->{'_B1Pt2'};
}

=head2 peak1_location_orig()

  Usage     : $pl = peak1_location_orig();
  Returns   : The peak 1 location (orig);
              undef if the data item is not in the file.
  ABIF Tag  : B1Pt1
  ABIF Type : short
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub peak1_location_orig {
	my $self = shift;
	unless (defined $self->{'_B1Pt1'}) {
		($self->{'_B1Pt1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('B1Pt', 1, 'n');
	}
	return $self->{'_B1Pt1'};
}

=head2 peak_area_ratio()

  Usage     : $par = $abif->peak_area_ratio();
  Returns   : The peak area ratio;
              undef if the data item is not in the file.
  ABIF Tag  : phAR1
  ABIF Type : float
  File Type : ab1

Returns the peak area ratio (equivalent to TRACE_PEAK_AREA_RATIO in phd1 file).

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub peak_area_ratio {
	my $self = shift;
	unless (defined $self->{'_phAR1'}) {
		my $r = undef;
		($r) = $self->get_data_item('phAR', 1, 'B32');
		if (defined $r) {
			$self->{'_phAR1'} = $self->_ieee2decimal($r);
		}
	}
	return $self->{'_phAR1'};
}

=head2 peaks()

  Usage     : @pks = $abif->peaks(1);
  Returns   : An array of peak hashes. Each peak hash contains the following attributes:
              'position', 'height', 'beginPos', 'endPos', 'beginHI', 'endHI', 
              'area', 'volume', 'fragSize', 'isEdited', 'label';
              () if the data item is not in the file.
            
  ABIF Tag  : PEAK
  ABIF Type : user-defined structure
  File Type : fsa

Returns the data associated with PEAK data structures.

=cut

sub peaks {
	my ($self, $n) = @_;
	my $k = '_PEAK' . $n;
	my ($position, $height, $beginPos, $endPos, $beginHI, $endHI, $area, $volume, $fragSize, $isEdited, $label);
	my $s = undef;
	my @raw_data;
	my @peak_array;
	my $i;
	
	unless (defined $self->{$k}) {
		@raw_data = $self->get_data_item('PEAK', $n, '(NnNNnnNNB32nZ64)*');
		for ($i = 0; $i < @raw_data; $i += 11) {
			($position, $height, $beginPos, $endPos, $beginHI, $endHI, $area, $volume, $s, $isEdited, $label) = @raw_data[$i .. $i+10];
			$fragSize = $self->_ieee2decimal($s) if (defined $s);
			my $peak = {};
			$peak->{position} = $position;
			$peak->{height} = $height;
			$peak->{beginPos} = $beginPos;
			$peak->{endPos} = $endPos;
			$peak->{beginHI} = $beginHI;
			$peak->{endHI} = $endHI;
			$peak->{area} = $area;
			$peak->{volume} = $volume;
			$peak->{fragSize} = $fragSize;
			$peak->{isEdited} = $isEdited;
			$peak->{label} = $label;
			push @peak_array, $peak;
		}
	$self->{$k} = (@peak_array) ? [ @peak_array ] : [ ];
	}
	return @{$self->{$k}};
}

=head2 pixel_bin_size()

  Usage     : $n = $abif->pixel_bin_size();
  Returns   : The pixel bin size;
              undef if the data item is not in the file.
  ABIF Tag  : PXLB1
  ABIF Type : long
  File Type : ab1, fsa
  
=cut

sub pixel_bin_size {
	my $self = shift;
	unless (defined $self->{'_PXLB1'}) {
		($self->{'_PXLB1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('PXLB', 1, 'N');
	}
	return $self->{'_PXLB1'};
}

=head2 pixels_lane()

  Usage     : $n = $abif->pixels_lane();
  Returns   : The pixels averaged per lane;
              undef if the data item is not in the file.
  ABIF Tag  : NAVG1
  ABIF Type : short
  File Type : ab1, fsa
  
=cut

sub pixels_lane {
	my $self = shift;
	unless (defined $self->{'_NAVG1'}) {
		($self->{'_NAVG1'}) =  map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('NAVG', 1, 'n');
	}
	return $self->{'_NAVG1'};
}

=head2 plate_type()

  Usage     : $s = $abif->plate_type();
  Returns   : The plate type;
              undef if the data item is not in the file.
  ABIF Tag  : PTYP1
  ABIF Type : cString
  File Type : ab1, fsa
  
Returns the plate type. Allowed values are 96-Well, 384-Well;
 
=cut

sub plate_type {
	my $self = shift;
	unless (defined $self->{'_PTYP1'}) {
		($self->{'_PTYP1'}) = $self->get_data_item('PTYP', 1, 'Z*');
	}
	return $self->{'_PTYP1'};
}

=head2 plate_size()

  Usage     : $n = $abif->plate_size();
  Returns   : The plate size.
              undef if the data item is not in the file.
  ABIF Tag  : PSZE1
  ABIF Type : long
  File Type : ab1, fsa
  
Returns the number of sample positions in the container (allowed values are 96
and 384);  
  
=cut

sub plate_size {
	my $self = shift;
	unless (defined $self->{'_PSZE1'}) {
		($self->{'_PSZE1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('PSZE', 1, 'N');
	}
	return $self->{'_PSZE1'};
}

=head2 polymer_expiration_date()

  Usage     : $s = $abif->polymer_expiration_date()
  Returns   : The polymer lot expiration date;
              undef if the data item is not in the file.
  ABIF Tag  : SMED1
  ABIF Type : pString
  File Type : ab1, fsa
  
The format of the date is implementation dependent.

=cut

sub polymer_expiration_date {
	my $self = shift;
	unless (defined $self->{'_SMED1'}) {
		($self->{'_SMED1'}) = $self->get_data_item('SMED', 1, 'xA*');
	}
	return $self->{'_SMED1'};
}

=head2 polymer_lot_number()

  Usage     : $s = $abif->polymer_lot_number();
  Returns   : A string containing the polymer lot number;
              undef if the data item is not in the file.
  ABIF Tag  : SMLt1
  ABIF Type : pString
  File Type : ab1, fsa
  
The format of the date is implementation dependent.

=cut

sub polymer_lot_number {
	my $self = shift;
	unless (defined $self->{'_SMLt1'}) {
		($self->{'_SMLt1'}) = $self->get_data_item('SMLt', 1, 'xA*');
	}
	return $self->{'_SMLt1'};
}

=head2 power()

  Usage     : @p = $abif->power();
  Returns   : The power, measured in milliwatts;
              () if the data item is not in the file.
  ABIF Tag  : DATA7
  ABIF Type : short array
  File Type : ab1, fsa
  
=cut

sub power {
	my $self = shift;
	unless (defined $self->{'_DATA7'}) {
		my @p = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', 7, 'n*');
		$self->{'_DATA7'} = (@p) ? [ @p ] : [ ];
	}
	return @{$self->{'_DATA7'}};
}

=head2 quality_levels()

  Usage     : $n = $abif->quality_levels();
  Returns   : The maximum quality value;
              undef if the data item is not in the file.
  ABIF Tag  : phQL1
  ABIF Type : short
  File Type : ab1

Returns the maximum quality value (equivalent to QUALITY_LEVELS in phd1 file).

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
  
=cut

sub quality_levels {
	my $self = shift;
	unless (defined $self->{'_phQL1'}) {
		($self->{'_phQL1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('phQL', 1, 'n');
	}
	return $self->{'_phQL1'};
}


=head2 quality_values()

  Usage     : @qv = $abif->quality_values();
  Returns   : The list of quality values;
              () if the data item is not in the file.
  ABIF Tag  : PCON2
  ABIF Type : char array 
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub quality_values {
	my $self = shift;
	unless (defined $self->{'_PCON2'}) {
		# Load and cache quality values
		my @qv = $self->get_data_item('PCON', 2, 'c*');
		$self->{'_PCON2'} = (@qv) ? [ @qv ] : [ ];
	}
	return @{$self->{'_PCON2'}};
}

=head2 quality_values_ref()

  Usage     : $qvref = $abif->quality_values_ref();
  Returns   : A reference to the list of quality values;
              a reference to the empty list if
                the data item is not in the file.
  ABIF Tag  : PCON2
  ABIF Type : char array
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub quality_values_ref {
	my $self = shift;
	unless (defined $self->{'_PCON2'}) {
		# Load and cache quality values
		my @qv = $self->get_data_item('PCON', 2, 'c*');
		$self->{'_PCON2'} = (@qv) ? [ @qv ] : [ ];
	}
	return $self->{'_PCON2'};
}

=head2 raw_data_for_channel()

  Usage     : @data = $abif->raw_data_for_channel($channel_number);
  Returns   : The channel $channel_number raw data;
              () if the data item is not in the file.
  ABIF Tag  : DATA1, DATA2, DATA3, DATA4, DATA105
  ABIF Type : short array
  File Type : ab1, fsa
  
There are four channels in an ABIF file, numbered from 1 to 4.
An optional channel number 5 exists in some files.

=cut

sub  raw_data_for_channel {
	my ($self, $channel_number) = @_;
	if ($channel_number == 5) {
		$channel_number = 105;
	}
	if ($channel_number < 1 or
		($channel_number > 5 and $channel_number != 105)) {
		return ();	
	}
	my $k = '_DATA' . $channel_number;
	unless (defined $self->{$k}) {
		my @data = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', $channel_number, 'n*');
		$self->{$k} = (@data) ? [ @data ] : [ ];
	}

	return @{$self->{$k}};
}

=head2 raw_trace()

  Usage    : @trace = $abif->raw_trace($base);
  Returns  : The raw trace corresponding to $base;
             () if the data item is not in the file.
  File Type : ab1
  
The possible values for C<$base> are 'A', 'C', 'G' and 'T' (case insensitive).

=cut

sub raw_trace {
	my ($self, $base) = @_;
	my %ob = ();
	
	$base =~ /^[ACGTacgt]$/ or return ();
	%ob = $self->order_base();
	return $self->raw_data_for_channel($ob{uc($base)});
}

=head2 rescaling()

  Usage     : $name = $abif->rescaling();
  Returns   : The rescaling divisor for color data;
              undef if the data item is not in the file.
  ABIF Tag  : Scal1
  ABIF Type : float
  File Type : ab1, fsa
  
=cut

sub rescaling {
	my $self = shift;
	unless (defined $self->{'_Scal1'}) {
		my $r = undef;
		($r) = $self->get_data_item('Scal', 1, 'B32');
		if (defined $r) {
			$self->{'_Scal1'} = $self->_ieee2decimal($r);
		}
	}
	return $self->{'_Scal1'};
}

=head2 results_group()

  Usage     : $name = $abif->results_group();
  Returns   : The results group name;
              undef if the data item is not in the file.
  ABIF Tag  : RGNm1
  ABIF Type : cString
  File Type : ab1, fsa
  
=cut

sub results_group {
	my $self = shift;
	unless (defined $self->{'_RGNm1'}) {
		($self->{'_RGNm1'}) = $self->get_data_item('RGNm', 1, 'Z*');
	}
	return $self->{'_RGNm1'};
}

=head2 results_group_comment()

  Usage     : $s = $abif->results_group_comment();
  Returns   : The results group comment;
              undef if the data item is not in the file.
  ABIF Tag  : RGCm1
  ABIF Type : cString
  File Type : ab1, fsa
  
This is an optional data item.  
 
=cut

sub results_group_comment {
	my $self = shift;
	unless (defined $self->{'_RGCm1'}) {
		($self->{'_RGCm1'}) = $self->get_data_item('RGCm', 1, 'Z*');
	}
	return $self->{'_RGCm1'};
}

=head2 results_group_owner()

  Usage     : $s = $abif->results_group_owner();
  Returns   : The results group owner;
              undef if the data item is not in the file.
  ABIF Tag  : RGOw1
  ABIF Type : cString
  File Type : ab1
  
Returns the name entered as the owner of the results group, in the Results Group
editor. This is an optional data item.  
 
=cut

sub results_group_owner {
	my $self = shift;
	unless (defined $self->{'_RGOw1'}) {
		($self->{'_RGOw1'}) = $self->get_data_item('RGOw', 1, 'Z*');
	}
	return $self->{'_RGOw1'};
}

=head2 reverse_complement_flag()

  Usage     : $n = $abif->reverse_complement_flag();
  Returns   : The reverse complement flag;
              undef if the data item is not in the file.
  ABIF Tag  : RevC1
  ABIF Type : short
  File Type : ab1

This data item is from Sequencing Analysis v5.2 Software.

=cut

sub reverse_complement_flag {
	my $self = shift;
	unless (defined $self->{'_RevC1'}) {
		($self->{'_RevC1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('RevC', 1, 'n');
	}
	return $self->{'_RevC1'};
}

=head2 run_module_name()

  Usage     : $name = $abif->run_module_name();
  Returns   : The run module name;
              undef if the data item is not in the file.
  ABIF Tag  : RMdN1
  ABIF Type : cString
  File Type : ab1, fsa
  
This should be the same as the value returned by C<data_collection_module_file()>. 
  
=cut

sub run_module_name {
	my $self = shift;
	unless (defined $self->{'_RMdN1'}) {
		($self->{'_RMdN1'}) = $self->get_data_item('RMdN', 1, 'Z*');
	}
	return $self->{'_RMdN1'};	
}

=head2 run_module_version()

  Usage     : $name = $abif->run_module_version();
  Returns   : The run module version;
              undef if the data item is not in the file.
  ABIF Tag  : RMdV1
  ABIF Type : cString
  File Type : ab1, fsa

=cut

sub run_module_version {
	my $self = shift;
	unless (defined $self->{'_RMdV1'}) {
		($self->{'_RMdV1'}) = $self->get_data_item('RMdV', 1, 'Z*');
	}
	return $self->{'_RMdV1'};	
}

=head2 run_module_xml_schema_version()

  Usage     : $vers = $abif->run_module_xml_schema_version();
  Returns   : The run module XML schema version;
              undef if the data item is not in the file.
  ABIF Tag  : RMXV1
  ABIF Type : cString
  File Type : ab1, fsa
  
=cut

sub run_module_xml_schema_version {
	my $self = shift;
	unless (defined $self->{'_RMXV1'}) {
		($self->{'_RMXV1'}) = $self->get_data_item('RMXV', 1, 'Z*');
	}
	return $self->{'_RMXV1'};	
}

=head2 run_module_xml_string()

  Usage     : $xml = $abif->run_module_xml_string();
  Returns   : The run module XML string;
              undef if the data item is not in the file.
  ABIF Tag  : RMdX1
  ABIF Type : char array
  File Type : ab1, fsa
  
=cut

sub run_module_xml_string {
	my $self = shift;
	unless (defined $self->{'_RMdX1'}) {
		($self->{'_RMdX1'}) = $self->get_data_item('RMdX', 1, 'A*');
	}
	return $self->{'_RMdX1'};	
}

=head2 run_name()

  Usage     : $name = $abif->run_name();
  Returns   : The run name;
              undef if the data item is not in the file.
  ABIF Tag  : RunN1
  ABIF Type : cString
  File Type : ab1, fsa

=cut

sub run_name {
	my $self = shift;
	unless (defined $self->{'_RunN1'}) {
		($self->{'_RunN1'}) = $self->get_data_item('RunN', 1, 'Z*');
	}
	return $self->{'_RunN1'};
}

=head2 run_protocol_name()

  Usage     : $xml = $abif->run_protocol_name();
  Returns   : The run protocol name;
              undef if the data item is not in the file.
  ABIF Tag  : RPrN1
  ABIF Type : cString
  File Type : ab1, fsa
  
=cut

sub run_protocol_name {
	my $self = shift;
	unless (defined $self->{'_RPrN1'}) {
		($self->{'_RPrN1'}) = $self->get_data_item('RPrN', 1, 'Z*');
	}
	return $self->{'_RPrN1'};	
}

=head2 run_protocol_version()

  Usage     : $vers = $abif->run_protocol_version();
  Returns   : The run protocol version;
              undef if the data item is not in the file.
  ABIF Tag  : RPrV1
  ABIF Type : cString
  File Type : ab1, fsa
  
=cut

sub run_protocol_version {
	my $self = shift;
	unless (defined $self->{'_RPrV1'}) {
		($self->{'_RPrV1'}) = $self->get_data_item('RPrV', 1, 'Z*');
	}
	return $self->{'_RPrV1'};	
}

=head2 run_start_date()

  Usage     : $date = $abif->run_start_date();
  Returns   : The run start date (yyyy-mm-dd);
              undef if the data item is not in the file.
  ABIF Tag  : RUND1
  ABIF Type : date
  File Type : ab1, fsa

=cut

sub run_start_date {
	my $self = shift;
	unless (defined $self->{'_RUND1'}) {
		my ($y, $m, $d) = $self->get_data_item('RUND', 1, 'nCC');
		if (defined $d) {
			$y -= $SHORT_MAX if ($y >= $SHORT_MID);
			$self->{'_RUND1'} = _make_date($y, $m, $d);
		}
	}
	return $self->{'_RUND1'};	
}

=head2 run_start_time()

  Usage     : $time = $abif->run_start_time();
  Returns   : The run start time (hh:mm:ss.nn);
              undef if the data item is not in the file.
  ABIF Tag  : RUNT1
  ABIF Type : time
  File Type : ab1, fsa

=cut

sub run_start_time {
	my $self = shift;
	unless (defined $self->{'_RUNT1'}) {
		my ($hh, $mm, $ss, $nn) = $self->get_data_item('RUNT', 1, 'C4');
		$self->{'_RUNT1'} = _make_time($hh, $mm, $ss, $nn) if (defined $nn);
	}
	return $self->{'_RUNT1'};	
}

=head2 run_stop_date()

  Usage     : $date = $abif->run_stop_date();
  Returns   : The run stop date (yyyy-mm-dd);
              undef if the data item is not in the file.
  ABIF Tag  : RUND2
  ABIF Type : date
  File Type : ab1, fsa

=cut

sub run_stop_date {
	my $self = shift;
	unless (defined $self->{'_RUND2'}) {
		my ($y, $m, $d) = $self->get_data_item('RUND', 2, 'nCC');
		if (defined $d) {
			$y -= $SHORT_MAX if ($y >= $SHORT_MID);
			$self->{'_RUND2'} = _make_date($y, $m, $d);
		}
	}
	return $self->{'_RUND2'};	
}

=head2 run_stop_time()

  Usage     : $time = $abif->run_stop_time();
  Returns   : The run stop time (hh:mm:ss.nn);
              undef if the data item is not in the file.
  ABIF Tag  : RUNT2
  ABIF Type : time
  File Type : ab1, fsa

=cut

sub run_stop_time {
	my $self = shift;
	unless (defined $self->{'_RUNT2'}) {
		my ($hh, $mm, $ss, $nn) = $self->get_data_item('RUNT', 2, 'C4');
		$self->{'_RUNT2'} = _make_time($hh, $mm, $ss, $nn) if (defined $nn);
	}
	return $self->{'_RUNT2'};	
}

=head2 run_temperature()

  Usage     : $temp = $abif->run_temperature();
  Returns   : The run temperature setting in °C;
              undef if the data item is not in the file.
  ABIF Tag  : Tmpr1
  ABIF Type : long
  File Type : ab1, fsa
  
=cut

sub run_temperature {
	my $self = shift;
	unless (defined $self->{'_Tmpr1'}) {
		($self->{'_Tmpr1'}) = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('Tmpr', 1, 'N');
	}
	return $self->{'_Tmpr1'};
}

=head2 sample_file_format_version()

  Usage     : $v = $abif->sample_file_format_version();
  Returns   : The Sample File Format Version;
              undef if the data item is not in the file.
  ABIF Tag  : SVER4
  ABIF Type : pString
  File Type : fsa
  
The Sample File Format Version contains the version of the sample file format
used to write the file.

=cut

sub sample_file_format_version {
	my $self = shift;
	unless (defined $self->{'_SVER4'}) {
		($self->{'_SVER4'}) = $self->get_data_item('SVER', 4, 'xA*');
	}
	return $self->{'_SVER4'};
}

=head2 sample_name()

  Usage     : $name = $abif->sample_name();
  Returns   : The sample name;
              undef if the data item is not in the file.
  ABIF Tag  : SMPL1
  ABIF Type : pString
  File Type : ab1
  
=cut

sub sample_name {
	my $self = shift;
	unless (defined $self->{'_SMPL1'}) {
		($self->{'_SMPL1'}) = $self->get_data_item('SMPL', 1, 'xA*');
	}
	return $self->{'_SMPL1'};
}

=head2 sample_tracking_id()

  Usage     : $sample_id = $abif->sample_tracking_id();
  Returns   : The sample tracking ID;
              undef if the data item is not in the file.
  ABIF Tag  : LIMS1
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub sample_tracking_id {
	my $self = shift;
	unless (defined $self->{'_LIMS1'}) {
		($self->{'_LIMS1'}) = $self->get_data_item('LIMS', 1, 'xA*');
	}
	return $self->{'_LIMS1'};
}

=head2 scanning_rate()

  Usage     : @bytes = $abif->scanning_rate();
  Returns   : The scanning rate;
              () if the data item is not in the file.
  ABIF Tag  : Rate1
  ABIF Type : user
  File Type : ab1, fsa

This data item's type is a user defined data structure. As such, it is returned
as a list of bytes that must be interpreted by the caller.

=cut

sub scanning_rate {
	my $self = shift;
	unless (defined $self->{'_Rate1'}) {
		my (@bytes) = $self->get_data_item('Rate', 1, 'C*');
		$self->{'_Rate1'} = (@bytes) ? [ @bytes ] : [ ];
	}
	return @{$self->{'_Rate1'}};
}

=head2 scan_color_data_values()

  Usage     : @C = $abif->scan_color_data_values($n);
  Returns   : A list of color data values;
              () if the data item is not in the file.
  ABIF Tag  : OvrV1 ... OvrV 'N'
  ABIF Type : long array
  File Type : ab1, fsa
  
Returns the list of color data values for the locations listed by
C<scan_number_indices()>. This is an optional data item.

=cut

sub scan_color_data_values {
	my ($self, $n) = @_;
	my $k = '_OvrV' . $n;
	unless (defined $self->{$k}) {
		my @C = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('OvrV', $n, 'N*');
		$self->{$k} = (@C) ? [ @C ] : [ ];
	}
	return @{$self->{$k}};
}

=head2 scan_numbers()

  Usage     : @N = $abif->scan_numbers();
  Returns   : The scan numbers of data points; 
              () if the data item is not in the file.
  ABIF Tag  : Satd1
  ABIF Type : long array
  File Type : ab1, fsa

Returns an array of integers representing the scan numbers of data points,
which are flagged as saturated by data collection;

This is an optional data item.

=cut

sub scan_numbers {
	my $self = shift;
	unless (defined $self->{'_Satd1'}) {
		my @N = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('Satd', 1, 'N*');
		$self->{'_Satd1'} = (@N) ? [ @N ] : [ ];
	}
	return @{$self->{'_Satd1'}};
}

=head2 scan_number_indices()

  Usage     : @I = $abif->scan_number_indices($n);
  Returns   : A list of scan number indices;
              () if the data item is not in the file.
  ABIF Tag  : OvrI1 ... OvrI 'N'
  ABIF Type : long array
  File Type : ab1, fsa

Returns the list of scan number indices for scans with color data value greater
than 32767.

This is an optional data item.

=cut

sub scan_number_indices {
	my ($self, $n) = @_;
	my $k = '_OvrI' . $n;
	unless (defined $self->{$k}) {
		my @I = map { ($_ < $LONG_MID) ? $_ : $_ - $LONG_MAX }
			$self->get_data_item('OvrI', $n, 'N*');
		$self->{$k} = (@I) ? [ @I ] : [ ];
	}
	return @{$self->{$k}};
}

=head2 seqscape_project_name()

  Usage     : $name = $abif->seqscape_project_name();
  Returns   : SeqScape(R) project name;
              undef if the data item is not in the file.
  ABIF Tag  : PROJ4
  ABIF Type : cString
  File Type : ab1
  
This data item is in SeqScape(R) software sample files only. This is an optional
data item.
  
=cut

sub seqscape_project_name {
	my $self = shift;
	unless (defined $self->{'_PROJ4'}) {
		($self->{'_PROJ4'}) = $self->get_data_item('PROJ', 4, 'Z*');
	}
	return $self->{'_PROJ4'};
}

=head2 seqscape_project_template()

  Usage     : name = $abif->seqscape_project_template();
  Returns   : SeqScape(R) project template name;
              undef if the data item is not in the file.
  ABIF Tag  : PRJT1
  ABIF Type : cString
  File Type : ab1
  
This data item is in SeqScape(R) software sample files only. This is an optional
data item.
  
=cut

sub seqscape_project_template {
	my $self = shift;
	unless (defined $self->{'_PRJT1'}) {
		($self->{'_PRJT1'}) = $self->get_data_item('PRJT', 1, 'Z*');
	}
	return $self->{'_PRJT1'};
}

=head2 seqscape_specimen_name()

  Usage     : $name = $abif->seqscape_specimen_name();
  Returns   : SeqScape(R) specimen name;
              undef if the data item is not in the file.
  ABIF Tag  : SPEC1
  ABIF Type : cString
  File Type : ab1
  
This data item is in SeqScape(R) software sample files only. This is an optional
data item.
  
=cut

sub seqscape_specimen_name {
	my $self = shift;
	unless (defined $self->{'_SPEC1'}) {
		($self->{'_SPEC1'}) = $self->get_data_item('SPEC', 1, 'Z*');
	}
	return $self->{'_SPEC1'};
}

=head2 sequence()

  Usage     : $sequence = sequence();
  Returns   : The basecalled sequence;
              undef if the data item is not in the file.
  ABIF Tag  : PBAS2
  ABIF Type : char array
  File Type : ab1
  
This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.
 
=cut

sub sequence {
	my $self = shift;
	unless (defined $self->{'_PBAS2'}) {
		($self->{'_PBAS2'}) = $self->get_data_item('PBAS', 2, 'A*');
	}
	return $self->{'_PBAS2'};
}

=head2 sequence_length()

  Usage    : $l = sequence_length();
  Returns  : The length of the base called sequence;
             0 if the sequence is not in the file.
  File Type : ab1
  
=cut

sub sequence_length() {
	my $self = shift;
	my $seq = $self->sequence();
	return 0 unless defined $seq;
	return length($seq);
}

=head2 sequencing_analysis_param_filename()

  Usage     : $f = sequencing_analysis_param_filename();
  Returns   : The Sequencing Analysis parameters filename;
              undef if the data item is not in the file.
  ABIF Tag  : APFN2
  ABIF Type : pString
  File Type : ab1
  
=cut

sub sequencing_analysis_param_filename {
	my $self = shift;
	unless (defined $self->{'_APFN2'}) {
		($self->{'_APFN2'}) = $self->get_data_item('APFN', 2, 'xA*');
	}
	return $self->{'_APFN2'};
}

=head2 signal_level()

  Usage     : %signal_level = $abif->signal_level();
  Returns   : The signal level for each dye;
              () if the data item is not in the file.
  ABIF Tag  : S/N%1
  ABIF Type : short array
  File Type : ab1
  
The keys of the returned hash are the values retrieved with C<base_order()>.

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub signal_level {
	my $self = shift;
	unless (defined $self->{'_S/N%1'}) {
		my @sl = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('S/N%', 1, 'n*');
		unless (@sl) {
			$self->{'_S/N%1'} = { };
		}
		else {
			my %signal = ();
			my @bo = $self->base_order();
			for (my $i = 0; $i < scalar(@sl); $i++) {
				$signal{$bo[$i]} = $sl[$i];
			}
			$self->{'_S/N%1'} = { %signal };
		}
	}
	return %{$self->{'_S/N%1'}};
}

=head2 size_standard_filename()

  Usage     : $s = $abif->size_standard_filename();
  Returns   : The Size Standard file name;
              undef if the data item is not in the file.
  ABIF Tag  : StdF1
  ABIF Type : pString
  File Type : fsa
  
=cut

sub size_standard_filename {
	my $self = shift;
	unless (defined $self->{'_StdF1'}) {
		($self->{'_StdF1'}) = $self->get_data_item('StdF', 1, 'xA*');
	}
	return $self->{'_StdF1'};
}

=head2 snp_set_name()

  Usage     : $s = $abif->snp_set_name();
  Returns   : SNP set name;
              undef if the data item is not in the file.
  ABIF Tag  : SnpS1
  ABIF Type : pString
  File Type : fsa

This is an optional data item.
  
=cut

sub snp_set_name {
	my $self = shift;
	unless (defined $self->{'_SnpS1'}) {
		($self->{'_SnpS1'}) = $self->get_data_item('SnpS', 1, 'xA*');
	}
	return $self->{'_SnpS1'};
}

=head2 start_collection_event()

  Usage     : $s = $abif->start_collection_event();
  Returns   : The start collection event;
              undef if the data item is not in the file.
  ABIF Tag  : EVNT3
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub start_collection_event {
	my $self = shift;
	unless (defined $self->{'_EVNT3'}) {
		($self->{'_EVNT3'}) = $self->get_data_item('EVNT', 3, 'xA*');
	}
	return $self->{'_EVNT3'};
}

=head2 start_point()

  Usage     : $n = $abif->start_point();
  Returns   : The start point;
              undef if the data item is not in the file.
  ABIF Tag  : ASPt2
  ABIF Type : short
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub start_point {
	my $self = shift;
	unless (defined $self->{'_ASPt2'}) {
		($self->{'_ASPt2'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('ASPt', 2, 'n');
	}
	return $self->{'_ASPt2'};
}

=head2 start_point_orig()

  Usage     : $n = $abif->start_point_orig();
  Returns   : The start point (orig);
              undef if the data item is not in the file.
  ABIF Tag  : ASPt1
  ABIF Type : short
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub start_point_orig {
	my $self = shift;
	unless (defined $self->{'_ASPt1'}) {
		($self->{'_ASPt1'} ) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('ASPt', 1, 'n');
	}
	return $self->{'_ASPt1'};
}

=head2 start_run_event()

  Usage     : $s = $abif->start_run_event();
  Returns   : The start run event;
              undef if the data item is not in the file.
  ABIF Tag  : EVNT1
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub start_run_event {
	my $self = shift;
	unless (defined $self->{'_EVNT1'}) {
		($self->{'_EVNT1'}) = $self->get_data_item('EVNT', 1, 'xA*');
	}
	return $self->{'_EVNT1'};
}

=head2 stop_collection_event()

  Usage     : $s = $abif->stop_collection_event();
  Returns   : The stop collection event;
              undef if the data item is not in the file.
  ABIF Tag  : EVNT4
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub stop_collection_event {
	my $self = shift;
	unless (defined $self->{'_EVNT4'}) {
		($self->{'_EVNT4'}) = $self->get_data_item('EVNT', 4, 'xA*');
	}
	return $self->{'_EVNT4'};
}

=head2 stop_point()

  Usage     : $n = $abif->stop_point();
  Returns   : The stop point;
              undef if the data item is not in the file.
  ABIF Tag  : AEPt2
  ABIF Type : short
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub stop_point {
	my $self = shift;
	unless (defined $self->{'_AEPt2'}) {
		($self->{'_AEPt2'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('AEPt', 2, 'n');
	}
	return $self->{'_AEPt2'};
}

=head2 stop_point_orig()

  Usage     : $n = $abif->stop_point_orig();
  Returns   : The stop point (orig);
              undef if the data item is not in the file.
  ABIF Tag  : AEPt1
  ABIF Type : short
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub stop_point_orig {
	my $self = shift;
	unless (defined $self->{'_AEPt1'}) {
		($self->{'_AEPt1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('AEPt', 1, 'n');
	}
	return $self->{'_AEPt1'};
}


=head2 stop_run_event()

  Usage     : $s = $abif->stop_run_event();
  Returns   : The stop run event;
              undef if the data item is not in the file.
  ABIF Tag  : EVNT2
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub stop_run_event {
	my $self = shift;
	unless (defined $self->{'_EVNT2'}) {
		($self->{'_EVNT2'}) = $self->get_data_item('EVNT', 2, 'xA*');
	}
	return $self->{'_EVNT2'};
}

=head2 temperature()

  Usage     : @t = $abif->temperature();
  Returns   : The temperature, measured in °C
              () if the data item is not in the file.
  ABIF Tag  : DATA8
  ABIF Type : short array
  File Type : ab1, fsa
  
=cut

sub temperature {
	my $self = shift;
	unless (defined $self->{'_DATA8'}) {
		my @t = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', 8, 'n*');
		$self->{'_DATA8'} = (@t) ? [ @t ] : [ ];
	}
	return @{$self->{'_DATA8'}};
}

=head2 trace()

  Usage     : @trace = $abif->trace($base);
  Returns   : The (analyzed) trace corresponding to $base;
              () if the data item is not in the file.
  File Type : ab1
  
The possible values for C<$base> are 'A', 'C', 'G' and 'T'.

=cut

sub trace {
	my ($self, $base) = @_;
	my %ob = ();
	
	$base =~ /^[ACGTacgt]$/ or return ();
	%ob = $self->order_base();
	return $self->analyzed_data_for_channel($ob{uc($base)});
}

=head2 trim_probability_threshold()

  Usage     : $pr = $abif->trim_probability_threshold();
  Returns   : The trim probability threshold used;
              undef if the data item is not in the file.
  ABIF Tag  : phTR2
  ABIF Type : float
  File Type : ab1

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub trim_probability_threshold {
	my $self = shift;
	unless (defined $self->{'_phTR2'}) {
		my $pr = undef;
		($pr) = $self->get_data_item('phTR', 2, 'B32');
		$self->{'_phTR2'} = $self->_ieee2decimal($pr) if (defined $pr);
	}
	return $self->{'_phTR2'};
}

=head2 trim_region()

  Usage     : $n = $abif->trim_region();
  Returns   : The read positions;
              undef if the data item is not in the file.
  ABIF Tag  : phTR1
  ABIF Type : short
  File Type : ab1

Returns the read positions of the first and last bases in trim region; along
with C<trim_probability_threshold()>, this is equivalent to TRIM in phd1 file.

This data item is from SeqScape(R) v2.5 and Sequencing Analysis v5.2 Software.

=cut

sub trim_region {
	my $self = shift;
	unless (defined $self->{'_phTR1'}) {
		($self->{'_phTR1'}) = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('phTR', 1, 'n');
	}
	return $self->{'_phTR1'};
}


=head2 voltage()

  Usage     : @v = $abif->voltage();
  Returns   : The voltage, measured in decavolts;
              () if the data item is not in the file.
  ABIF Tag  : DATA5
  ABIF Type : short array
  File Type : ab1, fsa

=cut

sub voltage {
	my $self = shift;
	unless (defined $self->{'_DATA5'}) {
		my @v = map { ($_ < $SHORT_MID) ? $_ : $_ - $SHORT_MAX }
			$self->get_data_item('DATA', 5, 'n*');
		$self->{'_DATA5'} = (@v) ? [ @v ] : [ ];
	}
	return @{$self->{'_DATA5'}};
}

=head2 user()

  Usage     : $user = $abif->user();
  Returns   : The name of the user who created the plate;
              undef if the data item is not in the file.
  ABIF Tag  : User1
  ABIF Type : pString
  File Type : ab1, fsa
  
This is an optional data item.

=cut

sub user {
	my $self = shift;
	unless (defined $self->{'_User1'}) {
		($self->{'_User1'}) = $self->get_data_item('User', 1, 'xA*');
	}
	return $self->{'_User1'};
}

=head2 well_id()

  Usage     : $well_id = $abif->well_id();
  Returns   : The well ID;
              undef if the data item is not in the file.
  ABIF Tag  : TUBE1
  ABIF Type : pString
  File Type : ab1, fsa
  
=cut

sub well_id {
	my $self = shift;
	unless (defined $self->{'_TUBE1'}) {
		($self->{'_TUBE1'}) = $self->get_data_item('TUBE', 1, 'xA*');
	}
	return $self->{'_TUBE1'};
}

#==============================================================================

=head1 METHODS FOR ASSESSING QUALITY

The following methods compute some values that help assessing the quality
of the data.

=head2 avg_signal_to_noise_ratio()

  Usage    : $sn_ratio = $abif->avg_signal_to_noise_ratio()
  Returns  : The average signal to noise ratio;
             0 on error.

This method works only with files containing data processed by the KB(tm)
Basecaller. If the information needed to compute such value is missing, it
returns 0.

=cut

sub avg_signal_to_noise_ratio {
	my $self = shift;
	my %sl = $self->signal_level();
	return 0 unless %sl;
	my %noise = $self->noise();
	return 0 unless %noise;
	my $avg = 0;
	foreach my $base (keys %sl) {
		$avg += $sl{$base} / $noise{$base};
	}
	return $avg / scalar(keys %sl);
}


=head2 clear_range()

  Usage    : ($b, $e) = $abif->clear_range();
             ($b, $e) = $abif->clear_range(
                                $window_width,
                                $bad_bases_threshold,
                                $quality_threshold
                               );        
  Returns  : The clear range of the sequence;
             (-1, -1) if there is no clear range.

The Sequencing Analysis program determines the clear range of the sequence by
trimming bases from the 5' to 3' ends until fewer than 4 bases out of 20 have a
quality value less than 20. You can change these parameters by explicitly
passing arguments to this method (the default values are C<$window_width> = 20,
C<$bad_bases_threshold> = 4, C<$quality_threshold> = 20). Note that Sequencing
Analysis counts the bases starting from one, so you have to add one to the
return values to get consistent results.

=cut

sub clear_range {
	my $self = shift;
	my $window = 20;
	my $bad_bases = 4;
	my $threshold = 20;
	if (@_) {
		$window = shift;
		$bad_bases = shift;
		$threshold = shift;
	}
	return ($self->clear_range_start($window, $bad_bases, $threshold),
		$self->clear_range_stop($window, $bad_bases, $threshold));
}

=head2 clear_range_start()

  Usage    : $b = $abif->clear_range_start();
             $b = $abif->clear_range_start(
                          $window_width,
                          $bad_bases_threshold,
                          $quality_threshold
                         );
  Returns  : The clear range start position;
             -1 if no clear range exists.
  
See C<clear_range()>.

=cut

sub clear_range_start {
	my $self = shift;
	my $window = 20;
	my $bad_bases = 4;
	my $threshold = 20;
	if (@_) {
		$window = shift;
		$bad_bases = shift;
		$threshold = shift;
	}
	my $qv_ref = $self->quality_values_ref();
	return -1 unless defined $qv_ref;

	my $N = scalar(@$qv_ref);
	return -1 if ($N < $window); # Not enough quality values
	
	my $j; # Points to the rightmost element of next window
	my $n = 0; # Number of bad quality bases
	for ($j = 0; $j < $window; $j++) {
		if ($$qv_ref[$j] < $threshold) {
			$n++;
		}
	}
	while ($n >= $bad_bases and $j < $N) {
		if ($$qv_ref[$j - $window] < $threshold) {
			$n--;
		}
		if ($$qv_ref[$j] < $threshold) {
			$n++;
		}
		$j++;
	}
	return -1 if ($n >= $bad_bases); # No clear range
	return $j - $window;
}


=head2 clear_range_stop()

  Usage    : $e = $abif->clear_range_stop();
             $e = $abif->clear_range_stop(
                          $window_width,
                          $bad_bases_threshold,
                          $quality_threshold
                         );
  Returns  : The clear range stop position;
             -1 if no clear range exists.
  
See C<clear_range()>.

=cut

sub clear_range_stop {
	my $self = shift;
	my $window = 20;
	my $bad_bases = 4;
	my $threshold = 20;
	if (@_) {
		$window = shift;
		$bad_bases = shift;
		$threshold = shift;
	}
	my $qv_ref = $self->quality_values_ref();
	return -1 unless defined $qv_ref;
	
	my $N = scalar(@$qv_ref);
	return -1 if ($N < $window); # Not enough quality values
	
	my $j; # Points to the leftmost element of next window
	my $n = 0; # Number of bad quality bases
	for ($j = $N - 1; $j >= $N - $window; $j--) {
		if ($$qv_ref[$j] < $threshold) {
			$n++;
		}
	}	
	while ($n >= $bad_bases and $j >= 0) {
		if ($$qv_ref[$j + $window] < $threshold) {
			$n--;
		}
		if ($$qv_ref[$j] < $threshold) {
			$n++;
		}
		$j--;
	}
	return -1 if ($n >= $bad_bases); # No clear range
	return $j + $window;
}

=head2 contiguous_read_length()

  Usage    : ($b, $e) = $abif->contiguous_read_length(
                                $window_width,
                                $quality_threshold
                               );
             ($b, $e) = $abif->contiguous_read_length(
                                $window_width,
                                $quality_threshold,
                                $trim_ends
                               );
  Returns  : The start and stop position of the CRL;
             (-1, -1) if there is no CRL.

The CRL is (the length of) the longest uninterrupted stretch in a read such that
the average quality of any interval of C<$window_width> bases that is inside such
stretch never goes below C<$threshold>. The threshold must be at least 10. The
positions are counted from zero. If C<$trim_ends> is true, the ends of the CRL
are trimmed until there are no bases with quality values less than 10 within the
first five and the last five bases. Trimming is not applied by default. If there
is more than one CRL, the position of the first one is reported.

=cut

sub contiguous_read_length {
	my $self = shift;
	my $window_width = shift;
	my $qv_threshold = shift;
	my $trim = 0;
	$trim = shift if (@_);
	
	my $qv_ref = $self->quality_values_ref();
	my $N = scalar(@$qv_ref);
	return (-1, -1) if ($N < $window_width);
	my $crl = 0; # 1 if we are inside a crl, 0 otherwise
	my $start = 0;
	my $new_start = 0;
	my $stop = 0;
	my $threshold = $window_width * $qv_threshold;
	my $q = 0;
	my $i;
	for ($i = 0; $i < $window_width; $i++) {
		$q += $$qv_ref[$i];
	}
	$crl = 1 if ($q >= $threshold);
	while ($i < $N) {
		$q -= $$qv_ref[$i - $window_width];
		$q += $$qv_ref[$i];
		if ($crl and $q < $threshold) {
			$crl = 0;
			if ($stop - $start < $i - $new_start - 1) {
				$start = $new_start;
				$stop = $i - 1;
			}
		}
		elsif ( (not $crl) and $q >= $threshold) {
			$crl = 1;
			$new_start = $i - $window_width + 1;
		}
		$i++;
	}
	if ($crl and $stop - $start < $N - $new_start - 1) {
		$start = $new_start;
		$stop = $N - 1;
	}
	return ($start, $stop) unless $trim;
	
	my $j = 0;
	while ($start + 4 <= $stop and ($j < 5)) { # Trim the beginning
		 if ($$qv_ref[$start + $j] < 10) {
		 	$start += $j + 1;
		 	$j = 0;
		 }
		 else {
		 	$j++;
		 }
	}
	$j = 0;
	while ($start + 4 <= $stop and ($j < 5)) { # Trim the end
		if ($$qv_ref[$stop - $j] < 10) {
			$stop -= ($j + 1);
			$j = 0;
		}
		else {
			$j++;
		}
	}
	if ($stop - $start < 4) {
		for (my $k = $start; $k <= $stop; $k++) {
			if ($$qv_ref[$k] < 10) {
				return (-1, -1);
			}
		}
	}
	return ($start, $stop);
}

=head2 length_of_read()

  Usage    : $LOR = $abif->length_of_read(
                            $window_width,
                            $quality_threshold
                           );
             $LOR = $abif->length_of_read(
                            $window_width,
                            $quality_threshold,
                            $method
                           );
  Returns  : The Length Of Read (LOR) value.

The Length Of Read (LOR) score gives an approximate measure of the
usable range of high-quality or high-accuracy bases determined by quality
values. Such range can be determined in several ways. Two possible procedures
are currently implemented and described below.

If C<$method> is the string 'SequencingAnalysis' then the LOR is computed as the
widest range starting and ending with C<$window_width> bases whose average
quality is greater than or equal to C<$quality_threshold>. This is the default
method that is applied if this optional argument is omitted.

If C<$method> is the string 'GoodQualityWindows' then the LOR is computed as the
number of intervals of C<$window_width> bases whose average quality is greater
than or equal to  C<$quality_threshold>.

=cut

sub length_of_read {
	my $self = shift;
	my $window = shift;
	my $qv_threshold = shift;
	my $method = 'SequencingAnalysis';
	if (@_) { $method = shift; }
	
	my $qv_ref = $self->quality_values_ref();
	return 0 unless defined $qv_ref;
	my $LOR = 0;
	my $first = 0;
	my $last = 0;
	my $sum = 0;
	#my $avg = 0;
	
	my $threshold = $window * $qv_threshold;
	my $N = scalar(@$qv_ref);
	if ($N < $window) {
		#print STDERR "Not enough bases to compute LOR.\n";
		#print STDERR "At least $window bases are needed.\n";
		return 0;
	}
	
	# Dispatch according to the chosen method
	if ($method eq 'SequencingAnalysis') {
		# Compute the LOR score as the Sequencing Analysis program does
		# Compute the average quality value in the first window
		my $i;
		# Determine the first window with average qv >= $qv_threshold		
		my $start = 0;
		$sum = 0;
		for ($i = 0; $i < $window; $i++) {
			$sum += $$qv_ref[$i];
		}		
		if ($sum < $threshold) {
			do {
				$sum -= $$qv_ref[$i - $window];
				$sum += $$qv_ref[$i];
				$i++;
			} while ($sum < $threshold and $i < $N);
			$start = $i - $window;
		}
		
		# Determine the last window with average qv >= $qv_threshold
		my $stop = $N - 1;
		$sum = 0;
		for ($i = $stop; $i > $stop - $window; $i--) {
			$sum += $$qv_ref[$i];
		}
		if ($sum < $threshold) {
			do {
				$sum -= $$qv_ref[$i + $window];
				$sum += $$qv_ref[$i];
				$i--;
			} while ($sum < $threshold and $i >= 0);
			$stop = $i + $window;
		}
		
		$LOR = ($stop > $start) ? ($stop - $start + 1) : 0;
	} # end if ($method eq 'SequencingAnalysis')
	else { 
		# This method computes the LOR as the number
		# of windows of size $window having average quality value >= $threshold

		# Compute the average quality value in the first window
		$sum = 0;
		my $i; # Points to the right end of the next window to be processed
		for ($i = 0; $i < $window; $i++) {
			$sum += $$qv_ref[$i];
		}
		#$avg = $sum / $window;
		#if ($avg >= $qv_threshold) {
		if ($sum >= $threshold) {
			$LOR++;
		}
		while ($i < $N) {
			# Compute the average of the shifted window
			$sum -= $$qv_ref[$i - $window];
			$sum += $$qv_ref[$i];
			#$avg = $sum / $window;
			#if ($avg >= $qv_threshold) {
			if ($sum >= $threshold) {
				$LOR++;
			}
			$i++;		
		}
	}
	
	return $LOR;
}

=head2 num_low_quality_bases()

  Usage    : $n = $abif->num_low_quality_bases($threshold);
             $n = $abif->num_low_quality_bases(
                          $threshold,
                          $start,
                          $stop
                         );
  Returns  : The number of low quality bases;
             -1 on error.

Returns the number of quality bases in the range C<[$start,$stop]>, or in
the whole sequence if no range is specified, with quality value less than or
equal to C<$threshold>. Returns -1 if the information needed to compute such
value (i.e., the quality values) is missing from the file.

=cut

sub num_low_quality_bases {
	my $self = shift;
	my $max = shift;
	my $start;
	my $stop;
	if (@_) {
		$start = shift;
		$stop = shift;
	}
	else {
		$start = 0;
		$stop = -1;
	}
	
	my $qv_ref = $self->quality_values_ref();
	return -1 unless defined $qv_ref;
	my $n = 0;
	if ($start <= $stop) {
		for (my $i = $start; $i <= $stop; $i++) {
			if ($$qv_ref[$i] <= $max) {
				$n++;
			}
		}
	}
	else { # Count all the quality values
		foreach my $qv (@$qv_ref) {
			if ($qv <= $max) {
				$n++;
			}
		}
	}
	return $n;
}

=head2 num_high_quality_bases()

  Usage    : $n = $abif->num_high_quality_bases($threshold);
             $n = $abif->num_high_quality_bases(
                          $threshold,
                          $start,
                          $stop
                         );
  Returns  : The number of high quality bases;
             -1 on error.

Returns the number of quality bases in the range C<[$start,$stop]>, or in
the whole sequence if no range is specified, with quality value greater than or
equal to C<$threshold>. Returns -1 if the information needed to compute such
value (i.e., the quality values) is missing from the file.

=cut

sub num_high_quality_bases {
	my $self = shift;
	my $min = shift;
	my $start;
	my $stop;
	if (@_) {
		$start = shift;
		$stop = shift;
	}
	else {
		$start = 0;
		$stop = -1;
	}
	
	my $qv_ref = $self->quality_values_ref();
	return -1 unless defined $qv_ref;
	my $n = 0;
	if ($start <= $stop) {
		for (my $i = $start; $i <= $stop; $i++) {
			if ($$qv_ref[$i] >= $min) {
				$n++;
			}
		}
	}
	else { # Count all the quality values
		foreach my $qv (@$qv_ref) {
			if ($qv >= $min) {
				$n++;
			}
		}
	}
	return $n;
}

=head2 num_medium_quality_bases()

  Usage    : $n = $abif->num_medium_quality_bases(
                          $min_qv,
                          $max_qv
                         );
             $n = $abif->num_medium_quality_bases(
                          $min_qv,
                          $max_qv,
                          $start,
                          $stop
                         );
  Returns  : The number of medium quality bases;
             -1 on error.

Returns the number of quality bases in the range C<[$start,$stop]>, or in
the whole sequence if no range is specified, whose quality value is in the
(closed) range C<[$min_qv,$max_qv]>. Returns -1 if the information needed to
compute such value (i.e., the quality values) is missing from the file.

=cut

sub num_medium_quality_bases {
	my $self = shift;
	my $min = shift;
	my $max = shift;
	my $start;
	my $stop;
	if (@_) {
		$start = shift;
		$stop = shift;
	}
	else {
		$start = 0;
		$stop = -1;
	}

	my $qv_ref = $self->quality_values_ref();
	return -1 unless defined $qv_ref;
	my $n = 0;
	if ($start <= $stop) {
		for (my $i = $start; $i <= $stop; $i++) {
			if ($$qv_ref[$i] >= $min and $$qv_ref[$i] <= $max) {
				$n++;
			}
		}
	}
	else { # Count all the quality values
		foreach my $qv (@$qv_ref) {
			if ($qv >= $min and $qv <= $max) {
				$n++;
			}
		}
	}
	return $n;
}

=head2 sample_score()

  Usage    : $ss = $abif->sample_score();
           : $ss = $abif->sample_score(
                           $window_width,
                           $bad_bases_threshold,
                           $quality_threshold
                          );
  Returns  : The sample score of the sequence.
  
The sample score is the average quality value of the bases in the clear range of
the sequence (see C<clear_range()>). The method returns 0 if the information
needed to compute such value is missing or if the clear range is empty.

=cut

sub sample_score {
	my $self = shift;
	my $start;
	my $stop;
	if (@_) {
		my $window = shift;
		my $bad_bases = shift;
		my $threshold = shift;
		$start = $self->clear_range_start($window, $bad_bases, $threshold);
		$stop  = $self->clear_range_stop($window, $bad_bases, $threshold);
	}
	else {
		$start = $self->clear_range_start();
		$stop = $self->clear_range_stop();
	}
	my $qv_ref = $self->quality_values_ref();
	return 0 unless ($start >= 0) and ($start <= $stop) and defined $qv_ref;
	# Compute average quality value in the clear range
	my $sum = 0;
	for (my $i = $start; $i <= $stop; $i++) {
		$sum += $$qv_ref[$i];
	}
	return $sum / ($stop - $start + 1);
}

#==============================================================================

#=head1 HELPER FUNCTIONS
#
#The following methods are convenience methods to convert binary
#representations into decimal and vice versa.
#
# Although not documented, float numbers in ABI files
# apparently use standard IEEE representation.
#
#=cut
#
## See http://perldoc.perl.org/perlfaq4.html
#
#=head2 _bin2uint()
#
#  Usage    : _bin2uint($bit_string)
#  Returns  : the unsigned integer corresponding to the given bit string.
#
#Interprets the bit string as an unsigned integer. It works for binary strings
#up to 32 bits.
#
#=cut

sub _bin2uint {
	my $self = shift;
    return unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

#=head2 _uint2bin()
#
#  Usage    : _uint2bin($n)
#  Returns  : a 32 bit string representation of the given unsigned integer.
#
#Translates the given non negative integer into a 32 bit string.
#
#=cut

sub _uint2bin {
	my $self = shift;
    return unpack("B32", pack("N", shift));
}

#=head2 _bin2decimal()
#
#  Usage    : _bin2decimal($fractional_bit_string)
#  Returns  : the decimal value of the given fractional bit string.
#
#Converts a fractional binary number into its decimal value, e.g., 010.01000 is
#turned into 2.25.
#
#=cut

sub _bin2decimal {
	my $self = shift;
	my ($i, $f) = split('\.', shift);
	return _bin2uint($i) + (_bin2uint($f) / 2**length($f));
}

#=head2 _ieee2decimal()
#
#  Usage    : _ieee2decimal($string_32_bits)
#  Returns  : the floating number corresponding to the given 32 bit string.
#
#Interprets the 32 bit string in the standard IEEE format:
#
#  <sign (1 bit)><exponent (8 bits)><mantissa (23 bits)>
#  
#The value is computed as:
#
#  sign * 1.mantissa * 2**(exponent - 127)
#
#=cut

sub _ieee2decimal {
	my $self = shift;
	my $b = shift;
	my $sign = (substr($b, 0, 1) eq '0') ? 1 : -1;
	my $exp = unpack("N", pack("B32", substr("0" x 32 . substr($b, 1, 8), -32)));
	my $m = 1 + (unpack("N", pack("B32", substr("0" x 32 . substr($b, 9, 23), -32))) / (2**23));
	return $sign * $m * (2**($exp - 127));
}


#=head2 _decimal2ieee()
#
#  Usage    : _decimal2ieee($decimal_number)
#  Returns  : the 32 bit IEEE representation of (an approximation of) $decimal_number  
#
# Very trivial sub-optimal non-optimized in-some-cases-erroneous
# conversion into IEEE-754 32 bit float.
#=cut

sub _decimal2ieee {
	my $self = shift;
	my $decimal_number = shift;
	my $ieee;
	my $mantissa;
	my $exp;
	if ($decimal_number == 0.0) {
		return '00000000000000000000000000000000';
	}
	# First of all, let's try built-in packing
	$ieee = unpack('B32', pack('f', $decimal_number));
	# Check whether it's IEEE-754
	my $ff = $self->_ieee2decimal($ieee);
	if (abs(($decimal_number - $ff) / $ff) < 0.0001) { # Quick and dirty...
		return $ieee;
	}
	
	# If we get here, we've been unlucky...
	my $sign = '0';
	if ($decimal_number =~ /^-/) {
		$sign = '1';
		$decimal_number = abs($decimal_number);
	}
	my ($i, $f) = ($decimal_number =~ /^(\d*)(\.?\d*)$/);
	$i = 0 unless ($i);
	$f = 0 unless ($f);
	$mantissa = _uint2bin($i);
	$mantissa .= _fraction2bin($f);
	# Normalize
	$mantissa =~ /\./g;
	$exp = pos($mantissa);
	$mantissa =~ /[^\d]/g; # Failed match to reset pos()
	if ($mantissa =~ /1/g) {
		$exp -= pos($mantissa);
	}
	else {
		return '00000000000000000000000000000000'
	}
	# Bias exponent
	$exp = ($exp > 0) ? $exp += 126 : $exp += 127;
	$exp = _uint2bin($exp); # assume it is positive...
	$mantissa =~ s/\.//g;
	($mantissa) = ($mantissa =~ /^0*1(\d*)$/);
	$mantissa = 0 unless ($mantissa);
	while (length($mantissa) < 23) {
		$mantissa .= '0';
	}
	$mantissa = substr($mantissa, 0, 23);
	# (I should increase the last digit by 1 in some cases,
	# but I'm too lazy to implement it now...)
	$ieee = $sign;
	$ieee .= substr($exp, -8);
	$ieee .= $mantissa;

	return $ieee;
}

#=head2 _fraction2bin()
#
#  Usage    : _fraction2bin($fraction)
#             _fraction2bin($fraction, $prec)
#  Returns  : a binary representation of $fraction.
#
# A very simple implementation of decimal to binary conversion of fractions.
# $fraction must be 0 <= $fraction < 1;
#
#=cut
sub _fraction2bin {
	my $self = shift;
	my $f = shift;
	my $prec = 23;
	$prec = shift if @_;	
	my $digit;
	my $result = '.';
	for (my $i = 0; $i < $prec; $i++) {
		$f *= 2;
		$digit = int($f);
		$result .= $digit;
		$f -= $digit;
	}
	return $result;
}

########################################################################

# Takes year, month, day and makes a date of the form yyyy-mm-dd
sub _make_date {
	my ($y, $m, $d) = @_;
	my $date = $y . '-';
	$date .= ($m < 10) ? '0' . $m : $m;
	$date .= '-';
	$date .= ($d < 10) ? '0' . $d : $d;
	return $date;
}

# Returns time in the format hh-mm-ss.nn
sub _make_time {
	my ($hh, $mm, $ss, $nn) = @_;
	my $time = '';
	$time .= ($hh < 10) ? '0' . $hh : $hh;
	$time .= ':';
	$time .= ($mm < 10) ? '0' . $mm : $mm;
	$time .= ':';
	$time .= ($ss < 10) ? '0' . $ss : $ss;
	$time .= '.';
	$time .= ($nn < 10) ? '0' . $nn : $nn;
	return $time;
}

sub _debug {
	my $self = shift;
	confess "usage: thing->_debug(level)" unless @_ == 1;
	my $level = shift;
	if (ref($self))  {
		$self->{"_DEBUG"} = $level; # just myself
	} 
	else {
		$Debugging = $level; # whole class
	}
}

sub DESTROY {
	my $self = shift;
	if ($Debugging || $self->{"_DEBUG"}) {
		carp "Destroying $self " . $self->name;
	}
}

sub END {
	if ($Debugging) {
		print "All ABIF objects are going away now.\n";
	}
}
    
=head1 AUTHOR

Nicola Vitacolonna, C<< <vitacolonna at appliedgenomics.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-bio-trace-abif at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Bio-Trace-ABIF>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Bio::Trace::ABIF

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Bio-Trace-ABIF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bio-Trace-ABIF>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bio-Trace-ABIF>

=item * Search CPAN

L<http://search.cpan.org/dist/Bio-Trace-ABIF>

=back

=head1 SEE ALSO

See L<http://www.appliedbiosystems.com/support/> for the ABIF format file
specification sheet.

There is an ABI module on CPAN (L<http://search.cpan.org/~malay/>).

bioperl-ext also parses ABIF files and other trace formats.

You are welcome at L<http://www.appliedgenomics.org>!

=head1 ACKNOWLEDGEMENTS

Thanks to Simone Scalabrin for many helpful suggestions and for the first
implementation of the C<length_of_read()> method the way Sequencing Analysis
does it (and for rating this module five stars)!
Thanks to Fabrizio Levorin and other people reporting bugs!

Some explanation about how Sequencing Analysis computes some parameters has
been found at L<http://keck.med.yale.edu/dnaseq/>.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2010 Nicola Vitacolonna, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

Feel free to rate this module on CPAN!

=cut

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=cut

1; # End of Bio::Trace::ABIF
