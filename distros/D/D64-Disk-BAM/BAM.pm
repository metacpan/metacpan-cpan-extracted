package D64::Disk::BAM;

=head1 NAME

D64::Disk::BAM - Processing the BAM (Block Availability Map) area of the Commodore disk images (D64 format only)

=head1 SYNOPSIS

  use D64::Disk::BAM;

  # Create new empty BAM object:
  my $diskBAM = D64::Disk::BAM->new();

  # Create new BAM object based on the BAM sector data retrieved from a D64 disk image file:
  my $diskBAM = D64::Disk::BAM->new($sector_data);

  # Get the BAM sector data:
  my $sector_data = $diskBAM->get_bam_data();

  # Clear the entire BAM sector data:
  $diskBAM->clear_bam();

  # Get disk name converted to an ASCII string:
  my $to_ascii = 1;
  my $disk_name = $diskBAM->disk_name($to_ascii);

  # Set disk name converted from an ASCII string:
  my $to_petscii = 1;
  $diskBAM->disk_name($to_petscii, $disk_name);

  # Get full disk ID converted to an ASCII string:
  my $to_ascii = 1;
  my $full_disk_id = $diskBAM->full_disk_id($to_ascii);

  # Set full disk ID converted from an ASCII string:
  my $to_petscii = 1;
  $diskBAM->full_disk_id($to_petscii, $full_disk_id);

  # Get the number of free sectors on the specified track:
  my $num_free_sectors = $diskBAM->num_free_sectors($track);

  # Check if the sector is used:
  my $is_sector_used = $diskBAM->sector_used($track, $sector);

  # Set specific sector to allocated:
  $diskBAM->sector_used($track, $sector, 1);

  # Check if the sector is free:
  my $is_sector_free = $diskBAM->sector_free($track, $sector);

  # Set specific sector to deallocated:
  $diskBAM->sector_free($track, $sector, 1);

  # Write BAM layout textual representation to a file handle:
  $diskBAM->print_out_bam_layout($fh);

  # Print out formatted disk header line to a file handle:
  $diskBAM->print_out_disk_header($fh);

  # Print out number of free blocks line to a file handle:
  $diskBAM->print_out_blocks_free($fh);

=head1 DESCRIPTION

Sector 0 of the directory track contains the BAM (Block Availability Map) and disk name/ID. This package provides the complete set of methods essential for accessing, managing and manipulating the contents of the BAM area of the Commodore disk images (note that only D64 format is supported).

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

our $VERSION = '0.04';

use Carp qw/carp croak/;
use Text::Convert::PETSCII qw/:convert/;

# Track containing the entire directory:
use constant DIRECTORY_FIRST_TRACK  => 0x00;
# First directory sector:
use constant DIRECTORY_FIRST_SECTOR => 0x01;
# Disk DOS version type:
use constant DISK_DOS_VERSION_TYPE  => 0x02;
# Disk Name (padded with $A0):
use constant DISK_NAME              => 0x90;
# Disk ID:
use constant DISK_ID                => 0xa2;
# Full Disk ID:
use constant FULL_DISK_ID           => 0xa2;
# DOS type, usually "2A":
use constant DOS_TYPE               => 0xa5;

# Number of sectors per track storage:
our @SECTORS_PER_TRACK = (
    21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, # tracks 1-17
    19, 19, 19, 19, 19, 19, 19,                                         # tracks 18-24
    18, 18, 18, 18, 18, 18,                                             # tracks 25-30
    17, 17, 17, 17, 17,                                                 # tracks 31-35
);

# BAM entries for each track (starting on track 1):
our @TRACK_BAM_ENTRIES = (
    0x04, 0x08, 0x0c, 0x10, 0x14, 0x18, 0x1c, 0x20, 0x24, 0x28, 0x2c, 0x30, 0x34, 0x38, 0x3c, 0x40, 0x44, # tracks 1-17
    0x48, 0x4c, 0x50, 0x54, 0x58, 0x5c, 0x60,                                                             # tracks 18-24
    0x64, 0x68, 0x6c, 0x70, 0x74, 0x78,                                                                   # tracks 25-30
    0x7c, 0x80, 0x84, 0x88, 0x8c,                                                                         # tracks 31-35
);

our @SECTOR_BAM_OFFSETS = (
    0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, 0x03, # sectors 0-7
    0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, 0x02, # sectors 8-15
    0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, # sectors 16-23
);

our @SECTOR_BAM_BITMASK = (
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, # sectors 0-7
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, # sectors 8-15
    0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, # sectors 16-23
);

=head2 new

Create new empty BAM object:

  my $diskBAM = D64::Disk::BAM->new();

Create new BAM object based on the BAM sector data:

  my $diskBAM = D64::Disk::BAM->new($sector_data);
  my $diskBAM = D64::Disk::BAM->new(@sector_data);

Upon failure an undefined value is returned.

Be careful providing the right sector input data. C<$sector_data> is expected to be the stream of bytes. C<@sector_data> is expected to be the list of single bytes (not the numeric byte values!).

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = [];
    bless $self, $class;
    my $initOK = $self->_initialize(@_);
    if ($initOK) {
        return $self;
    }
    else {
        return undef;
    }
}

sub _initialize {
    my $self = shift;
    my @sector_data = grep { defined } splice @_;
    my $sector_data;
    $self->_empty_bam();
    $sector_data .= $_ for @sector_data;
    if ($self->_setup_data($sector_data)) {
        return 1;
    }
    else {
        return 0;
    }
}

sub _setup_data {
    my $self = shift;
    my $sector_data = shift;
    if ($sector_data) {
        return 0 unless $self->_validate_bam_data($sector_data);
        for (my $i = 0; $i < length ($sector_data); $i++) {
            my $byte = substr $sector_data, $i, 1;
            $self->[$i] = ord $byte;
        }
    }
    return 1;
}

sub _validate_bam_data {
    my $self = shift;
    my $sector_data = shift;
    # Validate sector data, length is ok and all values correct!
    if (length ($sector_data) != 256) {
        carp sprintf q{Failed to validate the BAM sector data, expected the stream of 256 bytes but got %d bytes}, length ($sector_data);
        return 0;
    }
    for (my $track = 1; $track <= @TRACK_BAM_ENTRIES; $track++) {
        my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
        my $track_num_sectors = $SECTORS_PER_TRACK[$track - 1];
        # The first byte is the number of free sectors on that track:
        my $num_free_sectors = ord substr $sector_data, $track_bam_index, 1;
        if ($num_free_sectors > $track_num_sectors) {
            carp sprintf q{Failed to validate the BAM sector data, invalid number of free sectors reported on track %d: claims %d sectors free but track %d has only %d sectors}, $track, $num_free_sectors, $track, $track_num_sectors;
            return 0;
        }
        # The next three bytes represent the bitmap of which sectors are used/free:
        my $free_sectors_bitmap = unpack 'b*', (substr $sector_data, $track_bam_index + 1, 3);
        # Calculate the number of free sectors according to the bitmap allocation:
        my $free_sectors_count = scalar grep { $_ == 1 } split //, $free_sectors_bitmap;
        # The first byte that is the number of free sectors on that track and
        # the next three bytes representing the bitmap of which sectors are
        # used/free do not match, then this BAM sector data is invalid:
        if ($free_sectors_count != $num_free_sectors) {
            carp sprintf q{Failed to validate the BAM sector data, number of free sectors on track %d (which is claimed to be %d) does not match free sector allocation (which seems to be %d)}, $track, $num_free_sectors, $free_sectors_count;
            return 0;
        }
    }
    my $directory_first_track = ord substr $sector_data, DIRECTORY_FIRST_TRACK, 1;
    if ($directory_first_track != 0x12) {
        carp sprintf q{Warning! Track location of the first directory sector should be set to 18, but it is not: %d found in the BAM sector data}, $directory_first_track;
    }
    my $directory_first_sector = ord substr $sector_data, DIRECTORY_FIRST_SECTOR, 1;
    if ($directory_first_sector != 0x01) {
        carp sprintf q{Warning! Sector location of the first directory sector should be set to 1, but it is not: %d found in the BAM sector data}, $directory_first_sector;
    }
    my $section_filled_with_A0 = unpack 'h*', (substr $sector_data, 0xa0, 2);
    if ($section_filled_with_A0 ne '0a0a') {
        carp q{Warning! Bytes at offsets $A0-$A1 of the BAM sector data are expected to be filled with $A0, but they are not};
    }
    $section_filled_with_A0 = unpack 'h*', (substr $sector_data, 0xa7, 4);
    if ($section_filled_with_A0 ne '0a0a0a0a') {
        carp q{Warning! Bytes at offsets $A7-$AA of the BAM sector data are expected to be filled with $A0, but they are not};
    }
    return 1;
}

sub _empty_bam {
    my $self = shift;
    my $disk_name = shift;
    my $disk_id = shift;

    $self->[$_] = ord chr 0x00 for 0x00 .. 0xff;

    $self->[DIRECTORY_FIRST_TRACK]  = 0x12;
    $self->[DIRECTORY_FIRST_SECTOR] = 0x01;
    $self->[DISK_DOS_VERSION_TYPE]  = 0x41;

    for (my $track = 1; $track <= @TRACK_BAM_ENTRIES; $track++) {
        my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
        my $track_num_sectors = $SECTORS_PER_TRACK[$track - 1];
        # The first byte is the number of free sectors on that track:
        $self->[$track_bam_index] = $track_num_sectors;
        # The next three bytes represent the bitmap of which sectors are used/free:
        my @free_sectors = $self->_track_bam_free_sectors($track);
        @{$self}[$track_bam_index + 1 .. $track_bam_index + 3] = @free_sectors;
    }

    $self->[DISK_NAME + $_] = 0xa0 for 0x00 .. 0x0f;

    # A0-A1: Filled with $A0
    $self->[0xa0]  = 0xa0;
    $self->[0xa1]  = 0xa0;
    # A2-A3: Disk ID
    $self->[0xa2]  = 0xa0;
    $self->[0xa3]  = 0xa0;
    # A4: Usually $A0
    $self->[0xa4]  = 0xa0;
    # A5-A6: DOS type, usually "2A"
    $self->[0xa5]  = ord ascii_to_petscii '2';
    $self->[0xa6]  = ord ascii_to_petscii 'a';
    # A7-AA: Filled with $A0
    $self->[0xa7]  = 0xa0;
    $self->[0xa8]  = 0xa0;
    $self->[0xa9]  = 0xa0;
    $self->[0xaa]  = 0xa0;
}

sub _track_bam_free_sectors {
    my $self = shift;
    my $track = shift;
    my $free_sectors = 0;
    # Get number of sectors per track storage:
    my $num_sectors = $SECTORS_PER_TRACK[$track - 1];
    while ($num_sectors-- > 0) {
        $free_sectors <<= 1;
        $free_sectors |= 1;
    }
    $free_sectors = sprintf q{%06x}, $free_sectors;
    my @free_sectors = $free_sectors =~ m/(..)/g;
    return map { hex } @free_sectors;
}

=head2 clear_bam

Clear the entire BAM sector data:

  $diskBAM->clear_bam();

=cut

sub clear_bam {
    my $self = shift;
    $self->_empty_bam();
}

=head2 directory_first_track

Get/set track location of the first directory sector (in theory it should be always set to 18, but it actually doesn't matter, and you should never trust what is here, you always use track/sector 18/1 for the first directory entry):

  $diskBAM->directory_first_track($directory_first_track);
  my $directory_first_track = $diskBAM->directory_first_track();

=cut

sub directory_first_track {
    my $self = shift;
    my $directory_first_track = shift;
    if (defined $directory_first_track) {
        $self->[DIRECTORY_FIRST_TRACK] = $directory_first_track;
    }
    return $self->[DIRECTORY_FIRST_TRACK];
}

=head2 directory_first_sector

Get/set sector location of the first directory sector (in theory it should be always set to 1, but it actually doesn't matter, and you should never trust what is here, you always use track/sector 18/1 for the first directory entry):

  $diskBAM->directory_first_sector($directory_first_sector);
  my $directory_first_sector = $diskBAM->directory_first_sector();

=cut

sub directory_first_sector {
    my $self = shift;
    my $directory_first_sector = shift;
    if (defined $directory_first_sector) {
        $self->[DIRECTORY_FIRST_SECTOR] = $directory_first_sector;
    }
    return $self->[DIRECTORY_FIRST_SECTOR];
}

=head2 dos_version_type

Get/set disk DOS version type:

  $diskBAM->dos_version_type($dos_version_type);
  my $dos_version_type = $diskBAM->dos_version_type();

When this byte is set to anything else than $41 or $00, we have what is called "soft write protection", thus any attempt to write to the disk will return the "DOS Version" error code 73, "CBM DOS V2.6 1541".

=cut

sub dos_version_type {
    my $self = shift;
    my $directory_first_sector = shift;
    if (defined $directory_first_sector) {
        $self->[DISK_DOS_VERSION_TYPE] = $directory_first_sector;
    }
    return $self->[DISK_DOS_VERSION_TYPE];
}

=head2 get_bam_data

Get the BAM sector data:

  my $sector_data = $diskBAM->get_bam_data();
  my @sector_data = $diskBAM->get_bam_data();

Depending on the context, either a reference or an array of bytes is returned.

=cut

sub get_bam_data {
    my $self = shift;
    if (wantarray) {
        return @{$self};
    }
    else {
        my $sector_data = q{};
        $sector_data .= chr $_ for @{$self};
        return $sector_data;
    }
}

=head2 disk_name

Get disk name:

  my $disk_name = $diskBAM->disk_name($to_ascii);

The first input parameter indicates whether value returned should get converted to an ASCII string upon retrieval:

=over

=item *
A false value defaults to the original 16-bytes long PETSCII string padded with $A0

=item *
A true value enforces conversion of the original data to an ASCII string

=back

Set disk name:

  $diskBAM->disk_name($to_petscii, $disk_name);

The first input parameter indicates whether C<$disk_name> parameter should get converted to a PETSCII string before storing:

=over

=item *
A false value indicates that C<$disk_name> has already been converted to a 16-bytes long PETSCII string and padded with $A0

=item *
A true value enforces conversion of the original data to a valid PETSCII string

=back

Make sure that you either provide a valid PETSCII stream of bytes or use this option to get your original ASCII string properly converted.

The second input parameter provides the actual disk name to be written to the BAM sector data.

=cut

sub disk_name {
    my $self = shift;
    my $convert = shift;
    my $disk_name = shift;
    if (defined $disk_name) {
        $self->_set_text_data(q{Disk name}, $disk_name, 16, $convert);
    }
    my $retrieved_disk_name = join '', map { chr } @{$self}[DISK_NAME .. DISK_NAME + 15];
    # Remove padded $A0 bytes at the end of a PETSCII string:
    substr ($retrieved_disk_name, -1) = q{} while $retrieved_disk_name =~ m/\xa0$/;
    if ((not defined $disk_name and $convert) or (defined $disk_name and not $convert)) {
        $retrieved_disk_name = petscii_to_ascii($retrieved_disk_name);
    }
    return $retrieved_disk_name;
}

=head2 disk_id

Get disk ID:

  my $disk_id = $diskBAM->disk_id($to_ascii);

The first input parameter indicates whether value returned should get converted to an ASCII string upon retrieval:

=over

=item *
A false value defaults to the original 2-bytes long PETSCII string padded with $A0

=item *
A true value enforces conversion of the original data to an ASCII string

=back

Set disk ID:

  $diskBAM->disk_id($to_petscii, $disk_id);

The first input parameter indicates whether C<$disk_id> parameter should get converted to a PETSCII string before storing:

=over

=item *
A false value indicates that C<$disk_id> has already been converted to a 2-bytes long PETSCII string and padded with $A0

=item *
A true value enforces conversion of the original data to a valid PETSCII string

=back

Make sure that you either provide a valid PETSCII stream of bytes or use this option to get your original ASCII string properly converted.

The second input parameter provides the actual disk ID to be written to the BAM sector data.

=cut

sub disk_id {
    my $self = shift;
    my $convert = shift;
    my $disk_id = shift;
    if (defined $disk_id) {
        $self->_set_text_data(q{Disk ID}, $disk_id, 2, $convert);
    }
    my $retrieved_disk_id = join '', map { chr } @{$self}[DISK_ID .. DISK_ID + 1];
    # Remove padded $A0 bytes at the end of a PETSCII string:
    substr ($retrieved_disk_id, -1) = q{} while $retrieved_disk_id =~ m/\xa0$/;
    if ((not defined $disk_id and $convert) or (defined $disk_id and not $convert)) {
        $retrieved_disk_id = petscii_to_ascii($retrieved_disk_id);
    }
    return $retrieved_disk_id;
}

=head2 full_disk_id

Get full disk ID:

  my $full_disk_id = $diskBAM->full_disk_id($to_ascii);

The first input parameter indicates whether value returned should get converted to an ASCII string upon retrieval:

=over

=item *
A false value defaults to the original 5-bytes long PETSCII string padded with $A0

=item *
A true value enforces conversion of the original data to an ASCII string

=back

Set full disk ID:

  $diskBAM->full_disk_id($to_petscii, $full_disk_id);

The first input parameter indicates whether C<$full_disk_id> parameter should get converted to a PETSCII string before storing:

=over

=item *
A false value indicates that C<$full_disk_id> has already been converted to a 5-bytes long PETSCII string and padded with $A0

=item *
A true value enforces conversion of the original data to a valid PETSCII string

=back

Make sure that you either provide a valid PETSCII stream of bytes or use this option to get your original ASCII string properly converted.

The second input parameter provides the actual full disk ID to be written to the BAM sector data.

=cut

sub full_disk_id {
    my $self = shift;
    my $convert = shift;
    my $full_disk_id = shift;
    if (defined $full_disk_id) {
        $self->_set_text_data(q{Full disk ID}, $full_disk_id, 5, $convert);
    }
    my $retrieved_full_disk_id = join '', map { chr } @{$self}[FULL_DISK_ID .. FULL_DISK_ID + 4];
    # Remove padded $A0 bytes at the end of a PETSCII string:
    substr ($retrieved_full_disk_id, -1) = q{} while $retrieved_full_disk_id =~ m/\xa0$/;
    if ((not defined $full_disk_id and $convert) or (defined $full_disk_id and not $convert)) {
        $retrieved_full_disk_id =~ s/\xa0/\x20/g;
        $retrieved_full_disk_id = petscii_to_ascii($retrieved_full_disk_id);
    }
    return $retrieved_full_disk_id;
}

=head2 dos_type

Get DOS type:

  my $dos_type = $diskBAM->dos_type($to_ascii);

The first input parameter indicates whether value returned should get converted to an ASCII string upon retrieval:

=over

=item *
A false value defaults to the original 2-bytes long PETSCII string padded with $A0

=item *
A true value enforces conversion of the original data to an ASCII string

=back

Set DOS type:

  $diskBAM->dos_type($to_petscii, $dos_type);

The first input parameter indicates whether C<$dos_type> parameter should get converted to a PETSCII string before storing:

=over

=item *
A false value indicates that C<$dos_type> has already been converted to a 2-bytes long PETSCII string and padded with $A0

=item *
A true value enforces conversion of the original data to a valid PETSCII string

=back

Make sure that you either provide a valid PETSCII stream of bytes or use this option to get your original ASCII string properly converted.

The second input parameter provides the actual DOS type to be written to the BAM sector data.

=cut

sub dos_type {
    my $self = shift;
    my $convert = shift;
    my $dos_type = shift;
    if (defined $dos_type) {
        $self->_set_text_data(q{DOS type}, $dos_type, 2, $convert);
    }
    my $retrieved_dos_type = join '', map { chr } @{$self}[DOS_TYPE .. DOS_TYPE + 1];
    # Remove padded $A0 bytes at the end of a PETSCII string:
    substr ($retrieved_dos_type, -1) = q{} while $retrieved_dos_type =~ m/\xa0$/;
    if ((not defined $dos_type and $convert) or (defined $dos_type and not $convert)) {
        $retrieved_dos_type = petscii_to_ascii($retrieved_dos_type);
    }
    return $retrieved_dos_type;
}

sub _set_text_data {
    my $self = shift;
    my $var_name = shift;
    my $text_data = shift;
    my $max_length = shift;
    my $convert = shift;

    my $var_bam_indexes = {
        q{Disk name}    => DISK_NAME,
        q{Disk ID}      => DISK_ID,
        q{Full disk ID} => FULL_DISK_ID,
        q{DOS type}     => DOS_TYPE,
    };
    my $var_bam_index = $var_bam_indexes->{$var_name};

    if ($convert) {
        # Warn if original ASCII string is longer than $max_length characters:
        if (length ($text_data) > $max_length) {
            carp sprintf q{%s to be set contains %d bytes: "%s" (note that only first %d bytes will be used)}, $var_name, length ($text_data), $text_data, $max_length;
            substr ($text_data, $max_length) = q{};
        }
        # Convert an ASCII string to a PETSCII string:
        $text_data = ascii_to_petscii($text_data);
        # Pad with $A0 when necessary:
        $text_data .= chr 0xa0 while length ($text_data) < $max_length;
    }
    else {
        # Warn if original PETSCII string is longer than $max_length characters:
        if (length ($text_data) > $max_length) {
            carp sprintf q{%s to be set contains %d bytes: "%s" (note that only first %d bytes will be used)}, $var_name, length ($text_data), petscii_to_ascii ($text_data), $max_length;
            substr ($text_data, $max_length) = q{};
        }
        # Warn if original PETSCII string is shorter than $max_length characters:
        if (length ($text_data) < $max_length) {
            carp sprintf q{%s to be set contains %d bytes: "%s" (note that it will be padded with $A0 bytes to get full %d bytes string)}, $var_name, length ($text_data), petscii_to_ascii ($text_data), $max_length;
            # Pad with $A0 when necessary:
            $text_data .= chr 0xa0 while length ($text_data) < $max_length;
        }
    }
    splice @{$self}, $var_bam_index, $max_length, map { ord } split //, $text_data;
}

=head2 num_free_sectors

Get the number of free sectors on an entire disk:

  my $num_free_sectors = $diskBAM->num_free_sectors('all');

Get the number of free sectors on the specified track:

  my $num_free_sectors = $diskBAM->num_free_sectors($track);

When successful the number of free sectors on that track will be returned.

Returns an undefined value if invalid track number has been provided.

=cut

sub num_free_sectors {
    my $self = shift;
    my $track = shift;
    if (defined $track && $track eq 'all') {
        my $directory_first_track = $self->directory_first_track();
        my $num_free_sectors = 0;
        for my $track (1 .. scalar @SECTORS_PER_TRACK) {
            next if $track == $directory_first_track; # skip directory track
            $num_free_sectors += $self->num_free_sectors($track);
        }
        return $num_free_sectors;
    }
    unless ($self->_validate_track_number($track)) {
        carp sprintf qq{Unable to get the number of free sectors on that track};
        return undef;
    }
    my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
    # The first byte of track BAM is the number of free sectors on that track:
    my $num_free_sectors = $self->[$track_bam_index];
    return $num_free_sectors;
}

sub _increase_num_free_sectors {
    my $self = shift;
    my $track = shift;
    my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
    # The first byte of track BAM is the number of free sectors on that track:
    my $num_free_sectors = $self->[$track_bam_index];
    # Get number of sectors per track storage:
    my $max_sector = $SECTORS_PER_TRACK[$track - 1];
    if ($num_free_sectors >= $max_sector) {
        croak sprintf qq{Internal error! Unable to increase the number of free sectors on track %s to %d, because it consists of %d sectors only}, $track, $num_free_sectors + 1, $max_sector;
    }
    $self->[$track_bam_index] = ++$num_free_sectors;
}

sub _decrease_num_free_sectors {
    my $self = shift;
    my $track = shift;
    my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
    # The first byte of track BAM is the number of free sectors on that track:
    my $num_free_sectors = $self->[$track_bam_index];
    if ($num_free_sectors <= 0) {
        croak sprintf qq{Internal error! Unable to decrease the number of free sectors on track %s to %d, because it already contains %d free sectors}, $track, $num_free_sectors + 1;
    }
    $self->[$track_bam_index] = --$num_free_sectors;
}

sub _validate_track_number {
    my $self = shift;
    my $track = shift;
    if ($track < 1 or $track > 35) {
        carp sprintf qq{Invalid track number specified: %d}, $track;
        return 0;
    }
    else {
        return 1;
    }
}

=head2 sector_used

Check if the sector is used:

  my $is_sector_used = $diskBAM->sector_used($track, $sector);

True value indicates that the sector is used, false value states that the sector is free.

Set specific sector to allocated:

  $diskBAM->sector_used($track, $sector, 1);

Remove allocation from sector:

  $diskBAM->sector_used($track, $sector, 0);

=cut

sub sector_used {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my $is_used = shift;

    unless ($self->_validate_sector_number($track, $sector)) {
        carp sprintf qq{Unable to get sector allocation};
        return undef;
    }

    my $track_bam_index = $TRACK_BAM_ENTRIES[$track - 1];
    my $sector_bam_offset = $SECTOR_BAM_OFFSETS[$sector];
    my $sector_bam_bitmask = $SECTOR_BAM_BITMASK[$sector];

    if (defined $is_used) {
        my $sector_bam_bitmap = $self->[$track_bam_index + $sector_bam_offset];
        my $was_sector_used_before = not ($sector_bam_bitmap & $sector_bam_bitmask);
        if ($is_used) {
            # Warn on repeated sector allocation:
            if ($was_sector_used_before) {
                carp sprintf qq{Warning! Allocating sector %d on track %d, which is already in use}, $sector, $track;
            }
            # Decrease the number of free sectors:
            else {
                $self->_decrease_num_free_sectors($track);
            }
            # Set specific sector to allocated:
            $self->[$track_bam_index + $sector_bam_offset] &= ($sector_bam_bitmask ^ 0xff);
        }
        else {
            # Warn on repeated sector deallocation:
            unless ($was_sector_used_before) {
                carp sprintf qq{Warning! Deallocating sector %d on track %d, which has been free before}, $sector, $track;
            }
            # Increase the number of free sectors:
            else {
                $self->_increase_num_free_sectors($track);
            }
            # Remove allocation from sector:
            $self->[$track_bam_index + $sector_bam_offset] |= $sector_bam_bitmask;
        }
    }

    my $sector_bam_bitmap = $self->[$track_bam_index + $sector_bam_offset];

    if ($sector_bam_bitmap & $sector_bam_bitmask) {
        return 0;
    }
    else {
        return 1;
    }
}

=head2 sector_free

Check if the sector is free:

  my $is_sector_free = $diskBAM->sector_free($track, $sector);

True value indicates that the sector is free, false value states that the sector is used.

Set specific sector to deallocated:

  $diskBAM->sector_free($track, $sector, 1);

Remove sector from the list of empty sectors:

  $diskBAM->sector_free($track, $sector, 0);

=cut

sub sector_free {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my $is_free = shift;

    my $is_used = not $is_free if defined $is_free;

    my $is_sector_used = $self->sector_used($track, $sector, $is_used);

    if ($is_sector_used) {
        return 0;
    }
    else {
        return 1;
    }
}

sub _validate_sector_number {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    unless ($self->_validate_track_number($track)) {
        return 0;
    }
    else {
        # Get number of sectors per track storage:
        my $max_sector = $SECTORS_PER_TRACK[$track - 1];
        if ($sector < 0 or $sector > $max_sector - 1) {
            carp sprintf qq{Invalid sector number specified: %d}, $sector;
            return 0;
        }
        else {
            return 1;
        }
    }
}

=head2 print_out_bam_layout

Write BAM layout textual representation to a file handle:

  $diskBAM->print_out_bam_layout($fh);

C<$fh> is expected to be an opened file handle that BAM layout's textual representation may be written to.

=cut

sub print_out_bam_layout {
    my $self = shift;
    my $fh = shift;
    print q{    };
    for (my $col = 0x00; $col < 0x10; $col++) {
        printf q{%02X }, $col;
    }
    print qq{\n} . q{    } . '-' x 47 . qq{\n};
    for (my $row = 0x00; $row < 0x100; $row += 0x10) {
        printf q{%02X: }, $row;
        for (my $col = 0x00; $col < 0x10; $col++) {
            my $val = $self->[$row + $col];
            printf q{%02X }, $val;
        }
        for (my $col = 0x00; $col < 0x10; $col++) {
            my $val = $self->[$row + $col];
            if ($val >= 0x20 and $val <= 0x7f) {
                $val = ord petscii_to_ascii chr $val;
            }
            else {
                $val = ord '?';
            }
            printf q{%c}, $val;
        }
        printf qq{\n};
    }
}

=head2 print_out_disk_header

Print out formatted disk header line to a file handle:

  $diskBAM->print_out_disk_header($fh, $as_petscii);

C<fh> defaults to the standard output. C<as_petscii> defaults to false (meaning that ASCII characters will be printed out by default).

=cut

sub print_out_disk_header {
    my ($self, $fh, $as_petscii) = @_;

    $fh ||= *STDOUT;
    $fh->binmode(':bytes');

    my $stdout = select $fh;

    if ($as_petscii) {
        # Get disk name as a PETSCII string:
        my $disk_name = $self->disk_name(0);
        $disk_name .= chr 0x20 while length $disk_name < 16;
        $disk_name =~ s/\xa0/\x20/g;
        # Get full disk ID as a PETSCII string:
        my $full_disk_id = $self->full_disk_id(0);
        $full_disk_id =~ s/\xa0/\x20/g;
        # Setup an empty default disk header:
        my @disk_header;
        # Populate disk header with bytes:
        push @disk_header, chr 0x30; # 0
        push @disk_header, chr 0x20; # _
        push @disk_header, chr 0x12; # RVS ON
        push @disk_header, chr 0x22; # "
        push @disk_header, split //, $disk_name;
        push @disk_header, chr 0x22; # "
        push @disk_header, chr 0x20; # _
        push @disk_header, split //, $full_disk_id;
        push @disk_header, chr 0x92; # RVS OFF
        # Print out disk name and full disk ID:
        print @disk_header;
    }
    else {
        # Get disk name converted to an ASCII string:
        my $disk_name = $self->disk_name(1);
        # Get full disk ID converted to an ASCII string:
        my $full_disk_id = $self->full_disk_id(1);
        # Print out disk name and full disk ID:
        printf q{0 "%-16s" %s}, $disk_name, $full_disk_id;
    }

    select $stdout;

    return;
}

=head2 print_out_blocks_free

Print out number of free blocks line to a file handle:

  $diskBAM->print_out_blocks_free($fh, $as_petscii);

C<fh> defaults to the standard output. C<as_petscii> defaults to false (meaning that ASCII characters will be printed out by default).

=cut

sub print_out_blocks_free {
    my ($self, $fh, $as_petscii) = @_;

    $fh ||= *STDOUT;
    $fh->binmode(':bytes');

    my $stdout = select $fh;

    # Get number of free sectors on an entire disk:
    my $num_free_sectors = $self->num_free_sectors('all');
    my $blocks_free = sprintf q{%d blocks free.}, $num_free_sectors;

    # Print out number of free blocks:
    if ($as_petscii) {
        print petscii_to_ascii $blocks_free;
    }
    else {
        printf $blocks_free;
    }

    select $stdout;

    return;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 CAVEATS

There are some variations of the BAM layout, these are however not covered (yet!) by this module:

=over

=item *
DOLPHIN DOS 40-track extended format (track 36-40 BAM entries)

=item *
SPEED DOS 40-track extended format (track 36-40 BAM entries)

=back

The BAM entries for SPEED, DOLPHIN and ProLogic DOS use the same layout as standard BAM entries, hence should be relatively easy to get implemented. Extended versions of this package may appear or they might as well get supported through other modules by the means of inheritance.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.04 (2013-03-10)

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2013 by Pawel Krol <pawelkrol@cpan.org>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;
