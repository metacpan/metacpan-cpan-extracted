package D64::Disk::Dir;

=head1 NAME

D64::Disk::Dir - Handling entire Commodore (D64/D71/D81) disk image directories

=head1 SYNOPSIS

  use D64::Disk::Dir;

  # Read entire D64/D71/D81 disk image directory from file on disk in one step:
  my $d64DiskDirObj = D64::Disk::Dir->new($filename);

  # Read entire D64/D71/D81 disk image directory from file on disk in two steps:
  my $d64DiskDirObj = D64::Disk::Dir->new();
  my $readOK = $d64DiskDirObj->read_dir($filename);

  # Read new D64/D71/D81 disk directory replacing currently loaded dir with it:
  my $readOK = $d64DiskDirObj->read_dir($filename);

  # Get disk directory title converted to ASCII string:
  my $convert2ascii = 1;
  my $title = $d64DiskDirObj->get_title($convert2ascii);

  # Get disk directory ID converted to ASCII string:
  my $convert2ascii = 1;
  my $diskID = $d64DiskDirObj->get_id($convert2ascii);

  # Get number of blocks free:
  my $blocksFree = $d64DiskDirObj->get_blocks_free();

  # Get number of directory entries:
  my $num_entries = $d64DiskDirObj->num_entries();

  # Get directory entry at the specified position:
  my $entryObj = $d64DiskDirObj->get_entry($index);

  # Get binary file data from a directory entry at the specified position:
  my $data = $d64DiskDirObj->get_file_data($index);

  # Print out the entire directory content to the standard output:
  $d64DiskDirObj->print_dir();

=head1 DESCRIPTION

This package provides an abstract layer above D64::Disk::Image module, enabling user to handle D64 disk image directories in a higher-level object-oriented way.

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use base qw( Exporter );
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'all'} = [];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.03';

use Carp qw/carp croak verbose/;

use D64::Disk::Dir::Entry;
use D64::Disk::Image qw(:all);

# Mapping file types onto file type constants:
our %file_type_constants = (
    'del' => T_DEL,
    'seq' => T_SEQ,
    'prg' => T_PRG,
    'usr' => T_USR,
    'rel' => T_REL,
    'cbm' => T_CBM,
    'dir' => T_DIR,
    '???' => 0xFF,
);

=head2 new

Create empty C<D64::Disk::Dir> object without loading disk image directory yet:

  my $d64DiskDirObj = D64::Disk::Dir->new();

Create new C<D64::Disk::Dir> object and read entire D64/D71/D81 disk image directory from file on disk for further access.

  my $d64DiskDirObj = D64::Disk::Dir->new($filename);

A valid C<D64::Disk::Dir> object is returned upon success, an undefined value otherwise.

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
    # Read entire disk image directory:
    if (defined $filename) {
        my $readOK = $self->read_dir($filename);
        return 0 unless $readOK;
    }
    return 1;
}

sub _check_dir_read {
    my $self = shift;
    # Raise error if directory has not been read yet:
    croak "Unable to perform requested operation, because disk image directory has not been read yet" if $self->{'DIR_READ'} == 0;
}

sub _init_dir {
    my $self = shift;
    # Directory has not been read yet:
    $self->{'DIR_READ'} = 0;
    $self->_release_d64_image();
    $self->_clear_dir_entries();
    delete $self->{'D64_FILE_NAME'};
    delete $self->{'DIR_INFO'};
}

=head2 read_dir

Read entire D64/D71/D81 disk image directory from file on disk, replacing currently loaded directory (if any).

  $d64DiskDirObj->read_dir($filename);

Returns true value upon success, and false otherwise.

=cut

sub read_dir {
    my $self = shift;
    my $filename = shift;
    # We do not verify file existence here, D64::Disk::Image module croaks on inexisting files:
    $self->_init_dir();
    # Load image into RAM:
    my $d64DiskImageObj = D64::Disk::Image->load_image($filename);
    $self->{'D64_DISK_IMAGE'} = $d64DiskImageObj;
    $self->{'D64_FILE_NAME'} = $filename;
    # Open directory for reading:
    my $dir = $d64DiskImageObj->open('$', T_PRG, F_READ);
    # Get disk-wide directory information:
    $self->_get_dir_info($dir);
    # Read directory blocks:
    my $readOK = $self->_read_dir_blocks($dir);
    return 0 unless $readOK;
    # Close directory:
    $dir->close();
    # Store D64 disk image filename for further checks:
    $self->{'FILENAME'} = $filename;
    # Directory has been read successfully:
    $self->{'DIR_READ'} = 1;
    return 1;
    # There was a problem reading directory:
    return 0;
}

sub _read_dir_blocks {
    my $self = shift;
    my $dir = shift;
    # Read first block into buffer:
    my ($counter, $buffer) = $dir->read(254);
    if ($counter != 254) {
        carp 'BAM read failed';
        return 0;
    }
    # Read directory blocks:
    while (1) {
        my ($counter, $buffer) = $dir->read(254);
        last unless $counter == 254;
        for (my $offset = -2; $offset < 254; $offset += 32) {
            # If file type != 0:
            my $file_type = ord (substr $buffer, $offset + 2, 1);
            if ($file_type != 0) {
                # Create new D64::Disk::Dir::Entry object:
                my $bytes = substr $buffer, $offset + 2, 30;
                my $entryObj = D64::Disk::Dir::Entry->new($bytes);
                unless (defined $entryObj) {
                    carp 'Directory blocks read failed';
                    return 0;
                }
                # Add it to the list of directory entries:
                $self->_add_dir_entry($entryObj);
            }
        }
    }
    return 1;
}

sub _get_dir_info {
    my $self = shift;
    my $dir = shift;
    my $d64DiskImageObj = $self->{'D64_DISK_IMAGE'};
    # Get number of blocks free:
    my $blocksFree = $d64DiskImageObj->blocksfree();
    # Get title and ID:
    my ($title, $id) = $d64DiskImageObj->title();
    $title = D64::Disk::Image->name_from_rawname($title);
    $id = D64::Disk::Image->name_from_rawname($id);
    # Store directory details in a hash:
    $self->{'DIR_INFO'} = {
        'TITLE'       => $title,
        'ID'          => $id,
        'BLOCKS_FREE' => $blocksFree,
    };
}

sub _add_dir_entry {
    my $self = shift;
    my $entryObj = shift;
    push @{$self->{'DIR_ENTRIES'}}, $entryObj;
}

sub _get_dir_entries {
    my $self = shift;
    my $entries = $self->{'DIR_ENTRIES'};
    $entries = [] unless defined $entries;
    return $entries;
}

sub _clear_dir_entries {
    my $self = shift;
    $self->{'DIR_ENTRIES'} = [];
}

=head2 get_title

Get 16 character disk directory title (PETSCII string):

  my $convert2ascii = 0;
  my $title = $d64DiskDirObj->get_title($convert2ascii);

Get disk directory title converted to ASCII string:

  my $convert2ascii = 1;
  my $title = $d64DiskDirObj->get_title($convert2ascii);

=cut

sub get_title {
    my $self = shift;
    my $convert2ascii = shift;
    $self->_check_dir_read();
    my $title = $self->{'DIR_INFO'}->{'TITLE'};
    # Convert title to ASCII when necessary:
    $title = D64::Disk::Image->petscii_to_ascii($title) if $convert2ascii;
    return $title;
}

=head2 get_id

Get 2 character disk directory ID (PETSCII string):

  my $convert2ascii = 0;
  my $diskID = $d64DiskDirObj->get_id($convert2ascii);

Get disk directory ID converted to ASCII string:

  my $convert2ascii = 1;
  my $diskID = $d64DiskDirObj->get_id($convert2ascii);

=cut

sub get_id {
    my $self = shift;
    my $convert2ascii = shift;
    $self->_check_dir_read();
    my $id = $self->{'DIR_INFO'}->{'ID'};
    # Convert disk ID to ASCII when necessary:
    $id = D64::Disk::Image->petscii_to_ascii($id) if $convert2ascii;
    return $id;
}

=head2 get_blocks_free

Get number of blocks free:

  my $blocksFree = $d64DiskDirObj->get_blocks_free();

=cut

sub get_blocks_free {
    my $self = shift;
    $self->_check_dir_read();
    my $blocksFree = $self->{'DIR_INFO'}->{'BLOCKS_FREE'};
    return $blocksFree;
}

=head2 num_entries

Get number of directory entries:

  my $num_entries = $d64DiskDirObj->num_entries();

=cut

sub num_entries {
    my $self = shift;
    $self->_check_dir_read();
    my $entries_aref = $self->_get_dir_entries();
    my $num_entries = @{$entries_aref};
    return $num_entries;
}

=head2 get_entry

Get directory entry at the specified position (index value must be a valid position equal or greater than 0 and less than number of directory entries):

  my $entryObj = $d64DiskDirObj->get_entry($index);

Returns a valid L<D64::Disk::Dir::Entry> object upon success, and false otherwise.

=cut

sub get_entry {
    my $self = shift;
    my $index = shift;
    $self->_check_dir_read();
    my $num_entries = $self->num_entries();
    if ($index < 0 or $index >= $num_entries) {
        carp "Cannot get entry at invalid index position (disk directory contains only ${num_entries} file(s), unable to get entry at position ${index})";
        return undef;
    }
    my $entries_aref = $self->_get_dir_entries();
    my $entryObj = $entries_aref->[$index];
    return $entryObj;
}

=head2 get_file_data

Get binary file data from a directory entry at the specified position:

  my $data = $d64DiskDirObj->get_file_data($index);

Reads data from a file at the specified directory index position (index value must be a valid position equal or greater than 0 and less than number of directory entries). Returns binary file data (including its loading address) upon success, and an undefined value otherwise.

=cut

sub get_file_data {
    my $self = shift;
    my $index = shift;
    $self->_check_dir_read();
    my $entryObj = $self->get_entry($index);
    unless (defined $entryObj) {
        carp "Unable to get file data from an inexisting directory entry (validate first that ${index} file(s) really exist(s) on this disk!)";
        return undef;
    }
    my $d64DiskImageObj = $self->{'D64_DISK_IMAGE'};
    # Get filename from the specified directory index position:
    my $name = $entryObj->get_name(0);
    my $rawname = D64::Disk::Image->rawname_from_name($name);
    # Get the actual filetype:
    my $type = $entryObj->get_type();
    my $filetype = $file_type_constants{$type};
    # Open a file for reading:
    my $prg = $d64DiskImageObj->open($rawname, $filetype, F_READ);
    # Read data from file:
    my ($counter, $buffer) = $prg->read();
    # Close a file:
    $prg->close();
    return $buffer;
}

=head2 print_dir

Print out the entire directory content to any opened file handle (the standard output by default):

  $d64DiskDirObj->print_dir($fh);

=cut

sub print_dir {
    my $self = shift;
    my $fh = shift;
    $fh = *STDOUT unless defined $fh;
    $self->_check_dir_read();
    $self->_print_title($fh);
    my $num_entries = $self->num_entries();
    for (my $i = 0; $i < $num_entries; $i++) {
        my $entryObj = $self->get_entry($i);
        $entryObj->print_entry($fh);
    }
    $self->_print_blocks_free($fh);
}

sub _print_title {
    my $self = shift;
    my $fh = shift;
    # Get title converted to ASCII:
    my $title = $self->get_title(1);
    # Get disk ID converted to ASCII:
    my $id = $self->get_id(1);
    # Print title and disk ID:
    printf $fh "0 \"%-16s\" %s\n", $title, $id;
}

sub _print_blocks_free {
    my $self = shift;
    my $fh = shift;
    # Print number of blocks free:
    my $blocksFree = $self->get_blocks_free();
    printf $fh "%d blocks free\n", $blocksFree;
}

sub DESTROY {
    my $self = shift;
    $self->_release_d64_image();
}

sub _release_d64_image {
    my $self = shift;
    my $d64DiskImageObj = $self->{'D64_DISK_IMAGE'};
    delete $self->{'D64_DISK_IMAGE'};
    # Release D64 image:
    $d64DiskImageObj->free_image() if defined $d64DiskImageObj;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

L<D64::Disk::Dir::Entry>, L<D64::Disk::Dir::Iterator>, L<D64::Disk::Image>

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.03 (2013-02-16)

=head1 COPYRIGHT AND LICENSE

This module is licensed under a slightly modified BSD license, the same terms as Per Olofsson's "diskimage.c" library and L<D64::Disk::Image> Perl package it is based on, license contents are repeated below.

Copyright (c) 2003-2006, Per Olofsson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

diskimage.c website: L<http://www.paradroid.net/diskimage/>

=cut

1;
