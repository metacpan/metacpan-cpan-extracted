package D64::Disk::Dir::Item;

=head1 NAME

D64::Disk::Dir::Item - Handling individual Commodore (D64/D71/D81) disk image directory items in pure Perl

=head1 SYNOPSIS

  use D64::Disk::Dir::Item qw(:all);

  # Create a new disk image directory item instance:
  my $item = D64::Disk::Dir::Item->new($data);
  my $item = D64::Disk::Dir::Item->new(@data);
  my $item = D64::Disk::Dir::Item->new(\@data);

  # Fetch item data as a scalar of 30 bytes:
  my $data = $item->data();
  # Fetch item data as an array of 30 bytes:
  my @data = $item->data();

  # Update item providing 30 bytes of scalar data:
  $item->data($data);
  # Update item given array with 30 bytes of data:
  $item->data(@data);
  $item->data(\@data);

  # Get/set the actual file type:
  my $type = $item->type();
  $item->type($type);

  # Get/set "closed" flag (when not set produces "*", or "splat" files):
  my $is_closed = $item->closed();
  $item->closed($is_closed);

  # Get/set "locked" flag (when set produces ">" locked files):
  my $is_locked = $item->locked();
  $item->locked($is_locked);

  # Get/set track location of first sector of file:
  my $track = $item->track();
  $item->track($track);

  # Get/set sector location of first sector of file:
  my $sector = $item->sector();
  $item->sector($sector);

  # Get/set 16 character filename (in CBM ASCII, padded with $A0):
  my $name = $item->name();
  $item->name($name);

  # Get/set track location of first side-sector block (REL file only):
  my $side_track = $item->side_track();
  $item->side_track($side_track);

  # Get/set sector location of first side-sector block (REL file only):
  my $side_sector = $item->side_sector();
  $item->side_sector($side_sector);

  # Get/set relative file record length (REL file only):
  my $record_length = $item->record_length();
  $item->record_length($record_length);

  # Get/set file size in sectors:
  my $size = $item->size();
  $item->size($size);

  # Print out formatted disk image directory item:
  $item->print();

  # Validate item data against all possible errors:
  my $is_valid = $item->validate();

  # Check if directory item contains information about the actual disk file:
  my $is_empty = $item->empty();

  # Check if directory item is writable and can be replaced by any new file:
  my $is_writable = $item->writable();

  # Clone disk directory item:
  my $clone = $item->clone();

  # Check if filename matches given CBM ASCII pattern:
  my $is_matched = $item->match_name($petscii_pattern);

  # Convert any given file type into its three-letter printable string representation:
  my $string = D64::Disk::Dir::Item->type_to_string($type);

=head1 DESCRIPTION

C<D64::Disk::Dir::Item> provides a helper class for C<D64::Disk::Layout> module, enabling users to manipulate individual directory entries in an object oriented way without the hassle of worrying about the meaning of individual bits and bytes describing each entry in a disk directory. The whole family of C<D64::Disk::Layout> modules has been implemented in pure Perl as an alternative to Per Olofsson's "diskimage.c" library originally written in an ANSI C.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.07';

use parent 'Clone';

use Data::Dumper;
use Readonly;
use Scalar::Util qw(looks_like_number);
use Text::Convert::PETSCII qw(:convert);
use Try::Tiny;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Setup package constant names:
our (
    # File type constant names:
    $T_DEL, $T_SEQ, $T_PRG, $T_USR, $T_REL, $T_CBM, $T_DIR,

    # Data offset constant names:
    $I_TYPE, $I_NAME, $I_CLOSED, $I_LOCKED,
    $I_TRACK, $I_SECTOR, $I_SIZE_LO, $I_SIZE_HI,
    $I_SIDE_TRACK, $I_SIDE_SECTOR, $I_RECORD_LENGTH,

    # Other package constant names:
    $ITEM_SIZE,
);

# File type constant values:
my %file_type_constants = (
    T_DEL => 0b000,
    T_SEQ => 0b001,
    T_PRG => 0b010,
    T_USR => 0b011,
    T_REL => 0b100,
    T_CBM => 0b101,
    T_DIR => 0b110,
);

# Data offset constant values:
my %data_offset_constants = (
    I_TYPE          => 0x00,
    I_CLOSED        => 0x00,
    I_LOCKED        => 0x00,
    I_TRACK         => 0x01,
    I_SECTOR        => 0x02,
    I_NAME          => 0x03,
    I_SIDE_TRACK    => 0x13,
    I_SIDE_SECTOR   => 0x14,
    I_RECORD_LENGTH => 0x15,
    I_SIZE_LO       => 0x1c,
    I_SIZE_HI       => 0x1d,
);

# Other package constant values:
my %other_package_constants = (
    ITEM_SIZE => 0x1e,
);

# Setup package constant values:
my %all_constants = (%file_type_constants, %data_offset_constants, %other_package_constants);
while (my ($name, $value) = each %all_constants) {
    if ($] < 5.008) {
        eval sprintf q{
            Readonly \\$%s => %d;
        }, $name, $value;
    }
    else {
       eval sprintf q{
            Readonly $%s => %d;
        }, $name, $value;
    }
}

use base qw(Exporter);
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'types'} = [ qw($T_DEL $T_SEQ $T_PRG $T_USR $T_REL $T_CBM $T_DIR) ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'types'}} ];
our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );
our @EXPORT = qw();

=head2 new

Create an instance of a C<D64::Disk::Dir::Item> class as an empty directory entry:

  my $item = D64::Disk::Dir::Item->new();

Create an instance of a C<D64::Disk::Dir::Item> class providing 30 bytes of data retrieved from a disk directory:

  my $item = D64::Disk::Dir::Item->new(data => $data);
  my $item = D64::Disk::Dir::Item->new(data => \@data);

=cut

sub new {
    my ($this) = shift;
    my $class = ref ($this) || $this;
    my $object = $class->_init();
    my $self = bless $object, $class;
    $self->data(@_) if @_;
    return $self;
}

sub _init {
    my ($class) = @_;
    my @object = map { chr 0x00 } (0x01 .. $ITEM_SIZE);
    return \@object;
}

=head2 data

Fetch item data as a scalar of 30 bytes:

  my $data = $item->data();

Fetch item data as an array of 30 bytes:

  my @data = $item->data();

Update item providing 30 bytes of scalar data retrieved from a disk directory:

  $item->data($data);

Update item given array with 30 bytes of data retrieved from a disk directory:

  $item->data(@data);
  $item->data(\@data);

=cut

sub data {
    my ($self, @args) = @_;

    if (scalar @args > 0) {
        if (scalar @args == 1) {
            my ($arg) = @args;
            if (ref $arg eq 'ARRAY') {
                @args = @{$arg};
            }
        }

        if (scalar @args == 1) {
            my ($arg) = @args;
            unless (ref $arg) {
                unless (length $arg == 30) {
                    die q{Unable to set directory item data: Invalid length of data};
                }
                @{$self} = split //, $arg;
            }
            else {
                die q{Unable to set directory item data: Invalid arguments given};
            }
        }
        elsif (scalar @args == 30) {
            for (my $i = 0; $i < @args; $i++) {
                my $byte_value = $args[$i];
                unless ($self->_is_valid_data_type($byte_value)) {
                    die sprintf q{Invalid data type at offset %d (%s)}, $i, ref $args[$i];
                }
                unless ($self->_is_valid_byte_value($byte_value)) {
                    die sprintf q{Invalid byte value at offset %d ($%x)}, $i, $byte_value;
                }
            }
            @{$self} = @args;
        }
        else {
            die q{Unable to set directory item data: Invalid amount of data};
        }
    }

    return unless defined wantarray;
    return wantarray ? @{$self} : join '', @{$self};
}

sub _is_valid_data_type {
    my ($self, $byte_value) = @_;

    unless (ref $byte_value) {
        return 1;
    }

    return 0;
}

sub _is_valid_byte_value {
    my ($self, $byte_value) = @_;

    if (length ($byte_value) == 1 && ord ($byte_value) >= 0x00 && ord ($byte_value) <= 0xff) {
        return 1;
    }

    return 0;
}

sub _is_valid_number_value {
    my ($self, $number_value) = @_;

    if ($self->is_int($number_value) && $number_value >= 0x00 && $number_value <= 0xff) {
        return 1;
    }

    return 0;
}

sub is_valid_string_value {
    my ($self, $string_value) = @_;

    no bytes;
    unless (grep { ord ($_) < 0x00 || ord ($_) > 0xff } split //, $string_value) {
        return 1;
    }

    return 0;
}

=head2 bytes

C<bytes> is simply a convenient alias for C<data>.

Fetch item data as a scalar of 30 bytes:

  my $bytes = $item->bytes();

Fetch item data as an array of 30 bytes:

  my @bytes = $item->bytes();

Update item providing 30 bytes of scalar data retrieved from a disk directory:

  $item->bytes($bytes);

Update item given array with 30 bytes of data retrieved from a disk directory:

  $item->bytes(@bytes);
  $item->bytes(\@bytes);

=cut

*bytes = \&data;

=head2 type

Get the actual file type:

  my $type = $item->type();

Set the actual file type:

  $item->type($type);

The following file type constants are the only valid values that may be used to update current item type: C<$T_DEL>, C<$T_SEQ>, C<$T_PRG>, C<$T_USR>, C<$T_REL>, C<$T_CBM>, and C<$T_DIR>.

=cut

sub type {
    my ($self, $type) = @_;

    if (defined $type) {
        if (ref $type) {
            die q{Invalid file type constant (scalar value expected)};
        }
        unless ($self->is_int($type)) {
            die q{Invalid file type constant (type constant expected)};
        }
        if ($type - ($type & 0b1111)) {
            die q{Invalid file type constant (only bits 0-3 can be set)};
        }
        my @valid_values = (0b000, 0b001, 0b010, 0b011, 0b100, 0b101, 0b110);
        unless (grep { $_ == $type } @valid_values) {
            die q{Illegal file type constant};
        }
        $self->[$I_TYPE] = chr ((ord ($self->[$I_TYPE]) & 0b11110000) | $type);
    }

    return ord ($self->[$I_TYPE]) & 0b1111;
}

=head2 closed

Get "closed" flag:

  my $is_closed = $item->closed();

Returns true when "closed" flag is set, and false otherwise.

Set "closed" flag:

  $item->closed($is_closed);

When "closed" flag is not set, it produces "*", or "splat" files.

=cut

sub closed {
    my ($self, $is_closed) = @_;

    if (defined $is_closed) {
        if (ref $is_closed) {
            die q{Invalid "closed" flag};
        }
        my $closed_bit = $is_closed ? 0b10000000 : 0b00000000;
        $self->[$I_CLOSED] = chr ((ord ($self->[$I_CLOSED]) & 0b01111111) | $closed_bit);
    }

    return (ord ($self->[$I_CLOSED]) & 0b10000000) == 0b10000000;
}

=head2 locked

Get "locked" flag:

  my $is_locked = $item->locked();

Returns true when "locked" flag is set, and false otherwise.

Set "locked" flag:

  $item->locked($is_locked);

When "locked" flag is set, it produces ">" locked files.

=cut

sub locked {
    my ($self, $is_locked) = @_;

    if (defined $is_locked) {
        if (ref $is_locked) {
            die q{Invalid "locked" flag};
        }
        my $locked_bit = $is_locked ? 0b01000000 : 0b00000000;
        $self->[$I_LOCKED] = chr ((ord ($self->[$I_LOCKED]) & 0b10111111) | $locked_bit);
    }

    return (ord ($self->[$I_LOCKED]) & 0b01000000) == 0b01000000;
}

=head2 track

Get track location of first sector of file:

  my $track = $item->track();

Set track location of first sector of file:

  $item->track($track);

=cut

sub track {
    my ($self, $track) = @_;

    if (defined $track) {
        unless ($self->_is_valid_data_type($track)) {
            die sprintf q{Invalid type (%s) of track location of first sector of file (single byte expected)}, $self->_dump($track);
        }
        unless ($self->_is_valid_number_value($track)) {
            die sprintf q{Invalid value (%s) of track location of first sector of file (single byte expected)}, $self->_dump($track);
        }
        $self->[$I_TRACK] = pack 'C', $track;
    }

    return unpack 'C', $self->[$I_TRACK];
}

=head2 sector

Get sector location of first sector of file:

  my $sector = $item->sector();

Set sector location of first sector of file:

  $item->sector($sector);

=cut

sub sector {
    my ($self, $sector) = @_;

    if (defined $sector) {
        unless ($self->_is_valid_data_type($sector)) {
            die sprintf q{Invalid type (%s) of sector location of first sector of file (single byte expected)}, $self->_dump($sector);
        }
        unless ($self->_is_valid_number_value($sector)) {
            die sprintf q{Invalid value (%s) of sector location of first sector of file (single byte expected)}, $self->_dump($sector);
        }
        $self->[$I_SECTOR] = pack 'C', $sector;
    }

    return unpack 'C', $self->[$I_SECTOR];
}

=head2 name

Get 16 character filename:

  my $name = $item->name();

Returned value is a CBM ASCII string. Unless specified otherwise, it will be padded with C<$A0>.

Get filename (without C<$A0> padding):

  my $name = $item->name(padding_with_a0 => 0);

C<padding_with_a0> input parameter defaults to C<1>. That means every time filename is fetched from a C<D64::Disk::Dir::Item> object, length of a retrieved string will be 16 characters.

Set 16 character filename:

  $item->name($name);

Input name parameter is expected to be CBM ASCII string. Unless specified otherwise, it will be padded with C<$A0>.

Set 16 character filename (without C<$A0> padding):

  $item->name($name, padding_with_a0 => 0);

C<padding_with_a0> input parameter defaults to C<1>. That means every time filename is written into a C<D64::Disk::Dir::Item> object, it gets complemented with additional C<$A0> bytes up to the maximum length of a filename, which is 16 bytes. Thus by default 16 characters of filename data are always stored in a disk directory item.

In order to convert a PETSCII string to an ASCII string and vice versa, use the following subroutines provided by C<Text::Convert::PETSCII> module:

  use Text::Convert::PETSCII qw/:all/;

  my $ascii_name = petscii_to_ascii($petscii_name);
  my $petscii_name = ascii_to_petscii($ascii_name);

See L<Text::Convert::PETSCII> module description for more details on ASCII/PETSCII text conversion.

=cut

sub name {
    my ($self, @options) = @_;

    my $name;
    if (scalar (@options) % 2 == 1) {
        $name = shift @options;
    }
    my %options = @options;
    $options{padding_with_a0} = 1 if not exists $options{padding_with_a0};

    if (defined $name) {
        unless ($self->is_str($name)) {
            die sprintf q{Invalid type (%s) of filename (string value expected)}, $self->_dump($name);
        }
        if (length $name > 16) {
            die sprintf q{Too long (%s) filename (maximum 16 PETSCII characters allowed)}, $self->_dump($name);
        }
        unless ($self->is_valid_string_value($name)) {
            die sprintf q{Invalid string (%s) of filename (PETSCII string expected)}, $self->_dump($name);
        }
        if ($options{padding_with_a0}) {
            $self->[$I_NAME + $_] = chr 0xa0 for (0 .. 15);
        }
        for (my $i = 0; $i < length $name; $i++) {
            $self->[$I_NAME + $i] = substr $name, $i, 1;
        }
    }

    my $name_length = $I_NAME + 15;
    unless ($options{padding_with_a0}) {
        while (ord ($self->[$name_length]) == 0xa0 && $name_length >= $I_NAME) {
            $name_length--;
        }
    }
    $name = join '', @{$self}[$I_NAME..$name_length];

    return $name;
}

=head2 side_track

Get track location of first side-sector block:

  my $side_track = $item->side_track();

A track location of first side-sector block is returned for relative files only, an undefined value otherwise.

Set track location of first side-sector block:

  $item->side_track($side_track);

When attempting to assign track location of first side-sector block for a non-relative file, an exception will be thrown.

=cut

sub side_track {
    my ($self, $side_track) = @_;

    if (defined $side_track) {
        unless ($self->type() eq $T_REL) {
            die sprintf q{Illegal file type ('%s') encountered when attempting to set track location of first side-sector block ('rel' files only)}, $self->type_to_string($self->type());
        }
        unless ($self->_is_valid_data_type($side_track)) {
            die sprintf q{Invalid type (%s) of track location of first side-sector block of file (single byte expected)}, $self->_dump($side_track);
        }
        unless ($self->_is_valid_number_value($side_track)) {
            die sprintf q{Invalid value (%s) of track location of first side-sector block of file (single byte expected)}, $self->_dump($side_track);
        }
        $self->[$I_SIDE_TRACK] = pack 'C', $side_track;
    }

    return unless $self->type() eq $T_REL;

    return unpack 'C', $self->[$I_SIDE_TRACK];
}

=head2 side_sector

Get sector location of first side-sector block:

  my $side_sector = $item->side_sector();

A sector location of first side-sector block is returned for relative files only, an undefined value otherwise.

Set sector location of first side-sector block:

  $item->side_sector($side_sector);

When attempting to assign sector location of first side-sector block for a non-relative file, an exception will be thrown.

=cut

sub side_sector {
    my ($self, $side_sector) = @_;

    if (defined $side_sector) {
        unless ($self->type() eq $T_REL) {
            die sprintf q{Illegal file type ('%s') encountered when attempting to set sector location of first side-sector block ('rel' files only)}, $self->type_to_string($self->type());
        }
        unless ($self->_is_valid_data_type($side_sector)) {
            die sprintf q{Invalid type (%s) of sector location of first side-sector block of file (single byte expected)}, $self->_dump($side_sector);
        }
        unless ($self->_is_valid_number_value($side_sector)) {
            die sprintf q{Invalid value (%s) of sector location of first side-sector block of file (single byte expected)}, $self->_dump($side_sector);
        }
        $self->[$I_SIDE_SECTOR] = pack 'C', $side_sector;
    }

    return unless $self->type() eq $T_REL;

    return unpack 'C', $self->[$I_SIDE_SECTOR];
}

=head2 record_length

Get relative file record length:

  my $record_length = $item->record_length();

A relative file record length is returned for relative files only, an undefined value otherwise.

Get relative file record length (relative file only, maximum value 254):

  $item->record_length($record_length);

When attempting to assign relative file record length for a non-relative file or a record length greater than 254, an exception will be thrown.

=cut

sub record_length {
    my ($self, $record_length) = @_;

    if (defined $record_length) {
        unless ($self->type() eq $T_REL) {
            die sprintf q{Illegal file type ('%s') encountered when attempting to set record length ('rel' files only)}, $self->type_to_string($self->type());
        }
        unless ($self->_is_valid_data_type($record_length)) {
            die sprintf q{Invalid type (%s) of relative file record length (single byte expected)}, $self->_dump($record_length);
        }
        unless ($self->_is_valid_number_value($record_length)) {
            die sprintf q{Invalid value (%s) of relative file record length (single byte expected)}, $self->_dump($record_length);
        }
        unless ($record_length >= 0x00 && $record_length < 0xff) {
            die sprintf q{Invalid value (%s) of relative file record length (maximum allowed value 254)}, $self->_dump($record_length);
        }
        $self->[$I_RECORD_LENGTH] = pack 'C', $record_length;
    }

    return unless $self->type() eq $T_REL;

    return unpack 'C', $self->[$I_RECORD_LENGTH];
}

=head2 size

Get file size in sectors:

  my $size = $item->size();

The approximate file size in bytes is <= number_of_sectors * 254.

Set file size in sectors:

  $item->size($size);

=cut

sub size {
    my ($self, $size) = @_;

    if (defined $size) {
        unless ($self->_is_valid_data_type($size) && $self->is_int($size)) {
            die sprintf q{Invalid type (%s) of file size (integer value expected)}, $self->_dump($size);
        }
        unless ($size >= 0x0000 && $size <= 0xffff) {
            die sprintf q{Invalid value (%s) of file size (maximum allowed value %d)}, $self->_dump($size), 0xffff;
        }

        my $size_lo = $size % 0x0100;
        my $size_hi = int($size / 0x0100);

        $self->[$I_SIZE_LO] = pack 'C', $size_lo;
        $self->[$I_SIZE_HI] = pack 'C', $size_hi;
    }

    my $size_lo = unpack 'C', $self->[$I_SIZE_LO];
    my $size_hi = unpack 'C', $self->[$I_SIZE_HI];

    # Since a scalar value of a double type (NV) will always be loaded as the result
    # of multiplication in Perl 5.6.2, we need to force an integer value into an SV:
    return $self->set_iok($size_lo + 256 * $size_hi);
}

=head2 exact_size

Get exact file size in bytes:

  my $exact_size = $item->exact_size(disk_image => $disk_image_ref);

Warning! Do not use! This method has not been implemented (yet)!

=cut

sub exact_size {
    my ($self) = @_;

    # TODO: add another input parameter: required provision of a D64 disk image data...

    die q{Not yet implemented};
}

=head2 print

Print out formatted disk image directory item:

  $item->print(fh => $fh, as_petscii => $as_petscii);

C<fh> defaults to the standard output. C<as_petscii> defaults to false (meaning that ASCII characters will be printed out by default).

=cut

sub print {
    my ($self, %args) = @_;

    my $fh = $args{fh};
    my $as_petscii = $args{as_petscii};

    $fh ||= *STDOUT;
    $fh->binmode(':bytes');

    my $stdout = select $fh;

    if ($as_petscii) {
        my $type = $self->type_to_string($self->type(), 1);
        my $closed = $self->closed() ? 0x20 : 0x2a; # "*"
        my $locked = $self->locked() ? 0x3c : 0x20; # "<"
        my $size = ascii_to_petscii($self->size());
        my $name = sprintf "\"%s\"", $self->name(padding_with_a0 => 0);
        $name =~ s/\x00//g; # align file type string to the right column
        printf "%-4d %-18s%c%s%c\n", $size, $name, $closed, $type, $locked;
    }
    else {
        my $type = $self->type_to_string($self->type());
        my $closed = $self->closed() ? ord ' ' : ord '*';
        my $locked = $self->locked() ? ord '<' : ord ' ';
        my $size = $self->size();
        my $name = sprintf "\"%s\"", petscii_to_ascii($self->name(padding_with_a0 => 0));
        $name =~ s/\x00//g; # align file type string to the right column
        printf "%-4d %-18s%c%s%c\n", $size, $name, $closed, $type, $locked;
    }

    select $stdout;

    return;
}

=head2 validate

Validate item data against all possible errors:

  my $is_valid = $item->validate();

Returns true when all item data is valid, and false otherwise.

=cut

sub validate {
    my ($self) = @_;

    my $test = $self->new();

    my $is_valid = try {
        my $data = $self->data();
        die unless defined $data;
        $test->data($data);

        my $type = $self->type();
        die unless defined $type;
        $test->type($type);

        my $closed = $self->closed();
        die unless defined $closed;
        $test->closed($closed);

        my $locked = $self->locked();
        die unless defined $locked;
        $test->locked($locked);

        my $track = $self->track();
        die unless defined $track;
        $test->track($track);

        my $sector = $self->sector();
        die unless defined $sector;
        $test->sector($sector);

        my $name = $self->name();
        die unless defined $name;
        $test->name($name);

        if ($self->type() eq $T_REL) {

            my $side_track = $self->side_track();
            die unless defined $side_track;
            $test->side_track($side_track);

            my $side_sector = $self->side_sector();
            die unless defined $side_sector;
            $test->side_sector($side_sector);

            my $record_length = $self->record_length();
            die unless defined $record_length;
            $test->record_length($record_length);
        }

        my $size = $self->size();
        die unless defined $size;
        $test->size($size);

        1;
    }
    catch {
        0;
    };

    return $is_valid;
}

=head2 empty

Check if directory item contains information about the actual disk file:

  my $is_empty = $item->empty();

True value will be returned when directory item object is empty.

=cut

sub empty {
    my ($self) = @_;

    my $is_empty = not grep { ord ($_) != 0x00 } @{$self};

    return $is_empty;
}

=head2 writable

Check if slot occupied by this item in a disk directory is writable and can be replaced by any new file that would be written into disk:

  my $is_writable = $item->writable();

True value will be returned when directory item object is writable.

=cut

sub writable {
    my ($self) = @_;

    my $is_writable = !$self->closed() && $self->type() eq $T_DEL;

    return $is_writable;
}

=head2 clone

Clone disk directory item:

  my $clone = $item->clone();

=head2 match_name

Check if filename matches given CBM ASCII pattern:

  my $is_matched = $item->match_name($petscii_pattern);

C<$petscii_pattern> is expected to be a CBM ASCII string containing optional wildcard characters. The following wildcards are allowed/recognized:

=over

=item *
An asterisk C<*> character following any program name will yield successful match if filename is starting with that name.

=item *
A question mark C<?> character used as a wildcard will match any character in a filename.

=back

=cut

sub match_name {
    my ($self, $petscii_pattern) = @_;

    my $name = $self->name(padding_with_a0 => 0);

    my @name = split //, $name;
    my @pattern = split //, $petscii_pattern;

    for (my $i = 0; $i < @pattern; $i++) {
        my $match_pattern = ord $pattern[$i];
        if ($match_pattern == 0x2a) {
            return 1;
        }
        my $character = $name[$i];
        unless (defined $character && $match_pattern == 0x3f) {
            if (!defined $character || ord $character != $match_pattern) {
                return 0;
            }
        }
    }

    if (@name == @pattern) {
        return 1;
    }

    return 0;
}

=head2 type_to_string

Convert given file type into its three-letter printable ASCII/PETSCII string representation:

  my $string = D64::Disk::Dir::Item->type_to_string($type, $as_petscii);

C<as_petscii> defaults to false (meaning that ASCII characters will be returned by default).

=cut

sub type_to_string {
    my ($this, $type, $as_petscii) = @_;

    unless ($as_petscii) {
        my @mapping = (
            'del', # $T_DEL
            'seq', # $T_SEQ
            'prg', # $T_PRG
            'usr', # $T_USR
            'rel', # $T_REL
            'cbm', # $T_CBM
            'dir', # $T_DIR
        );

        if ($type >= 0 && $type < @mapping) {
            return $mapping[$type]
        }
        else {
            return '???';
        }
    }
    else {
        my @mapping = (
            '44454c', # $T_DEL
            '534551', # $T_SEQ
            '505247', # $T_PRG
            '555352', # $T_USR
            '52454c', # $T_REL
            '43424d', # $T_CBM
            '444952', # $T_DIR
        );

        if ($type >= 0 && $type < @mapping) {
            return pack 'H*', $mapping[$type];
        }
        else {
            return pack 'H*', '3f3f3f';
        }
    }
}

sub _dump {
    my ($self, $value) = @_;

    my $dump = Data::Dumper->new([$value])->Indent(0)->Terse(1)->Deepcopy(1)->Sortkeys(1)->Dump();

    return $dump;
}

sub is_int {
    my ($this, $var) = @_;

    return _is_int($var);
}

sub is_str {
    my ($this, $var) = @_;

    return _is_str($var);
}

sub magic_to_int {
    my ($this, $magic) = @_;

    return _magic_to_int($magic);
}

sub set_iok {
    my ($self, $var) = @_;

    my $var_iok = _set_iok($var);

    return $var_iok;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 CAVEATS

No GEOS-specific properties are supported by accessor methods of this module. Due to low popularity of GEOS system and rare amount of GEOS D64 disk images available on the net, I have decided to intentionally skip implementation of C<VLIR> file type format here. Thus all the information needed for the windowing system (icon, window position, creation time/date) cannot be right now accessed conveniently without the knowledge of specific C<VLIR> format details.

=head1 EXPORT

C<D64::Disk::Dir::Item> exports nothing by default.

You may request the import of file type constants (C<$T_DEL>, C<$T_SEQ>, C<$T_PRG>, C<$T_USR>, C<$T_REL>, C<$T_CBM>, and C<$T_DIR>) individually. All of these constants can be explicitly imported from C<D64::Disk::Dir::Item> by using it with the ":types" tag. All constants can be explicitly imported from C<D64::Disk::Dir::Item> by using it with the ":all" tag.

=head1 SEE ALSO

L<D64::Disk::Image>, L<D64::Disk::Layout>, L<Text::Convert::PETSCII>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.07 (2013-03-08)

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Pawel Krol <pawelkrol@cpan.org>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
