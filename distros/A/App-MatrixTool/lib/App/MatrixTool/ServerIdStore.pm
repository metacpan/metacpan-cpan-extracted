#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2015 -- leonerd@leonerd.org.uk

package App::MatrixTool::ServerIdStore;

use strict;
use warnings;

our $VERSION = '0.08';

use Errno qw( ENOENT );
use File::Basename qw( dirname );
use File::Path qw( make_path );
use MIME::Base64 qw( encode_base64 decode_base64 );

=head1 NAME

C<App::MatrixTool::ServerIdStore> - storage keyed by server name and an ID

=head1 DESCRIPTION

Provides a simple flat-file database that stores data keyed by a remote server
name and ID field. This is persisted in a human-readable file.

=cut

sub new
{
   my $class = shift;
   my %args = @_;

   return bless {
      path => $args{path},
      data => {},
      encode => $args{encode} // "base64",
   }, $class;
}

=head1 METHODS

=cut

sub _open_file
{
   my $self = shift;
   my ( $mode ) = @_;

   my $path = $self->{path};

   if( $mode eq ">>" and not -f $path ) {
      make_path( dirname( $path ) );
   }

   if( open my $fh, $mode, $path ) {
      return $fh;
   }

   return undef if $! == ENOENT and $mode eq "<";
   die "Cannot open $path - $!\n";
}

sub _read_file
{
   my $self = shift;
   return if $self->{have_read};

   if( my $fh = $self->_open_file( "<" ) ) {
      while( <$fh> ) {
         m/^\s*#/ and next; # ignore comment lines
         my ( $server, $id, $key ) = split m/\s+/, $_;

         defined $key or warn( "Unable to parse line $_" ), next;

         $self->{data}{$server}{$id} = $self->_decode( $key );
      }
   }

   $self->{have_read}++;
}

sub _encode
{
   my $self = shift;
   return encode_base64( $_[0], "" ) if $self->{encode} eq "base64";
   return $_[0];
}

sub _decode
{
   my $self = shift;
   return decode_base64( $_[0] ) if $self->{encode} eq "base64";
   return $_[0];
}

=head2 list

   %id_data = $store->list( server => $name )

Returns a kvlist associating IDs to byte strings of data stored for the given
server.

=cut

sub list
{
   my $self = shift;
   my %args = @_;

   my $server = $args{server};
   $self->_read_file;

   my %ret;
   foreach my $id ( keys %{ $self->{data}{$server} } ) {
      $ret{$id} = $self->{data}{$server}{$id};
   }

   return %ret;
}

=head2 get

   $key = $store->get( server => $name, id => $id )

Returns a byte string associated with the given server and ID, or C<undef> if
no such is known.

=cut

sub get
{
   my $self = shift;
   my %args = @_;

   my $server = $args{server};
   my $id     = $args{id};
   $self->_read_file;

   return unless $self->{data}{$server};
   return $self->{data}{$server}{$id};
}

=head2 put

   $store->put( server => $name, id => $id, data => $bytes )

Stores a byte string associated with the server and ID.

=cut

sub put
{
   my $self = shift;
   my %args = @_;

   my $server = $args{server};
   my $id     = $args{id};

   if( exists $self->{data}{$server}{$id} ) {
      return if $self->{data}{$server}{$id} eq $args{data};
      warn "ServerIdStore is overwriting a key with a different value!\n";
   }

   my $fh = $self->_open_file( ">>" );
   $fh->print( "$server $id " . $self->_encode( $args{data} ) . "\n" );

   $self->{data}{$server}{$id} = $args{data};
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
