package AnyData2::Format::FileSystem;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base qw(AnyData2::Format);

use Carp 'croak';
use File::Spec ();

=head1 NAME

AnyData2::Format::FileSystem - FileSystem format class for AnyData2

=cut

our $VERSION = '0.002';

=head1 METHODS

=head2 new

  # pure
  my $af = AnyData2::Format::FileSystem->new(
    AnyData2::Storage::FileSystem->new( dirname => $ENV{HOME} )
  );

constructs a filesystem format

=cut

sub new
{
    my ( $class, $storage, %options ) = @_;
    my $self = $class->SUPER::new($storage);

    $self->{fs_cols} = [qw(entry dev ino mode nlink uid gid rdev size atime mtime ctime blksize blocks)];

    $self;
}

=head2 cols

Return column names

=cut

sub cols
{
    my $self = shift;
    defined $self->{fs_cols} or croak "Should not been here ...";
    $self->{fs_cols};
}

=head2 fetchrow

Fetch next directory entry and return name and stat values

=cut

sub fetchrow
{
    my $self  = shift;
    my $entry = $self->{storage}->read();
    defined $entry or return;
    my $fqpn = File::Spec->catfile( $self->{storage}->{dirname}, $entry );
    [ $entry, stat $fqpn ];
}

=head2 pushrow

No idea how this can be reasonable implemented

=cut

sub pushrow
{
    croak "read-only format ...";
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

