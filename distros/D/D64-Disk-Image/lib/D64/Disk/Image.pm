package D64::Disk::Image;

=head1 NAME

D64::Disk::Image - Perl interface to Per Olofsson's "diskimage.c", an ANSI C library for manipulating Commodore disk images

=head1 SYNOPSIS

  use D64::Disk::Image qw(:all);

  # Create an empty image:
  my $d64 = D64::Disk::Image->create_image('image.d64');

  # Format the image:
  my $rawname = $d64->rawname_from_name('title');
  my $rawid = $d64->rawname_from_name('id');
  $d64->format($rawname, $rawid);

  # Write the image to disk:
  $d64->free_image();

  # Load an image from disk:
  my $d64 = D64::Disk::Image->load_image('image.d64');

  # Open a file for writing:
  my $rawname = $d64->rawname_from_name('filename');
  my $prg = $d64->open($rawname, T_PRG, F_WRITE);

  # Write data to file:
  my $counter = $prg->write($buffer);

  # Close a file:
  $prg->close();

  # Open a file for reading:
  my $rawname = $d64->rawname_from_name('filename');
  my $prg = $d64->open($rawname, T_PRG, F_READ);

  # Read data from file:
  my ($counter, $buffer) = $prg->read();

  # Close a file:
  $prg->close();

  # Free an image in memory:
  $d64->free_image();

=head1 DESCRIPTION

Per Olofsson's "diskimage.c" is an ANSI C library for manipulating Commodore disk images. In Perl the following operations are implemented via C<D64::Disk::Image> package:

=over

=item *
Open file ('$' reads directory)

=item *
Delete file

=item *
Rename file

=item *
Format disk

=item *
Allocate sector

=item *
Deallocate sector

=back

Additionally, the following operations are implemented via accompanying C<D64::Disk::Image::File> package:

=over

=item *
Read file

=item *
Write file

=item *
Close file

=back

The following formats are supported:

=over

=item *
D64 (single-sided 1541 disk image, with optional error info, which is currently ignored)

=item *
D71 (double-sided 1571 disk image)

=item *
D81 (3,5" 1581 disk image, however only root directory)

=back

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

# Image type constants:
use constant D64 => 1;
use constant D71 => 2;
use constant D81 => 3;

# Image size constants:
use constant D64_SIZE => 174848;
use constant D71_SIZE => 349696;
use constant D81_SIZE => 819200;

# File type constants:
use constant T_DEL => 0;
use constant T_SEQ => 1;
use constant T_PRG => 2;
use constant T_USR => 3;
use constant T_REL => 4;
use constant T_CBM => 5;
use constant T_DIR => 6;

our $VERSION = '0.02';

use Carp qw/carp croak verbose/;

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

use D64::Disk::Image::File qw(:all);

use base qw( Exporter );
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'imagetypes'} = [ qw(&D64 &D71 &D81) ];
$EXPORT_TAGS{'filetypes'} = [ qw(&T_DEL &T_SEQ &T_PRG &T_USR &T_REL &T_CBM &T_DIR) ];
$EXPORT_TAGS{'modes'} = [ qw(&F_READ &F_WRITE) ];
$EXPORT_TAGS{'types'} = [ @{$EXPORT_TAGS{'imagetypes'}}, @{$EXPORT_TAGS{'filetypes'}} ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'types'}}, @{$EXPORT_TAGS{'modes'}} ];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

=head2 new / load_image

Create new C<D64::Disk::Image> object and load existing D64/D71/D81 image file from disk:

  my $d64DiskImageObj = D64::Disk::Image->new($name);
  my $d64DiskImageObj = D64::Disk::Image->load_image($name);

=head2 new / create_image

Create new C<D64::Disk::Image> object and create new D64/D71/D81 image file on disk:

  my $d64DiskImageObj = D64::Disk::Image->new($name, $imageType);
  my $d64DiskImageObj = D64::Disk::Image->create_image($name, $imageType);

The following image type constants are available: D64, D71, D81 (image type D64 is used by default when executed as "create_image"). Each disk created needs to be formatted first before it can be used.

=cut

sub new {
    my $this = shift;
    my $name = shift;
    my $imageType = shift;
    unless (defined $imageType) {
        my $self = $this->load_image($name);
        return $self;
    }
    else {
        my $self = $this->create_image($name, $imageType);
        return $self;
    }
}

sub load_image {
    my $this = shift;
    my $name = shift;
    croak "Failed to open '${name}': file does not exist" unless defined $name and -e $name and -r $name;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    my $diskImage = di_load_image($name);
    $self->{'DISK_IMAGE'} = $diskImage;
    return $self;
}

sub create_image {
    my $this = shift;
    my $name = shift;
    croak "Failed to create disk image file '${name}': file already exists" if defined $name and -e $name;
    my $imageType = shift || &D64;
    my $class = ref($this) || $this;
    my $sizeMap_ref = {
        &D64 => &D64_SIZE,
        &D71 => &D71_SIZE,
        &D81 => &D81_SIZE,
    };
    my $size = $sizeMap_ref->{$imageType};
    my $self = {};
    bless $self, $class;
    my $diskImage = di_create_image($name, $size);
    $self->{'DISK_IMAGE'} = $diskImage;
    return $self;
}

=head2 free_image

Free an image in memory (each opened disk needs to be subsequently freed to avoid memory leaks):

  $d64DiskImageObj->free_image();

If the image has been modified, the changes will be written to disk.

=cut

sub free_image {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    di_free_image($diskImage);
}

=head2 sync

Write the image to disk:

  $d64DiskImageObj->sync();

=cut

sub sync {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    di_sync($diskImage);
}

=head2 status

Get the drive status:

  my ($numstatus, $status) = $d64DiskImageObj->status();

Numerical status is returned first, textual content of a status message is copied to the second return value.

=cut

sub status {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my ($numstatus, $status) = di_status($diskImage);
    carp "Failed to read disk image status" unless defined $status and length $status > 0;
    return ($numstatus, $status);
}

=head2 open

Open a file for reading or writing:

  my $imageFileObj = $d64DiskImageObj->open($rawname, $fileType, $mode);

The following file type constants are available: T_DEL, T_SEQ, T_PRG, T_USR, T_REL, T_CBM, T_DIR (by default file type T_PRG is used)

There are two open modes available: F_READ for reading, F_WRITE for writing (by default file is opened in F_READ mode)

Opening, reading, writing, and closing files is described in detail in L<D64::Disk::Image::File>

=cut

sub open {
    my $self = shift;
    my $rawname = shift;
    my $fileType = shift || &T_PRG;
    my $mode = shift || &F_READ;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $imageFile = D64::Disk::Image::File->open($diskImage, $rawname, $fileType, $mode);
    return $imageFile;
}

=head2 format

Format the image:

  my $numstatus = $d64DiskImageObj->format($rawname, $rawid);

If $rawid is given, a full format is performed.

  my $numstatus = $d64DiskImageObj->format($rawname);

If no $rawid is given, a quick format is performed.

=cut

sub format {
    my $self = shift;
    my $rawname = shift;
    my $rawid = shift || '\0';
    my $diskImage = $self->{'DISK_IMAGE'};
    my $numstatus = di_format($diskImage, $rawname, $rawid);
    return $numstatus;
}

=head2 delete

Delete files matching the pattern:

    my $numstatus = $d64DiskImageObj->delete($rawPattern, $fileType);

=cut

sub delete {
    my $self = shift;
    my $rawPattern = shift;
    my $fileType = shift || &T_PRG;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $status = di_delete($diskImage, $rawPattern, $fileType);
    return $status;
}

=head2 rename

Rename a file:

    my $numstatus = $d64DiskImageObj->rename($oldRawName, $newRawName, $fileType);

=cut

sub rename {
    my $self = shift;
    my $oldRawName = shift;
    my $newRawName = shift;
    my $fileType = shift || &T_PRG;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $status = di_rename($diskImage, $oldRawName, $newRawName, $fileType);
    return $status;
}

=head2 sectors_per_track

Get the number of sectors in a given track:

  my $sectors = D64::Disk::Image->sectors_per_track($imageType, $track);
  my $sectors = $d64DiskImageObj->sectors_per_track($imageType, $track);

=cut

sub sectors_per_track {
    my $this = shift;
    my $imageType = shift;
    my $track = shift;
    my $sectors = di_sectors_per_track($imageType, $track);
    return $sectors;
}

=head2 tracks

Get the number of tracks in the image:

  my $tracks = D64::Disk::Image->tracks($imageType);
  my $tracks = $d64DiskImageObj->tracks($imageType);

=cut

sub tracks {
    my $this = shift;
    my $imageType = shift;
    my $tracks = di_tracks($imageType);
    return $tracks;
}

=head2 title

Get the disk title and id in the BAM:

  my ($title, $id) = $d64DiskImageObj->title();

=cut

sub title {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my ($title, $id) = di_title($diskImage);
    carp "Failed to read disk image title" unless defined $title and length $title > 0;
    carp "Failed to read disk image id" unless defined $id and length $id > 0;
    return ($title, $id);
}

=head2 track_blocks_free

Get the number of free sectors in a given track:

    my $track_blocks_free = $d64DiskImageObj->track_blocks_free($track);

=cut

sub track_blocks_free {
    my $self = shift;
    my $track = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $track_blocks_free = di_track_blocks_free($diskImage, $track);
    return $track_blocks_free;
}

=head2 is_ts_free

Get non-zero if the given track and sector is free, and zero if it's allocated:

    my $is_ts_free = $d64DiskImageObj->is_ts_free($track, $sector);

=cut

sub is_ts_free {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $is_ts_free = di_is_ts_free($diskImage, $track, $sector);
    return $is_ts_free;
}

=head2 alloc_ts

Allocate a given track and sector:

    $d64DiskImageObj->alloc_ts($track, $sector);

=cut

sub alloc_ts {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    di_alloc_ts($diskImage, $track, $sector);
}

=head2 free_ts

Free a given track and sector:

    $d64DiskImageObj->free_ts($track, $sector);

=cut

sub free_ts {
    my $self = shift;
    my $track = shift;
    my $sector = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    di_free_ts($diskImage, $track, $sector);
}

=head2 rawname_from_name

Convert a NULL-terminated string to 16-byte 0xA0 padding:

  my $rawname = D64::Disk::Image->rawname_from_name($name);
  my $rawname = $d64DiskImageObj->rawname_from_name($name);

=cut

sub rawname_from_name {
    my $this = shift;
    my $name = shift;
    my $rawname = di_rawname_from_name($name);
    carp "Failed to convert '${name}' to rawname" unless defined $rawname and length $rawname > 0;
    return $rawname;
}

=head2 name_from_rawname

Converts a 0xA0 padded string to a NULL-terminated string:

  my $name = D64::Disk::Image->name_from_rawname($rawname);
  my $name = $d64DiskImageObj->name_from_rawname($rawname);

=cut

sub name_from_rawname {
    my $this = shift;
    my $rawname = shift;
    my $name = di_name_from_rawname($rawname);
    carp "Failed to convert '${rawname}' to name" unless defined $name and length $name > 0;
    return $name;
}

=head2 blocksfree

Get number of blocks free:

  my $blocksFree = $d64DiskImageObj->blocksfree();

=cut

sub blocksfree {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $blocksFree = _di_blocksfree($diskImage);
    return $blocksFree;
}

=head2 type

Get image type:

  my $imageType = $d64DiskImageObj->type();

=cut

sub type {
    my $self = shift;
    my $diskImage = $self->{'DISK_IMAGE'};
    my $imageType = _di_type($diskImage);
    return $imageType;
}

=head2 ascii_to_petscii

Convert an ASCII string to a PETSCII string:

  my $petscii_string = D64::Disk::Image->ascii_to_petscii($ascii_string);
  my $petscii_string = $d64DiskImageObj->ascii_to_petscii($ascii_string);

=cut

sub ascii_to_petscii {
    my $this = shift;
    my $str_ascii = shift;
    my $str_petscii = '';
    while ($str_ascii =~ s/^(.)(.*)$/$2/) {
        my $c = ord $1;
        $c &= 0x7f;
        if ($c >= ord 'A' && $c <= ord 'Z') {
            $c += 32;
        } elsif ($c >= ord 'a' && $c <= ord 'z') {
            $c -= 32;
        }
        $str_petscii .= chr $c;
    }
    return $str_petscii;
}

=head2 petscii_to_ascii

Convert a PETSCII string to an ASCII string:

  my $ascii_string = D64::Disk::Image->petscii_to_ascii($petscii_string);
  my $ascii_string = $d64DiskImageObj->petscii_to_ascii($petscii_string);

=cut

sub petscii_to_ascii {
    my $this = shift;
    my $str_petscii = shift;
    my $str_ascii = '';
    while ($str_petscii =~ s/^(.)(.*)$/$2/) {
        my $c = ord $1;
        $c &= 0x7f;
        if ($c >= ord 'A' && $c <= ord 'Z') {
            $c += 32;
        } elsif ($c >= ord 'a' && $c <= ord 'z') {
            $c -= 32;
        } elsif ($c == 0x7f) {
            $c = 0x3f;
        }
        $str_ascii .= chr $c;
    }
    return $str_ascii;
}

=head1 EXAMPLES

Print out the BAM:

  # Load image into RAM:
  my $d64 = D64::Disk::Image->load_image('image.d64');

  # Get image type:
  my $imageType = $d64->type();

  # Print BAM:
  print "TRK  FREE  MAP\n";
  for (my $track = 1; $track <= $d64->tracks($imageType); $track++) {
    my $sectors = $d64->sectors_per_track($imageType, $track);
    printf "%3d: %2d/%d ", $track, $d64->track_blocks_free($track), $sectors;
    for (my $sector = 0; $sector < $sectors; $sector++) {
      printf "%d", $d64->is_ts_free($track, $sector);
    }
    print "\n";
  }
  print "\n";

  # Print number of blocks free:
  my $blocksFree = $d64->blocksfree();
  printf "%d blocks free\n", $blocksFree;

  # Release image:
  $d64->free_image();

List the directory:

  my @file_types = qw/del seq prg usr rel cbm dir ???/;

  # Load image into RAM:
  my $d64 = D64::Disk::Image->load_image('image.d64');

  # Open directory for reading:
  my $dir = $d64->open('$', T_PRG, F_READ);

  # Convert title to ASCII:
  my ($title, $id) = $d64->title();
  $title = $d64->name_from_rawname($title);
  $title = $d64->petscii_to_ascii($title);

  # Convert ID to ASCII:
  $id = $d64->name_from_rawname($id);
  $id = $d64->petscii_to_ascii($id);

  # Print title and disk ID:
  printf "0 \"%-16s\" %s\n", $title, $id;

  # Read first block into buffer:
  my ($counter, $buffer) = $dir->read(254);
  die 'BAM read failed' if $counter != 254;

  # Read directory blocks:
  while (1) {
    my ($counter, $buffer) = $dir->read(254);
    last unless $counter == 254;

    for (my $offset = -2; $offset < 254; $offset += 32) {

      # If file type != 0:
      my $file_type = ord (substr $buffer, $offset + 2, 1);
      if ($file_type != 0) {

        my $rawname = substr $buffer, $offset + 5;
        my $name = $d64->name_from_rawname($rawname);
        my $type = $file_type & 7;
        my $closed = $file_type & 0x80;
        my $locked = $file_type & 0x40;
        my $size = ord (substr $buffer, $offset + 31, 1) << 8 | ord (substr $buffer, $offset + 30, 1);

        # Convert to ASCII and add quotes:
        $name = $d64->petscii_to_ascii($name);
        my $quotename = sprintf "\"%s\"", $name;

        # Print directory entry:
        printf "%-4d  %-18s%c%s%c\n", $size, $quotename, $closed ? ord ' ' : ord '*', $file_types[$type], $locked ? ord '<' : ord ' ';
      }
    }
  }

  # Print number of blocks free:
  my $blocksFree = $d64->blocksfree();
  printf "%d blocks free\n", $blocksFree;

  # Close directory:
  $dir->close();

  # Release image:
  $d64->free_image();

Copy a file from a disk image:

  # Load image into RAM:
  my $d64 = D64::Disk::Image->load_image('image.d64');

  # Convert filename:
  my $name = 'filename';
  my $rawname = $d64->rawname_from_name($d64->ascii_to_petscii($name));

  # Open file for reading:
  my $prg = $d64->open($rawname, T_PRG, F_READ);

  # Open file for writing:
  die "$name file already exists" if -e $name;
  open PRG, '>:bytes', $name or die "Couldn't open $name file for writing";

  # Read data from file:
  my ($size, $buffer) = $prg->read();
  print PRG $buffer;
  printf "Read %d bytes from %s\n", $size, $disk;

  # Close files:
  close PRG;
  $prg->close();

  # Release image:
  $d64->free_image();

Copy a file to a disk image:

  # Load image into RAM:
  my $d64 = D64::Disk::Image->load_image('image.d64');

  # Convert filename:
  my $name = 'filename';
  my $rawname = $d64->rawname_from_name($d64->ascii_to_petscii($name));

  # Open file for writing:
  my $prg = $d64->open($rawname, T_PRG, F_WRITE);

  # Open file for reading:
  die "$name file does not exist" unless -e $name;
  open PRG, '<:bytes', $name or die "Couldn't open $name file for reading";

  # Write data to file:
  my $buffer;
  my $filesize = (stat($name))[7];
  sysread PRG, $buffer, $filesize;
  my $size = $prg->write($buffer);
  printf "Wrote %d bytes to %s\n", $size, $disk_3;

  # Close files:
  close PRG;
  $prg->close();

  # Release image:
  $d64->free_image();

Create an empty disk image:

  # Create an empty image:
  my $d64 = D64::Disk::Image->create_image('image.d64', D64);

  # Convert title:
  my $name = 'title';
  my $rawname = $d64->rawname_from_name($d64->ascii_to_petscii($name));

  # Convert ID:
  my $id = 'id';
  my $rawid = $d64->rawname_from_name($d64->ascii_to_petscii($id));

  # Format the image:
  $d64->format($rawname, $rawid);

  # Release image:
  $d64->free_image();

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<D64::Disk::Image> exports nothing by default.

You may request the import of image type constants (D64, D71, and D81), and file type constants (C<T_DEL>, C<T_SEQ>, C<T_PRG>, C<T_USR>, C<T_REL>, C<T_CBM>, and C<T_DIR>). All of these constants can be explicitly imported from C<D64::Disk::Image> by using it with ":types" tag. You may also request the import of open mode constants (C<F_READ>, and C<F_WRITE>). Both these constants can be explicitly imported from C<D64::Disk::Image> by using it with ":modes" tag. All constants can be explicitly imported from C<D64::Disk::Image> by using it with ":all" tag.

=head1 SEE ALSO

L<D64::Disk::Image::File>

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.02 (2013-01-12)

=head1 COPYRIGHT AND LICENSE

diskimage.c is released under a slightly modified BSD license.

Copyright (c) 2003-2006, Per Olofsson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

=over

=item *
Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

=item *
Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

diskimage.c website: L<http://www.paradroid.net/diskimage/>

=cut

1;
