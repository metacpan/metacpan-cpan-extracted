package AnyData2::Storage::File::Blockwise;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base qw(AnyData2::Storage::File);

use Fcntl qw(:seek);
use IO::File ();

=head1 NAME

AnyData2::Storage::File::Blockwise - AnyData2 block oriented file storage

=cut

our $VERSION = '0.002';

=head1 METHODS

=head2 new

  my $as2 = AnyData2::Storage::File::Blockwise->new(
    filename  => "data.ext",
    filemode  => "<:raw",
    blocksize => 512
  );

constructs a storage.

=cut

sub new
{
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new(%options);
    @$self{qw(blocksize)} = @options{qw(blocksize)};
    $self;
}

=head2 read

  my $buf = $stor->read(<characters>)

Use binmode for characters as synonymous for bytes.

=cut

sub read
{
    my $self = shift;
    my $buf;
    my $rc = $self->{fh}->sysread( $buf, $self->{blocksize} );
    defined $rc or die "Error reading from $$self->{filename}: $!";
    $rc or return;
    $rc > 0 and $rc < $self->{blocksize} and die "Read only $rc bytes from $self->{filename} instead of $self->{blocksize}";
    $buf;
}

=head2 write

  $stor->write($buf)

Writes the buf out

=cut

sub write
{
    my ( $self, $buf ) = @_;
    my $rc = $self->{fh}->syswrite( $buf, $self->{blocksize} );
    defined $rc or die "Error writing to $self->{filename}: $!";
    $rc > 0 and $rc < $self->{blocksize} and die "Wrote only $rc bytes into $self->{filename} instead of $self->{blocksize}";
    "0E0";
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
