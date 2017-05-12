package AnyData2::Storage::File;

use 5.008001;
use strict;
use warnings FATAL => 'all';

use base qw(AnyData2::Storage);

use Carp qw/croak/;
use Fcntl qw(:seek);
use IO::File ();
use Module::Runtime qw(require_module);

=head1 NAME

AnyData2::Storage::File - AnyData2 file storage

=cut

our $VERSION = '0.002';

=head1 DESCRIPTION

Base class for L<AnyData2::Storage::File::Linewise> and L<AnyData2::Storage::File::Blockwise> to handle common stuff

=head1 METHODS

=head2 new

  my $as2 = AnyData2::Storage::File->new(
    filename => "data.ext",
    filemode => "r",
    fileperms => 0644
  );

  my $as2 = AnyData2::Storage::File->new(
    filename => "data.ext",
    filemode => "<:raw"
  );

constructs a storage.

=cut

sub new
{
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new();
    defined $options{filemode} or $options{filemode} = "r";
    my @openparms = qw(filename filemode);
    unless ( $options{filemode} =~ m/^[<>]/ )
    {
        defined $options{fileperms} or $options{fileperms} = 0644;
        push @openparms, qw(fileperms);
    }
    $self->{fh} = IO::File->new( @options{@openparms} ) or die "Can't open $options{filename}: $!";
    @$self{qw(filename filemode fileperms)} = @options{qw(filename filemode fileperms)};
    $self;
}

=head2 seek

  $stor->seek(pos, whence)

Moves the storage pointer to given position. See L<IO::Seekable> for details.

=cut

sub seek
{
    my ( $self, $pos, $whence ) = @_;
    $self->{fh}->seek( $pos, $whence ) or croak "Can't seek to $pos from $whence for $self->{filename}: $!";
    "0E0";
}

=head2 truncate

  $stor->truncate

Truncates the underlying storage backend at it's current position.

=cut

sub truncate
{
    my $self = shift;
    $self->{fh}->truncate( $self->{fh}->tell() ) or die "Can't truncate $self->{filename}: $!";
}

=head2 drop

  $stor->drop

Drops the underlying storage (e.g. delete file)

=cut

sub drop
{
    my $self = shift;
    $self->{fh} and $self->{fh}->close;
    unlink $self->{filename};
}

=head2 meta

Experimental

Returns a meta storage - if any. Imaging it as an object dealing with
underlying filesystem for a file storage.

=cut

sub _build_meta
{
    my $self = shift;
    require_module("AnyData2::Format::FileSystem");
    AnyData2::Format::FileSystem->new( dirname => dirname( $self->{filename} ) );
}

sub meta
{
    my $self = shift;
    $self->{meta} or $self->{meta} = $self->_build_meta;
    $self->{meta};
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
