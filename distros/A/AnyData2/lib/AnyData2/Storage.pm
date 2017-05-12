package AnyData2::Storage;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use Carp 'croak';

=head1 NAME

AnyData2::Storage - AnyData2 storage base class

=cut

our $VERSION = '0.002';

=head1 METHODS

AnyData2::Storage is intended to handle the data I/O for L<AnyData2::Format>s.
Thus implies, an C<AnyData2::Format> instance has requirements for it's
storage backend. Not every tuple might work well together.

=head2 new

constructs a storage.

=cut

sub new
{
    my ($class) = @_;
    bless {}, $class;
}

=head2 read

  my $buf = $stor->read(<characters>)

Use binmode for characters as synonymous for bytes.

=cut

sub read
{
    croak "missing overwritten method";
}

=head2 write

  $stor->write($buf)

Writes the buf out

=cut

sub write
{
    croak "missing overwritten method";
}

=head2 seek

  $stor->seek(pos,whence)

Moves the storage pointer to given position

=cut

sub seek
{
    croak "missing overwritten method";
}

=head2 truncate

  $stor->truncate

Truncates the underlying storage backend at it's current position.

=cut

sub truncate
{
    croak "missing overwritten method";
}

=head2 drop

  $stor->drop

Drops the underlying storage (e.g. delete file)

=cut

sub drop
{
    croak "missing overwritten method";
}

=head2 meta

Experimental

Returns a meta storage - if any. Imaging it as an object dealing with
underlying filesystem for a file storage.

=cut

sub meta
{
    croak "missing overwritten method";
}

=head1 LICENSE AND COPYRIGHT

Copyright 2015,2016 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
