package D64::Disk::Layout::Sector;

=head1 NAME

D64::Disk::Layout::Sector - An abstraction layer over physical sector data of various Commodore disk image formats

=head1 SYNOPSIS

  use D64::Disk::Layout::Sector;

  # Create a new disk sector object instance:
  my $object = D64::Disk::Layout::Sector->new(data => $data, track => $track, sector => $sector);
  my $object = D64::Disk::Layout::Sector->new(data => \@data, track => $track, sector => $sector);

  # Fetch sector data as a scalar of 256 bytes:
  my $data = $object->data();
  # Fetch sector data as an array of 256 bytes:
  my @data = $object->data();

  # Update sector providing 256 bytes of scalar data:
  $object->data($data);
  # Update sector given array with 256 bytes of data:
  $object->data(@data);
  $object->data(\@data);

  # Fetch the actual file contents from sector data as a scalar of allocated number of bytes:
  my $file_data = $object->file_data();
  # Fetch the actual file contents from sector data as an array of allocated number of bytes:
  my @file_data = $object->file_data();

  # Update the actual file contents providing number of scalar data bytes to allocate:
  $object->file_data($file_data);
  # Update the actual file contents given array with number of bytes of data to allocate:
  $object->file_data(@file_data);
  $object->file_data(\@file_data);

  # Get/set track location of the object data in the actual disk image:
  my $track = $object->track();
  $object->track($track);

  # Get/set sector location of the object data in the actual disk image:
  my $sector = $object->sector();
  $object->sector($sector);

  # Check if first two bytes of data point to the next chunk of data in a chain:
  my $is_valid_ts_link = $object->is_valid_ts_link();

  # Get/set track and sector link values to the next chunk of data in a chain:
  my ($track, $sector) = $object->ts_link();
  $object->ts_link($track, $sector);

  # Check if first two bytes of data indicate index of the last allocated byte:
  my $is_last_in_chain = $object->is_last_in_chain();

  # Get/set index of the last allocated byte within the sector data:
  my $alloc_size = $object->alloc_size();
  $object->alloc_size($alloc_size);

  # Check if sector object is empty:
  my $is_empty = $object->empty();

  # Set/clear boolean flag marking sector object as empty:
  $object->empty($empty);

  # Wipe out an entire sector data, and mark it as empty:
  $object->clean();

  # Print out formatted disk sector data:
  $object->print();

=head1 DESCRIPTION

C<D64::Disk::Layout::Sector> provides a helper class for C<D64::Disk::Layout> module and defines an abstraction layer over physical sector data of various Commodore disk image formats, enabling users to access and modify disk sector data in an object oriented way without the hassle of worrying about the meaning of individual bits and bytes, describing their function in a disk image layout. The whole family of C<D64::Disk::Layout> modules has been implemented in pure Perl as an alternative to Per Olofsson's "diskimage.c" library originally written in an ANSI C.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.02';

use Data::Dumper;
use Readonly;
use Storable qw(dclone);
use Text::Convert::PETSCII qw/:convert/;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

# Data offset constants:
Readonly our $I_TS_POINTER_TRACK  => 0x00;
Readonly our $I_TS_POINTER_SECTOR => 0x01;
Readonly our $I_ALLOC_SIZE        => 0x01;
Readonly our $I_SECTOR_DATA       => 0x02;

Readonly our $SECTOR_DATA_SIZE    => 0x0100;

=head2 new

Create an instance of a C<D64::Disk::Layout::Sector> class as an empty disk sector:

  my $object = D64::Disk::Layout::Sector->new();

Create an instance of a C<D64::Disk::Layout::Sector> class providing 256 bytes of data retrieved from a disk image:

  my $object = D64::Disk::Layout::Sector->new(data => $data, track => $track, sector => $sector);
  my $object = D64::Disk::Layout::Sector->new(data => \@data, track => $track, sector => $sector);

C<$track> and C<$sector> values are expected to be single bytes, an exception will be thrown when non-byte or non-numeric or non-scalar value is provided (please note that a default value of C<undef> is internally translated into the value of C<0x00>). For more information about C<$data> and C<@data> validation, see the C<data> section below.

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref ($this) || $this;
    my $object = $class->_init();
    my $self = bless $object, $class;

    if (%args) {
        unless (defined $args{data}) {
            die sprintf q{Unable to initialize sector data: undefined value of data (%d bytes expected)}, $SECTOR_DATA_SIZE;
        }
        unless (defined $args{track}) {
            die q{Unable to initialize track property: undefined value of track (numeric value expected)};
        }
        unless (defined $args{sector}) {
            die q{Unable to initialize sector property: undefined value of sector (numeric value expected)};
        }

        $self->data($args{data});
        $self->track($args{track});
        $self->sector($args{sector});
    }

    return $self;
}

sub _init {
    my ($this) = @_;
    my @data = map { chr 0x00 } (0x01 .. $SECTOR_DATA_SIZE);
    my %object = (
        data     => \@data,
        track    => 0,
        sector   => 0,
        is_empty => 1,
    );
    return \%object;
}

sub _object_property {
    my ($self, $name, $value) = @_;

    if (defined $value) {
        $self->{$name} = ref $value ? dclone $value : $value;
    }

    return $self->{$name};
}

sub _is_valid_byte_value {
    my ($self, $byte_value) = @_;

    if (defined $byte_value && length ($byte_value) == 1 && ord ($byte_value) >= 0x00 && ord ($byte_value) <= 0xff) {
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

=head2 data

Fetch sector data as a scalar of 256 bytes:

  my $data = $object->data();

Fetch sector data as an array of 256 bytes:

  my @data = $object->data();

Update sector providing 256 bytes of scalar data retrieved from a disk image:

  $object->data($data);

C<$data> value is expected to be a scalar of 256 bytes in length, an exception will be thrown when non-scalar value or a scalar which does not have a length of 256 bytes or a scalar which contains wide non-byte character is provided.

Update sector given array with 256 bytes of data retrieved from a disk image:

  $object->data(@data);
  $object->data(\@data);

C<@data> value is expected to be an array of 256 bytes in size, an exception will be thrown when non-array or an array with any other number of elements or an array with non-scalar byte values is provided.

=cut

sub data {
    my ($self, @args) = @_;

    my $data = $self->_validate_data(args => \@args, min_size => $SECTOR_DATA_SIZE, max_size => $SECTOR_DATA_SIZE, what => 'sector');

    if (defined $data) {
        $self->_object_property('data', $data);

        # When data is set, object is no longer empty (unless it's filled with zeroes)
        my $is_valid_ts_link = $self->is_valid_ts_link();
        my $alloc_size = $self->alloc_size();
        unless ($is_valid_ts_link || $alloc_size != 0) {
            $self->empty(1);
        }
        else {
            $self->empty(0);
        }
    }

    return unless defined wantarray;

    $data = $self->_object_property('data');

    return wantarray ? @{$data} : join '', @{$data};
}

sub _validate_data {
    my ($self, %args) = @_;

    my @args = @{$args{args}};

    return unless scalar @args > 0;

    # Convert arrayref parameter to an array:
    if (scalar @args == 1) {
        my ($arg) = @args;
        if (ref $arg eq 'ARRAY') {
            @args = @{$arg};
        }
    }

    my $what = $args{what};
    my $min_size = $args{min_size};
    my $max_size = $args{max_size};

    # Convert scalar parameter to an array:
    if (scalar @args == 1) {
        my ($arg) = @args;
        unless (ref $arg) {
            no bytes;
            if (length ($arg) < $min_size || length ($arg) > $max_size) {
                die sprintf q{Unable to set %s data: Invalid length of data}, $what;
            }
            @args = split //, $arg;
        }
        else {
            die sprintf q{Unable to set %s data: Invalid arguments given}, $what;
        }
    }

    unless (scalar (@args) < $min_size || scalar (@args) > $max_size) {
        for (my $i = 0; $i < @args; $i++) {
            my $byte_value = $args[$i];
            if (ref $byte_value) {
                die sprintf q{Unable to set %s data: Invalid data type at offset %d (%s)}, $what, $i, ref $args[$i];
            }
            unless ($self->_is_valid_byte_value($byte_value)) {
                die sprintf q{Unable to set %s data: Invalid byte value at offset %d (%s)}, $what, $i, $self->_dump($byte_value);
            }
        }
    }
    else {
        die sprintf q{Unable to set %s data: Invalid amount of data}, $what;
    }

    my @data = @args;

    return \@data;
}

=head2 file_data

Fetch the actual file contents from sector data as a scalar of allocated number of bytes:

  my $file_data = $object->file_data();

Fetch the actual file contents from sector data as an array of allocated number of bytes:

  my @file_data = $object->file_data();

Update the actual file contents providing number of scalar data bytes to allocate:

  $object->file_data($file_data, set_alloc_size => $set_alloc_size);

C<$file_data> value is expected to be a scalar of between 0 and 254 bytes in length, an exception will be thrown when non-scalar value or a scalar which does not have a length between 0 and 254 bytes or a scalar which contains wide non-byte character is provided. C<$set_alloc_size> input parameter defaults to C<0>. That means every file data assignment modifies only certain data bytes. This may or may not be a desired behaviour. If C<$file_data> contains 254 bytes of data, it is likely that the first two bytes of sector data should still point to the next chunk of data in a chain and thus remain unchanged. If C<$set_alloc_size> flag is set, this operation will additionally mark sector object as the last sector in chain and calculate the last allocated byte within sector data based on the number of bytes provided in C<$file_data> value. This value will then be assigned to the C<alloc_size> object property.

Update the actual file contents given array with number of bytes of data to allocate:

  $object->file_data(\@file_data, set_alloc_size => $set_alloc_size);

C<@file_data> value is expected to be an array of between 0 and 254 bytes in size, an exception will be thrown when non-array or an array with any other number of elements not in between 0 and 254 or an array with non-scalar byte values is provided. C<$set_alloc_size> input parameter defaults to C<0>. The same remarks apply here as the ones desribed in a paragraph above.

=cut

sub file_data {
    my ($self, $data, %args) = @_;

    $args{set_alloc_size} = 0 if not exists $args{set_alloc_size};

    my $file_data = $self->_validate_data(args => [$data], min_size => 0, max_size => 254, what => 'file') if defined $data;

    if (defined $file_data) {
        my $file_data_size = scalar @{$file_data};

        my $data = $self->_object_property('data');
        splice @{$data}, $I_SECTOR_DATA, $file_data_size, @{$file_data};

        if ($args{set_alloc_size}) {
            $data->[$I_TS_POINTER_TRACK] = chr 0x00;
            $data->[$I_ALLOC_SIZE] = chr ($file_data_size + ($file_data_size > 0x00 ? 0x01 : 0x00));
        }

        $self->_object_property('data', $data);

        # When data is set, object is no longer empty (unless it's filled with zeroes)
        my $is_valid_ts_link = $self->is_valid_ts_link();
        my $alloc_size = $self->alloc_size();
        unless ($is_valid_ts_link || $alloc_size != 0) {
            $self->empty(1);
        }
        else {
            $self->empty(0);
        }
    }

    return unless defined wantarray;

    $data = $self->_object_property('data');

    my @file_data = @{$data};
    my $alloc_size = $self->alloc_size();

    splice @file_data, $alloc_size + 1;
    splice @file_data, 0, $I_SECTOR_DATA;

    return wantarray ? @file_data : join '', @file_data;
}

=head2 track

Get track location of sector data in the actual disk image:

  my $track = $object->track();

Set track location of sector data in the actual disk image:

  $object->track($track);

C<$track> value is expected to be a single byte, an exception will be thrown when non-byte or non-numeric or non-scalar value is provided.

=cut

sub track {
    my ($self, $track) = @_;

    if (defined $track) {
        if (ref $track) {
            die sprintf q{Invalid type (%s) of track location of sector data (single byte expected)}, $self->_dump($track);
        }
        unless ($self->_is_valid_number_value($track)) {
            die sprintf q{Invalid value (%s) of track location of sector data (single byte expected)}, $self->_dump($track);
        }
        if ($track == 0x00) {
            die sprintf q{Illegal value (0) of track location of sector data (track 0 does not exist)};
        }
        $track = $self->_object_property('track', $track);
    }

    $track = $self->_object_property('track');

    return $track;
}

=head2 sector

Get sector location of sector data in the actual disk image:

  my $sector = $object->sector();

Set sector location of sector data in the actual disk image:

  $object->sector($sector);

C<$sector> value is expected to be a single byte, an exception will be thrown when non-byte or non-numeric or non-scalar value is provided.

=cut

sub sector {
    my ($self, $sector) = @_;

    if (defined $sector) {
        if (ref $sector) {
            die sprintf q{Invalid type (%s) of sector location of sector data (single byte expected)}, $self->_dump($sector);
        }
        unless ($self->_is_valid_number_value($sector)) {
            die sprintf q{Invalid value (%s) of sector location of sector data (single byte expected)}, $self->_dump($sector);
        }
        $sector = $self->_object_property('sector', $sector);
    }

    $sector = $self->_object_property('sector');

    return $sector;
}

=head2 is_valid_ts_link

Check if first two bytes of data point to the next chunk of data in a chain:

  my $is_valid_ts_link = $object->is_valid_ts_link();

=cut

sub is_valid_ts_link {
    my ($self) = @_;

    my $data = $self->_object_property('data');

    my $ts_pointer_track = ord $data->[$I_TS_POINTER_TRACK];

    return $ts_pointer_track == 0x00 ? 0 : 1;
}

=head2 ts_link

Get track and sector link values to the next chunk of data in a chain:

  my ($track, $sector) = $object->ts_link();

Track and sector values will be returned if first two bytes of data point to the next chunk of data in a chain, indicating this sector is in a link chain. When two first bytes of data indicate an index of the last allocated byte, an undefined value will be returned. An undefined value indicates that this is the last sector in a chain (and C<alloc_size> can be used to fetch index of the last allocated byte within sector data).

Set track and sector link values to the next chunk of data in a chain:

  $object->ts_link($track, $sector);

Setting track/sector link includes sector in a chain and adds link to the next sector of data, at the same time allocating an entire sector for storing file data.

=cut

sub ts_link {
    my ($self, $track, $sector) = @_;

    my $data = $self->_object_property('data');

    if (defined $track || defined $sector) {
        unless (defined $track) {
            die sprintf q{Undefined value of track location for the next chunk of data in a chain (single byte expected)}, $self->_dump($track);
        }
        if (ref $track) {
            die sprintf q{Invalid type (%s) of track location for the next chunk of data in a chain (single byte expected)}, $self->_dump($track);
        }
        unless ($self->_is_valid_number_value($track)) {
            die sprintf q{Invalid value (%s) of track location for the next chunk of data in a chain (single byte expected)}, $self->_dump($track);
        }
        if ($track == 0x00) {
            die sprintf q{Illegal value (0) of track location for the next chunk of data in a chain (track 0 does not exist)};
        }

        unless (defined $sector) {
            die sprintf q{Undefined value of sector location for the next chunk of data in a chain (single byte expected)}, $self->_dump($sector);
        }
        if (ref $sector) {
            die sprintf q{Invalid type (%s) of sector location for the next chunk of data in a chain (single byte expected)}, $self->_dump($sector);
        }
        unless ($self->_is_valid_number_value($sector)) {
            die sprintf q{Invalid value (%s) of sector location for the next chunk of data in a chain (single byte expected)}, $self->_dump($sector);
        }

        $data->[$I_TS_POINTER_TRACK] = chr $track;
        $data->[$I_TS_POINTER_SECTOR] = chr $sector;

        # Once valid track and sector link values are set, sector can no longer be considered empty:
        $self->empty(0);
    }

    return unless $self->is_valid_ts_link();

    $track = ord $data->[$I_TS_POINTER_TRACK];
    $sector = ord $data->[$I_TS_POINTER_SECTOR];

    return ($track, $sector);
}

*ts_pointer = \&ts_link;

=head2 is_last_in_chain

Check if two first bytes of data indicate an index of the last allocated byte, meaning this is the last sector in a chain:

  my $is_last_in_chain = $object->is_last_in_chain();

Note that C<alloc_size> method will always correctly return index of the last allocated byte within the sector data (even if first two bytes of data contain track and sector link values to the next chunk of data in a chain).

=cut

sub is_last_in_chain {
    my ($self) = @_;

    my $data = $self->_object_property('data');

    my $ts_pointer_track = ord $data->[$I_TS_POINTER_TRACK];

    return $ts_pointer_track == 0x00 ? 1 : 0;
}

=head2 alloc_size

Get index of the last allocated byte within the sector data:

  my $alloc_size = $object->alloc_size();

Index of the last valid (loaded) file byte will be returned when this is the last sector in a chain. When C<0xff> value is returned, this sector may be included in a link chain (if that is the case, C<ts_link> can be used to fetch track and sector link values to the next chunk of data in a chain).

Set index of the last allocated byte within the sector data:

  $object->alloc_size($alloc_size);

Setting index of the last allocated byte marks sector as the last one in a chain.

=cut

sub alloc_size {
    my ($self, $alloc_size) = @_;

    my $data = $self->_object_property('data');

    if (defined $alloc_size) {
        if (ref $alloc_size) {
            die sprintf q{Invalid index type (%s) of the last allocated byte within the sector data (single byte expected)}, $self->_dump($alloc_size);
        }
        unless ($self->_is_valid_number_value($alloc_size)) {
            die sprintf q{Invalid index value (%s) of the last allocated byte within the sector data (single byte expected)}, $self->_dump($alloc_size);
        }
        $data->[$I_ALLOC_SIZE] = chr $alloc_size;
        $data->[$I_TS_POINTER_TRACK] = chr 0x00;
    }

    return 0xff if $self->is_valid_ts_link();

    $alloc_size = ord $data->[$I_ALLOC_SIZE];

    return $alloc_size;
}

=head2 empty

Check if sector object is empty:

  my $is_empty = $object->empty();

Set boolean flag to mark sector object as empty:

  $object->empty(1);

Clear boolean flag to mark sector object as non-empty:

  $object->empty(0);

=cut

sub empty {
    my ($self, $is_empty) = @_;

    if (defined $is_empty) {
        if (ref $is_empty) {
            die q{Invalid "empty" flag};
        }
        $self->_object_property('is_empty', $is_empty ? 1 : 0);
    }

    $is_empty = $self->_object_property('is_empty');

    return $is_empty;
}

=head2 clean

Wipe out an entire sector data, and mark it as empty:

  $object->clean();

=cut

sub clean {
    my ($self) = @_;

    my $clean_object = $self->_init();

    while (my ($property, $value) = each %{$clean_object}) {
        $self->_object_property($property, $value);
    }

    return;
}

=head2 print

Print out formatted disk sector data:

  $object->print(fh => $fh);

C<$fh> defaults to the standard output.

=cut

sub print {
    my ($self, %args) = @_;

    my $fh = $args{fh};

    $fh ||= *STDOUT;
    $fh->binmode(':bytes');

    my $stdout = select $fh;

    my $data = $self->_object_property('data');

    print q{    };
    for (my $col = 0x00; $col < 0x10; $col++) {
        printf q{%02X }, $col;
    }
    print qq{\n} . q{    } . '-' x 47 . qq{\n};
    for (my $row = 0x00; $row < 0x100; $row += 0x10) {
        printf q{%02X: }, $row;
        for (my $col = 0x00; $col < 0x10; $col++) {
            my $val = ord $data->[$row + $col];
            printf q{%02X }, $val;
        }
        for (my $col = 0x00; $col < 0x10; $col++) {
            my $val = ord $data->[$row + $col];
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

    select $stdout;

    return;
}

sub _dump {
    my ($self, $value) = @_;

    if ($self->_is_valid_number_value($value)) {
        return sprintf q{$%02x}, $value;
    }

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

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace neither by default nor explicitly.

=head1 SEE ALSO

L<D64::Disk::Image>, L<D64::Disk::Layout>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.02 (2013-02-10)

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Pawel Krol E<lt>pawelkrol@cpan.orgE<gt>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;

__END__
