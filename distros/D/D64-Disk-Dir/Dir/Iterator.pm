package D64::Disk::Dir::Iterator;

=head1 NAME

D64::Disk::Dir::Iterator - Iterating through Commodore (D64/D71/D81) disk image directory entries

=head1 SYNOPSIS

  use D64::Disk::Dir::Iterator;

  # Create an iterator with a directory object instance:
  my $iter = D64::Disk::Dir::Iterator->new($d64DiskDirObj);

  # Perlish style iterator:
  while (my $entry = $iter->getNext()) {
    # ...do something with $entry...
  }

  # C++-ish style iterator:
  for (my $iter = D64::Disk::Dir::Iterator->new($d64DiskDirObj); $iter->hasNext(); $iter->next()) {
    my $entry = $iter->current();
    # ...do something with $entry...
  }

=head1 DESCRIPTION

This package provides an iterative method of accessing individual directory entries available within D64::Disk::Dir object instance based on a simple class for iterating over Perl arrays. See the description of L<Array::Iterator> package for a complete list of available methods and iteration process examples.

=head1 METHODS

=cut

use bytes;
use strict;
use warnings;

use base qw( Exporter Array::Iterator );
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'all'} = [];
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.03';

use Carp qw/carp croak verbose/;

=head2 new

Create an iterator with a D64::Disk::Dir object instance:

  my $iter = D64::Disk::Dir::Iterator->new($d64DiskDirObj);

=cut

sub new {
    my $this = shift;
    my $d64DiskDirObj = shift;
    croak "Not a D64::Disk::Dir object: \"$d64DiskDirObj\"" unless defined $d64DiskDirObj and $d64DiskDirObj->can("_get_dir_entries");
    my $entries = $d64DiskDirObj->_get_dir_entries();
    my $class = ref($this) || $this;
    my $self = $class->SUPER::new($entries);
    bless $self, $class;
    return $self;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace either by default or explicitly.

=head1 SEE ALSO

L<Array::Iterator>, L<D64::Disk::Dir>, L<D64::Disk::Dir::Entry>, L<D64::Disk::Image>

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
