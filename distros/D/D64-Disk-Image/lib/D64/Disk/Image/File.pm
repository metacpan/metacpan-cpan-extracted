package D64::Disk::Image::File;

=head1 NAME

D64::Disk::Image::File - File I/O portion of Perl interface to Per Olofsson's "diskimage.c", an ANSI C library for manipulating Commodore disk images

=head1 SYNOPSIS

  use D64::Disk::Image qw(:all);

  # Load an image from disk:
  my $d64 = D64::Disk::Image->load_image('disk.d64');

  # Write data to file:
  my $rawname = $d64->rawname_from_name('testfile');
  my $prg = $d64->open($rawname, T_PRG, F_WRITE);
  my $counter = $prg->write($buffer);
  $prg->close();

  # Read data from file:
  my $rawname = $d64->rawname_from_name('testfile');
  my $prg = $d64->open($rawname, T_PRG, F_READ);
  my ($counter, $buffer) = $prg->read();
  $prg->close();

  # Write the image to disk:
  $d64->free_image();

=head1 DESCRIPTION

Per Olofsson's "diskimage.c" is an ANSI C library for manipulating Commodore disk images. In Perl the following operations are implemented via D64::Disk::Image::File package:

=over

=item *
Open file ('$' reads directory)

=item *
Read file

=item *
Write file

=item *
Close file

=back

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use constant MAXIMUM_FILE_LENGTH => &D64::Disk::Image::D81_SIZE;

# Open mode constants:
use constant F_READ  => 'rb';
use constant F_WRITE => 'wb';

use base qw( Exporter );
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'modes'} = [ qw(&F_READ &F_WRITE) ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'modes'}} ];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.05';

use Carp qw/carp croak verbose/;

=head2 new

Create new D64::Disk::Image::File object and open file on a disk image:

  my $imageFile = D64::Disk::Image::File->new($diskImage, $rawname, $fileType, $mode);
  my $imageFile = D64::Disk::Image::File->open($diskImage, $rawname, $fileType, $mode);

Opens a file for reading or writing. Mode should be either F_READ (for reading) or F_WRITE (for writing). If '$' is given instead of the raw filename, the directory will be read. Consult D64::Disk::Image module documentation for the list of available file types. All parameters are mandatory.

=cut

sub new {
    my $this = shift;
    my $diskImage = shift;
    my $rawname = shift;
    my $fileType = shift;
    my $mode = shift;
    $diskImage = $diskImage->{'DISK_IMAGE'} unless ref $diskImage eq 'DiskImagePtr';
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    my $imageFile = di_open($diskImage, $rawname, $fileType, $mode);
    my $name = D64::Disk::Image->name_from_rawname($rawname);
    croak "Failed to open image file '${name}' in '${mode}' mode" unless defined $imageFile;
    $self->{'IMAGE_FILE'} = $imageFile;
    $self->{'WRITE_CALLED'} = $mode eq F_READ ? 1 : 0;
    return $self;
}

*open = \&new;

=head2 close

Close a file (each opened file needs to be subsequently closed to avoid memory leaks):

  $imageFile->close();

=cut

sub close {
    my $self = shift;
    my $imageFile = $self->{'IMAGE_FILE'};
    # Make sure there is no file without any content ever created (which would
    # result in uninitialized values of track/sector for this file in diskdir):
    $self->write(chr 0x00) unless $self->{'WRITE_CALLED'};
    di_close($imageFile);
}

=head2 read

Read data from file opened in F_READ mode:

  my ($counter, $buffer) = $imageFile->read($maxlength);

Reads $maxlength bytes of data into the buffer. Returns the number of bytes actually read, and the buffer with succeeding bytes of data.

=cut

sub read {
    my $self = shift;
    my $maxlength = shift || &MAXIMUM_FILE_LENGTH;
    my $imageFile = $self->{'IMAGE_FILE'};
    my ($counter, $buffer) = di_read($imageFile, $maxlength);
    return ($counter, $buffer);
}

=head2 write

Write data to file opened in F_WRITE mode:

  my $counter = $imageFile->write($buffer, $length);

Writes $length bytes of data from the $buffer. Returns the number of bytes actually written.

=cut

sub write {
    my $self = shift;
    my $buffer = shift;
    my $length = shift || length $buffer;
    my $imageFile = $self->{'IMAGE_FILE'};
    my $counter = di_write($imageFile, $buffer, $length);
    $self->{'WRITE_CALLED'} = 1;
    return $counter;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

C<D64::Disk::Image::File> exports nothing by default.

You may request the import of open mode constants (C<F_READ>, and C<F_WRITE>). Both these constants can be explicitly imported from C<D64::Disk::Image::File> by using it with ":modes" tag. All constants can be explicitly imported from C<D64::Disk::Image::File> by using it with ":all" tag.

=head1 SEE ALSO

L<D64::Disk::Image>

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.05 (2018-12-01)

=head1 COPYRIGHT AND LICENSE

diskimage.c is released under a slightly modified BSD license.

Copyright (c) 2003-2006, Per Olofsson
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

- Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
- Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

diskimage.c website: L<https://paradroid.automac.se/diskimage/>

=cut

1;
