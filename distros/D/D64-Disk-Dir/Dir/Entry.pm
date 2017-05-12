package D64::Disk::Dir::Entry;

=head1 NAME

D64::Disk::Dir::Entry - Handling individual Commodore (D64/D71/D81) disk image directory entries

=head1 SYNOPSIS

  use D64::Disk::Dir::Entry;

  # Create a new directory entry and initialize it with 30 bytes of binary data retrieved from a D64 disk image:
  my $entryObj = D64::Disk::Dir::Entry->new($bytes);

  # Get filename converted to ASCII string:
  my $convert2ascii = 1;
  my $name = $entryObj->get_name($convert2ascii);

  # Get various parameters describing detailed entry properties:
  my $type = $entryObj->get_type();
  my $track = $entryObj->get_track();
  my $sector = $entryObj->get_sector();

  # Print out a single line out of entire disk directory with the contents of this particular entry to the standard output:
  $entryObj->print_entry();

=head1 DESCRIPTION

This package provides a helper class for D64::Disk::Dir module, enabling user to handle individual directory entries in a higher-level object-oriented way.

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

our $VERSION = '0.03';

use Carp qw/carp croak verbose/;

use D64::Disk::Image qw(:all);

# File type names:
our @file_types = qw/del seq prg usr rel cbm dir ???/;

=head2 new

Create new C<D64::Disk::Dir::Entry> object and initialize it with 30 bytes of binary data describing each directory entry on a D64 disk image (or a physical disk):

  my $entryObj = D64::Disk::Dir::Entry->new($bytes);

The reason for initializing object not with 32 bytes of physical data but with 30 bytes instead is that two first bytes of each entry in a directory sector always should be $00 $00 as they are unused (except for the very first entry, in which case those bytes are still directory-wide, not entry-specific).

A valid C<D64::Disk::Dir::Entry> object is returned upon success, an undefined value otherwise.

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
    my $bytes = shift;
    # Verify valid bytes sequence:
    unless (length $bytes == 30) {
        carp 'Initializing D64::Disk::Dir::Entry object with invalid bytes sequence (exactly 30 bytes of binary data retrieved from a physical device are required to initialize it)';
        return 0;
    }
    my $convertOK = $self->_bytes_to_data($bytes);
    return 0 unless $convertOK;
    return 1;
}

sub _bytes_to_data {
    my $self = shift;
    my $bytes = shift;
    # Get file type:
    my $file_type = ord (substr $bytes, 0x00, 0x01);
    # Get the actual filetype:
    my $type = $file_type & 7;
    # Get closed flag (not set produces "*", or "splat" files):
    my $closed = $file_type & 0x80;
    # Get locked flag (set produces ">" locked files):
    my $locked = $file_type & 0x40;
    # Get track/sector location of first sector of file:
    my $track = ord (substr $bytes, 0x01, 0x01);
    my $sector = ord (substr $bytes, 0x02, 0x01);
    # Get 16 character filename (in PETASCII, padded with $A0):
    my $rawname = substr $bytes, 0x03, 0x10;
    my $name = D64::Disk::Image->name_from_rawname($rawname);
    my ($side_track, $side_sector, $record_length) = ();
    if ($file_types[$type] eq 'rel') {
        # Get track/sector location of first side-sector block (REL file only):
        $side_track = ord (substr $bytes, 0x13, 0x01);
        $side_sector = ord (substr $bytes, 0x14, 0x01);
        # Get REL file record length (REL file only, maximum value 254):
        $record_length = ord (substr $bytes, 0x15, 0x01);
    }
    # Get file size in sectors, low/high byte order ($1C+$1D*256):
    my $size = ord (substr $bytes, 0x1D, 0x01) << 8 | ord (substr $bytes, 0x1C, 0x01);
    # Store directory entry details in a hash:
    my $dirEntry = {
        'TYPE'          => $type,
        'CLOSED'        => $closed,
        'LOCKED'        => $locked,
        'TRACK'         => $track,
        'SECTOR'        => $sector,
        'NAME'          => $name,
        'SIDE_TRACK'    => $side_track,
        'SIDE_SECTOR'   => $side_sector,
        'RECORD_LENGTH' => $record_length,
        'SIZE'          => $size,
    };
    $self->{'DETAILS'} = $dirEntry;
    return 1;
}

sub _data_to_bytes {
    my $self = shift;
    my @bytes = ();
    # Get detailed file information stored within this object instance:
    my $dirEntry = $self->{'DETAILS'};
    my $type = $dirEntry->{'TYPE'};
    my $closed = $dirEntry->{'CLOSED'};
    my $locked = $dirEntry->{'LOCKED'};
    my $track = $dirEntry->{'TRACK'};
    my $sector = $dirEntry->{'SECTOR'};
    my $name = $dirEntry->{'NAME'};
    my $side_track = $dirEntry->{'SIDE_TRACK'} || 0x00;
    my $side_sector = $dirEntry->{'SIDE_SECTOR'} || 0x00;
    my $record_length = $dirEntry->{'RECORD_LENGTH'} || 0x00;
    my $size = $dirEntry->{'SIZE'};
    # Byte $00 - File type:
    $bytes[0x00] = chr ($type | ($locked ? 0x40 : 0x00) | ($closed ? 0x80 : 0x00));
    # Byte $01 - Track location of first sector of file:
    $bytes[0x01] = chr ($track);
    # Byte $02 - Sector location of first sector of file:
    $bytes[0x02] = chr ($sector);
    # Bytes $03..$12 - 16 character filename (in PETASCII, padded with $A0):
    my $rawname = D64::Disk::Image->rawname_from_name($name);
    my $i = 0x03;
    foreach my $byte (split //, $rawname) {
        $bytes[$i++] = $byte;
    }
    # Bytes $13..$14 - Track/Sector location of first side-sector block:
    $bytes[0x13] = chr ($side_track);
    $bytes[0x14] = chr ($side_sector);
    # Byte $15 - REL file record length:
    $bytes[0x15] = chr ($record_length);
    # Bytes $16..$1B - Unused
    $bytes[0x16] = chr 0x00;
    $bytes[0x17] = chr 0x00;
    $bytes[0x18] = chr 0x00;
    $bytes[0x19] = chr 0x00;
    $bytes[0x1A] = chr 0x00;
    $bytes[0x1B] = chr 0x00;
    # Bytes $1C..$1D - File size in sectors, low/high byte order ($1C+$1D*256):
    $bytes[0x1C] = chr ($size & 0xFF);
    $bytes[0x1D] = chr (($size >> 8) & 0xFF);
    my $bytes = join '', @bytes;
    return $bytes;
}

=head2 get_type

Get the actual filetype:

  my $type = $entryObj->get_type();

Returns the actual filetype as a three-letter string, the possibilities here are: "del", "seq", "prg", "usr", "rel", "cbm", "dir", and "???".

=cut

sub get_type {
    my $self = shift;
    my $type = $self->{'DETAILS'}->{'TYPE'};
    my $file_type = $file_types[$type];
    return $file_type;
}

=head2 get_closed

Get "Closed" flag (when not set produces "*", or "splat" files):

  my $closed = $entryObj->get_closed();

Returns true when "Closed" flag is set, and false otherwise.

=cut

sub get_closed {
    my $self = shift;
    my $closed = $self->{'DETAILS'}->{'CLOSED'};
    return $closed ? 1 : 0;
}

=head2 get_locked

Get "Locked" flag (when set produces ">" locked files):

  my $locked = $entryObj->get_locked();

Returns true when "Locked" flag is set, and false otherwise.

=cut

sub get_locked {
    my $self = shift;
    my $locked = $self->{'DETAILS'}->{'LOCKED'};
    return $locked ? 1 : 0;
}

=head2 get_track

Get track location of first sector of file:

  my $track = $entryObj->get_track();

=cut

sub get_track {
    my $self = shift;
    my $track = $self->{'DETAILS'}->{'TRACK'};
    return $track;
}

=head2 get_sector

Get sector location of first sector of file:

  my $sector = $entryObj->get_sector();

=cut

sub get_sector {
    my $self = shift;
    my $sector = $self->{'DETAILS'}->{'SECTOR'};
    return $sector;
}

=head2 get_name

Get 16 character filename (in PETASCII, padded with $A0):

  my $convert2ascii = 0;
  my $name = $entryObj->get_name($convert2ascii);

Get filename converted to ASCII string:

  my $convert2ascii = 1;
  my $name = $entryObj->get_name($convert2ascii);

=cut

sub get_name {
    my $self = shift;
    my $convert2ascii = shift;
    my $name = $self->{'DETAILS'}->{'NAME'};
    $name = D64::Disk::Image->petscii_to_ascii($name) if $convert2ascii;
    return $name;
}

=head2 get_side_track

Get track location of first side-sector block (relative file only):

  my $side_track = $entryObj->get_side_track();

A track location of first side-sector block is returned upon success, an undefined value otherwise.

=cut

sub get_side_track {
    my $self = shift;
    if ($self->get_type() ne 'rel') {
        carp "Unable to get track location of first side-sector block (not a REL file!)";
        return undef;
    }
    my $side_track = $self->{'DETAILS'}->{'SIDE_TRACK'};
    return $side_track;
}

=head2 get_side_sector

Get sector location of first side-sector block (relative file only):

  my $side_sector = $entryObj->get_side_sector();

A sector location of first side-sector block is returned upon success, an undefined value otherwise.

=cut

sub get_side_sector {
    my $self = shift;
    if ($self->get_type() ne 'rel') {
        carp "Unable to get sector location of first side-sector block (not a REL file!)";
        return undef;
    }
    my $side_sector = $self->{'DETAILS'}->{'SIDE_SECTOR'};
    return $side_sector;
}

=head2 get_record_length

Get relative file record length (relative file only, maximum value 254):

  my $record_length = $entryObj->get_record_length();

A relative file record length is returned upon success, an undefined value otherwise.

=cut

sub get_record_length {
    my $self = shift;
    if ($self->get_type() ne 'rel') {
        carp "Unable to get relative file record length (not a REL file!)";
        return undef;
    }
    my $record_length = $self->{'DETAILS'}->{'RECORD_LENGTH'};
    return $record_length;
}

=head2 get_size

Get file size in sectors:

  my $size = $entryObj->get_size();

The approximate filesize in bytes is <= #sectors * 254.

=cut

sub get_size {
    my $self = shift;
    my $size = $self->{'DETAILS'}->{'SIZE'};
    return $size;
}

=head2 get_bytes

Get 30 bytes of binary data that would describe this particular directory entry on a D64 disk image (or a physical disk):

  my $bytes = $entryObj->get_bytes();

=cut

sub get_bytes {
    my $self = shift;
    my $bytes = $self->_data_to_bytes();
    return $bytes;
}

=head2 print_entry

Print entry details to any opened file handle (the standard output by default):

  $entryObj->print_entry($fh);

This method is subsequently invoked for each single entry while printing an entire directory with D64::Disk::Dir module.

=cut

sub print_entry {
    my $self = shift;
    my $fh = shift;
    $fh = *STDOUT unless defined $fh;
    # Get detailed file information stored within this object instance:
    my $type = $self->get_type();
    my $closed = $self->get_closed() ? ord ' ' : ord '*';
    my $locked = $self->get_locked() ? ord '<' : ord ' ';
    my $size = $self->get_size();
    # Get filename convert to ASCII and add quotes:
    my $name = $self->get_name(1);
    my $quotename = sprintf "\"%s\"", $name;
    # Print directory entry:
    printf $fh "%-4d  %-18s%c%s%c\n", $size, $quotename, $closed, $type, $locked;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

L<D64::Disk::Dir>, L<D64::Disk::Image>

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
