package D64::Disk::Layout;

=head1 NAME

D64::Disk::Layout - Handling entire Commodore (D64/D71/D81) disk image data in pure Perl

=head1 SYNOPSIS

    use D64::Disk::Layout;

    # Create an empty disk layout instance:
    my $layout = D64::Disk::Layout->new();

    # Read disk image layout from existing file:
    my $layout = D64::Disk::Layout->new('image.d64');

    # Get disk sector object from a disk layout:
    my $sector_layout = $layout->sector(track => $track, sector => $sector);

    # Put new data into specific disk layout sector:
    $layout->sector(data => $sector_layout);
    # Update an arbitrary disk layout sector with data:
    $layout->sector(data => $sector_layout, track => $track, sector => $sector);

    # Fetch disk layout data as an array of 683 sector objects:
    my @sector_layouts = $layout->sectors();

    # Update disk layout given an array of arbitrary sector objects:
    $layout->sectors(sectors => \@sector_layouts);

    # Fetch disk layout data as a scalar of 683 * 256 bytes:
    my $data = $layout->data();

    # Update disk layout providing 683 * 256 bytes of scalar data:
    $layout->data(data => $data);

    # Print out nicely formatted human-readable form of a track/sector data:
    $layout->print(fh => $fh, track => $track, sector => $sector);

=head1 DESCRIPTION

C<D64::Disk::Layout> provides a helper class for C<D64::Disk> module, enabling users to easily access and manipulate entire D64/D71/D81 disk image data in an object oriented way without the hassle of worrying about the meaning of individual bits and bytes located on every track and sector of a physical disk image. The whole family of C<D64::Disk::Layout> modules has been implemented in pure Perl as an alternative to Per Olofsson's "diskimage.c" library originally written in an ANSI C.

C<D64::Disk::Layout> is completely unaware of an internal structure, configuration and meaning of individual sectors on disk. It only knows how to fetch and store bytes of data. Standard C<D64> disk image of C<170> kbytes is split into C<683> sectors on C<35> tracks, each of the sectors holding C<256> bytes. See description of the L<D64::Disk> module for a detailed description on accessing individual disk image files and preserving disk directory structure.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.02';

use base qw(D64::Disk::Layout::Base);
use Carp qw(carp croak);
use D64::Disk::Layout::Sector;
use List::MoreUtils qw(arrayify zip6);

# Number of bytes per sector storage:
our $bytes_per_sector = 256;

# Number of sectors per track storage:
our @sectors_per_track = ( 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, # tracks 1-17
                           19, 19, 19, 19, 19, 19, 19,                                         # tracks 18-24
                           18, 18, 18, 18, 18, 18,                                             # tracks 25-30
                           17, 17, 17, 17, 17,                                                 # tracks 31-35
                           # 17, 17, 17, 17, 17, 17, 17, 17, 17, 17,                             # tracks 31-40
                         );

=head2 new

Create empty unformatted D64 disk image layout:

    my $d64DiskLayoutObj = D64::Disk::Layout->new();

Read D64 disk image layout from existing file:

    my $d64DiskLayoutObj = D64::Disk::Layout->new('image.d64');

A valid D64::Disk::Layout object is returned upon success, an undefined value otherwise.

=cut

sub new {
  my ($class) = shift ;
  my $self = $class->SUPER::new(@_);
  if (defined $self) {
    bless $self, $class;
    return $self;
  }
  else {
    carp 'Failed to create new ' . __PACKAGE__ . ' object';
    return undef;
  }
}

sub _initialize {
  my ($self) = shift;
  $self->SUPER::_initialize(@_);
  return 1;
}

=head2 sector

Retrieve disk sector object from a disk layout:

    my $sectorObj = $d64DiskLayoutObj->sector(track => $track, sector => $sector);

Insert new data into specific disk layout sector:

    $d64DiskLayoutObj->sector(data => $sectorObj);

Update an arbitrary disk layout sector with data:

    $d64DiskLayoutObj->sector(data => $sectorObj, track => $track, sector => $sector);

=cut

sub sector {
  my ($self, %args) = @_;
  my $track = $args{track};
  my $sector = $args{sector};
  my $data = $args{data};
  if (defined $data) {
    unless (defined $track && defined $sector) {
      $track = $data->track();
      $sector = $data->sector();
    }
    $self->sector_data($track, $sector, $data->data());
  }
  my @data = $self->sector_data($track, $sector);
  return D64::Disk::Layout::Sector->new(data => \@data, track => $track, sector => $sector);
}

=head2 sectors

Fetch disk layout data as a flattened array of 683 sector objects:

    my @sector_layouts = $d64DiskLayoutObj->sectors();

Update disk layout given an array of arbitrary sector objects:

    $d64DiskLayoutObj->sectors(sectors => \@sector_layouts);

=cut

sub sectors {
  my ($self, %args) = @_;
  my $sectors = $args{sectors};
  if (defined $sectors) {
    for my $sectorObj (@{$sectors}) {
      my $track = $sectorObj->track();
      my $sector = $sectorObj->sector();
      my $data = $sectorObj->data();
      $self->sector_data($track, $sector, $data);
    }
  }
  my @sector_layouts = arrayify $self->tracks();
  return @sector_layouts;
}

=head2 tracks

Fetch disk layout data as an array of 35 arrays of sector objects allocated by their respective track numbers:

    my @track_layouts = $d64DiskLayoutObj->tracks();

=cut

sub tracks {
  my ($self) = @_;
  my @track_numbers = (1 .. @sectors_per_track);
  my @track_layouts = map {
    my ($num_sectors, $track) = @{$_};
    [
      map {
        my $sector = $_;
        $self->sector(track => $track, sector => $sector);
      } (0 .. $num_sectors - 1)
    ];
  } zip6 @sectors_per_track, @track_numbers;
  return @track_layouts;
}

=head2 data

Fetch disk layout data as a scalar of 683 * 256 bytes:

    my $data = $d64DiskLayoutObj->data();

Update disk layout providing 683 * 256 bytes of scalar data:

    $d64DiskLayoutObj->data(data => $data);

=cut

sub data {
  my ($self, %args) = @_;
  my $data = $args{data};
  my @track_numbers = (1 .. @sectors_per_track);
  my $result = join '', map {
    my ($num_sectors, $track) = @{$_};
    join '', map {
      my $sector = $_;
      if (defined $data) {
        $self->sector_data($track, $sector, split //, substr $data, 0x00, $bytes_per_sector, '');
      }
      $self->sector_data($track, $sector);
    } (0 .. $num_sectors - 1);
  } zip6 @sectors_per_track, @track_numbers;
  return $result;
}

=head2 print

Print out nicely formatted human-readable form of a track/sector data into any given IO::Handle:

    $d64DiskLayoutObj->print(fh => $fh, track => $track, sector => $sector);

=cut

sub print {
  my ($self, %params) = @_;
  my $track = $params{track};
  my $sector = $params{sector};

  my $fh = $params{fh} || *STDOUT;
  my $stdout = select $fh;

  my @data = $self->sector_data($track, $sector);

  # Fail on invalid track/sector value combinations:
  carp 'Failed to print track/sector=' . $track . '/' . $sector . ' data' unless @data;

  for (my $i = 0x00; $i < 0x0100; $i += 0x10) {
    printf q{%02X:}, $i;
    for (my $j = 0x00; $j < 0x10; $j++) {
        printf q{ %02x}, ord $data[$i + $j];
    }
    print qq{\n};
  }

  select $stdout;
  return;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

L<D64::Disk::Image>, L<D64::Disk::Layout::Sector>, L<D64::Disk::Layout::Base>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.02 (2021-01-13)

=head1 COPYRIGHT AND LICENSE

Copyright 2021 by Pawel Krol <pawelkrol@cpan.org>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;

__END__
