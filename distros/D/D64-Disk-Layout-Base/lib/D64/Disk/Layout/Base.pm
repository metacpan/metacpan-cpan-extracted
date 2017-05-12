package D64::Disk::Layout::Base;

=head1 NAME

D64::Disk::Layout::Base - A base class for designing physical layouts of various Commodore disk image formats

=head1 SYNOPSIS

  package D64::MyLayout;

  # Establish an ISA relationship with base class:
  use base qw(D64::Disk::Layout::Base);

  # Number of bytes per sector storage:
  our $bytes_per_sector = 256;

  # Number of sectors per track storage:
  our @sectors_per_track = ( 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, # tracks 1-17
                             19, 19, 19, 19, 19, 19, 19,                                         # tracks 18-24
                             18, 18, 18, 18, 18, 18,                                             # tracks 25-30
                             17, 17, 17, 17, 17, 17, 17, 17, 17, 17                              # tracks 31-40
                           );

  # Override default object constructor:
  sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if (defined $self) {
      bless $self, $class;
      return $self;
    }
    else {
      warn 'Failed to create new D64::MyLayout object';
      return undef;
    }
  }

  package main;

  # Read disk image data from file and create new derived class object instance:
  my $diskLayoutObj = D64::MyLayout->new('image.d64');

  # Get number of tracks available for use:
  my $num_tracks = $diskLayoutObj->num_tracks();
  # Get number of sectors per track information:
  my $num_sectors = $diskLayoutObj->num_sectors($track);

  # Read physical sector data from disk image:
  my $data = $diskLayoutObj->sector_data($track, $sector);
  my @data = $diskLayoutObj->sector_data($track, $sector);

  # Write physical sector data into disk image:
  $diskLayoutObj->sector_data($track, $sector, $data);
  $diskLayoutObj->sector_data($track, $sector, @data);

  # Save data changes to file:
  $diskLayoutObj->save();
  $diskLayoutObj->save_as('image.d64');

=head1 DESCRIPTION

This package provides a base class for designing physical layouts of various Commodore disk image formats, represented by data that can be allocated into tracks and sectors. The following two variables are required to be defined at a package-scope level of any derived class:

  our $bytes_per_sector = 256;

This scalar value defines number of bytes per sector storage.

  our @sectors_per_track = ( 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, # tracks 1-17
                             19, 19, 19, 19, 19, 19, 19,                                         # tracks 18-24
                             18, 18, 18, 18, 18, 18,                                             # tracks 25-30
                             17, 17, 17, 17, 17, 17, 17, 17, 17, 17                              # tracks 31-40
                           );

This list defines number of sectors per track storage.

Initialization of both these properties is always validated at compile-time within import method of the base class.

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use base qw(Exporter);
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'all'} = [];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.01';

use Carp qw(carp croak);

sub import {
    my $this = shift;
    my $class = ref($this) || $this;
    my $bytes_per_sector = $class->_derived_class_property_value('$bytes_per_sector');
    croak "Derived class \"${class}\" does not define \"\$bytes_per_sector\" value" unless defined $bytes_per_sector;
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    croak "Derived class \"${class}\" does not define \"\@sectors_per_track\" array" unless defined $sectors_per_track_aref;
    # $class->_track_data_offsets($bytes_per_sector, $sectors_per_track_aref);
    $class->SUPER::import();
}

=head2 new

Create empty unformatted disk image layout:

  my $diskLayoutObj = D64::Disk::Layout::Base->new();

Read disk image layout from existing file:

  my $diskLayoutObj = D64::Disk::Layout::Base->new('image.d64');

A valid D64::Disk::Layout::Base object is returned upon success, an undefined value otherwise.

You are most likely wanting to override this method in your derived class source code by calling it first to create an object and then reblessing a referenced object currently belonging to the base class:

  use base qw(D64::Disk::Layout::Base);

  sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    if (defined $self) {
      bless $self, $class;
      return $self;
    }
    else {
      warn 'Failed to create new D64::MyLayout object';
      return undef;
    }
  }

Creating a new object may fail upon one of the following conditions:

=over

=item *
File specified as an input parameter does not exist or cannot be read

=item *
File is too short, what causes inability to read complete sector data

=back

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my $self = {};
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
    my $filename = shift;
    if (defined $filename) {
        # Validate that file exists:
        unless (-e $filename) {
            carp "File \"${filename}\" does not exist";
            return 0;
        }
        unless (-r $filename) {
            carp "Unable to open file \"${filename}\" for reading";
            return 0;
        }
        # Read disk image data from file:
        my $readOK = $self->_read_image_data($filename);
        return 0 unless $readOK;
    }
    else {
        # Create new empty disk image:
        $self->_create_empty_image();
    }
    return 1;
}

sub _create_empty_image {
    my $self = shift;
    my $class = ref($self) || $self;
    my $bytes_per_sector = $class->_derived_class_property_value('$bytes_per_sector');
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    # Generate track data:
    my $num_tracks = @{$sectors_per_track_aref};
    for (my $track = 1; $track <= $num_tracks; $track++) {
        # Generate sector data:
        my $num_sectors = $sectors_per_track_aref->[$track - 1];
        for (my $sector = 0; $sector < $num_sectors; $sector++) {
            my $buffer = chr (0x00) x $bytes_per_sector;
            $self->sector_data($track, $sector, $buffer);
        }
    }
}

sub _read_image_data {
    my $self = shift;
    my $filename = shift;
    my $class = ref($self) || $self;
    my $bytes_per_sector = $class->_derived_class_property_value('$bytes_per_sector');
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    # my $track_data_offsets_aref = $class->_derived_class_property_value('@track_data_offsets');
    # Open file for reading:
    open (my $fh, '<', $filename) or croak $!;
    binmode $fh;
    # Read track data:
    my $num_tracks = @{$sectors_per_track_aref};
    for (my $track = 1; $track <= $num_tracks; $track++) {
        # Read sector data:
        my $num_sectors = $sectors_per_track_aref->[$track - 1];
        for (my $sector = 0; $sector < $num_sectors; $sector++) {
            my $buffer;
            # my $offset = $track_data_offsets_aref->[$track - 1] + $sector * $bytes_per_sector;
            my $num_bytes = sysread ($fh, $buffer, $bytes_per_sector);
            if ($num_bytes == $bytes_per_sector) {
                $self->sector_data($track, $sector, $buffer);
            }
            elsif ($num_bytes > 0 and $num_bytes != $bytes_per_sector) {
                croak "Number of bytes read from disk image \"${filename}\" on track ${track} and sector ${sector} is ${num_bytes} when ${bytes_per_sector} bytes were expected (file too short?)";
            }
        }
    }
    # Close file upon reading:
    close ($fh) or croak $!;
    # Keep the name of file read for further data saving actions:
    $self->{'FILE'} = $filename;
}

=head2 sector_data

Read physical sector data from disk image:

  my $data = $diskLayoutObj->sector_data($track, $sector);
  my @data = $diskLayoutObj->sector_data($track, $sector);

Can either be read into a scalar (in which case it is a bytes sequence) or into an array (method called in a list context returns a list of single bytes of data). Length of a scalar as well as size of an array depends on number of bytes per sector storage defined within derived class in $bytes_per_sector variable.

A valid sector data is returned upon successful read, an undefined value otherwise.

Write physical sector data into disk image:

  $diskLayoutObj->sector_data($track, $sector, $data);
  $diskLayoutObj->sector_data($track, $sector, @data);

Same as above, data to write can be provided as a scalar (a bytes sequence of strictly defined length) as well as an array (list of single bytes of data of precisely specified size).

A valid sector data is returned upon successful write, an undefined value otherwise.

=cut

sub sector_data {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my @data = splice @_;
    my $class = ref($self) || $self;
    my $data;
    $data .= $_ for @data;
    # Validate track number (should be within range 1 .. $num_tracks):
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    my $num_tracks = @{$sectors_per_track_aref};
    if ($track < 1 or $track > $num_tracks) {
        carp "Invalid track number: ${track} (accepted track number range for this class is: 1 <= \$track <= ${num_tracks})";
        return undef;
    }
    # Validate sector number (should be within range 0 .. $num_sectors - 1):
    my $num_sectors = $self->num_sectors($track);
    if ($sector < 0 or $sector >= $num_sectors) {
        carp "Invalid sector number: ${sector} (accepted sector number range for this class is: 0 <= \$sector < ${num_sectors})";
        return undef;
    }
    if (defined $data) {
        my $bytes_per_sector = $class->_derived_class_property_value('$bytes_per_sector');
        my $data_length = length $data;
        # Validate data length (should contain exactly "$bytes_per_sector" bytes):
        if ($data_length > $bytes_per_sector) {
            my $bytes_truncated = $data_length - $bytes_per_sector;
            substr $data, $bytes_per_sector, $bytes_truncated, '';
            carp "Too much data provided while writing physical sector into disk image, last ${bytes_truncated} byte(s) of data truncated and just ${bytes_per_sector} byte(s) written";
        }
        # Pad data to be written to disk with zeroes (uninitialized values):
        if ($data_length < $bytes_per_sector) {
            my $bytes_appended = $bytes_per_sector - $data_length;
            substr $data, $data_length, 0, chr (0x00) x $bytes_appended;
            carp "Too little data provided while writing physical sector into disk image, ${bytes_appended} extra zero byte(s) of data appended and ${bytes_per_sector} byte(s) written";
        }
        $self->{'DATA'}->[$track]->[$sector] = $data;
    }
    return unless defined wantarray;
    $data = $self->{'DATA'}->[$track]->[$sector];
    if (wantarray) {
        @data = split //, $data;
        return @data;
    }
    else {
        return $data;
    }
}

sub _track_data_offsets {
    my ($class, $bytes_per_sector, $sectors_per_track_aref) = splice @_;
    my @track_data_offsets = ();
    my $offset = 0;
    my $num_tracks = @{$sectors_per_track_aref};
    for (my $track = 0; $track < $num_tracks; $track++) {
        push @track_data_offsets, $offset;
        $offset += $sectors_per_track_aref->[$track] * $bytes_per_sector;
    }
    $class->_derived_class_property_value('@track_data_offsets', \@track_data_offsets);
}

sub _derived_class_property_value {
    my $this = shift;
    my $param = shift;
    my $value = shift;
    my $class = ref($this) || $this;
    $param =~ s/^(.)//;
    my $type = $+;
    if ($type eq '$') {
        unless (defined $value) {
            return eval "\$${class}::${param}";
        }
        else {
            return eval "\$${class}::${param} = \$value";
        }
    }
    elsif ($type eq '@') {
        unless (defined $value) {
            return eval "\\\@${class}::${param}";
        }
        else {
            return eval "\@${class}::${param} = \@{\$value}";
        }
    }
    return undef;
}

=head2 num_tracks

Get number of tracks available:

  my $num_tracks = $diskLayoutObj->num_tracks();

=cut

sub num_tracks {
    my $self = shift;
    my $class = ref($self) || $self;
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    my $num_tracks = @{$sectors_per_track_aref};
    return $num_tracks;
}

=head2 num_sectors

Get number of sectors per track:

  my $num_sectors = $diskLayoutObj->num_sectors($track);

Number of sectors per specified track is returned upon success, an undefined value otherwise.

=cut

sub num_sectors {
    my $self = shift;
    my $track = shift;
    my $class = ref($self) || $self;
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    my $num_tracks = @{$sectors_per_track_aref};
    if ($track < 1 or $track > $num_tracks) {
        carp "Invalid track number: ${track} (accepted track number range for this class is: 1 <= \$track <= ${num_tracks})";
        return undef;
    }
    my $num_sectors = $sectors_per_track_aref->[$track - 1];
    return $num_sectors;
}

=head2 save

Save disk layout data to previously loaded image file:

  my $saveOK = $diskLayoutObj->save();

This method will not work when layout object is created as an empty unformatted disk image. Creating empty unformatted disk image layout forces usage of "save_as" method to save data by providing a filename to create new file. Disk layout object needs to be created by reading disk image layout from existing file to make this particular subroutine operative.

Returns true value upon successful write, and false otherwise.

=cut

sub save {
    my $self = shift;
    my $filename = $self->{'FILE'};
    unless (defined $filename) {
        carp "This disk layout object has been created as an empty unformatted disk image without a filename specified during its creation. You need to use 'save_as' method in order to provide a filename to create new file instead";
        return 0;
    }
    my $saveOK = $self->save_as($filename);
    return $saveOK;
}

=head2 save_as

Save disk layout data to file with specified name:

  my $saveOK = $diskLayoutObj->save_as('image.d64');

A behaviour implemented in this method prevents from overwriting an existing file unless it is the same file as the one that data has been previously read from (the same file that was used while creating this object instance).

Returns true value upon successful write, and false otherwise.

=cut

sub save_as {
    my $self = shift;
    my $filename = shift;
    my $class = ref($self) || $self;
    # Test if provided filename is the same as file loaded during initialization:
    my $loaded_filename = $self->{'FILE'};
    unless (defined $loaded_filename and $loaded_filename eq $filename) {
        # Validate that target file does not exist yet:
        if (-e $filename) {
            carp "Unable to save disk layout data. Target file \"${filename}\" already exists";
            return 0;
        }
    }
    # If both names are the same, there is no need to validate file existence,
    # because in such case we allow to overwrite original file with new data!
    my $bytes_per_sector = $class->_derived_class_property_value('$bytes_per_sector');
    my $sectors_per_track_aref = $class->_derived_class_property_value('@sectors_per_track');
    # Open file for writing:
    open (my $fh, '>', $filename) or croak $!;
    binmode $fh;
    # Write track data:
    my $num_tracks = @{$sectors_per_track_aref};
    for (my $track = 1; $track <= $num_tracks; $track++) {
        # Write sector data:
        my $num_sectors = $sectors_per_track_aref->[$track - 1];
        for (my $sector = 0; $sector < $num_sectors; $sector++) {
            my $data = $self->sector_data($track, $sector);
            # my $offset = $track_data_offsets_aref->[$track - 1] + $sector * $bytes_per_sector;
            my $num_bytes = syswrite ($fh, $data, $bytes_per_sector);
            unless (defined $num_bytes and $num_bytes == $bytes_per_sector) {
                carp "There was a problem writing data to file \"${filename}\": $!";
                close $fh;
                unlink $filename if defined $loaded_filename and $loaded_filename ne $filename;
                return 0;
            }
        }
    }
    # Close file upon reading:
    close ($fh) or croak $!;
    # Keep the name of file read for further data saving actions:
    $self->{'FILE'} = $filename;
    return 1;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

L<D64::Disk::Image>

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.01 (2011-01-22)

=head1 COPYRIGHT AND LICENSE

Copyright 2011 by Pawel Krol <pawelkrol@cpan.org>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1;
