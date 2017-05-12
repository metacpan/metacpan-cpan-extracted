#  You may distribute under the terms of either the GNU General Public License
#  or the Artistic License (the same terms as Perl itself)
#
#  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk

package App::MatrixTool::Command::client::login;

use strict;
use warnings;
use base qw( App::MatrixTool::Command::client );

our $VERSION = '0.08';

use constant DESCRIPTION => "Obtain a client authentication token";
use constant ARGUMENTS => ( "user", "password?" );
use constant OPTIONS => ();

=head1 NAME

matrixtool client login - Obtain a client authentication token

=head1 SYNOPSIS

   $ matrixtool client login @me:example.com

=head1 DESCRIPTION

This command performs the C</login> steps of the Matrix client API, obtaining
an access token for the given user ID. This requires a password - either
provided on the commandline as a second argument, or requested interactively
on the terminal.

Once the access token is obtained it is stored in the token cache, which lives
in F<$HOME/.matrix/client-tokens>. This cache will be consulted by other
C<matrixtool client> sub-commands to automatically provide the access token if
required.

Note that the interactive terminal method requires the optional dependency of
L<IO::Termios> to be installed, so that local echo can temporarily be disabled
while the user types in the password.

=cut

sub run
{
   my $self = shift;
   my ( $opts, $user, $password ) = @_;

   $self->{user_id} = $user;

   if( !defined $password ) {
      require IO::Termios;
      my $stdin = IO::Termios->new( \*STDIN );

      STDOUT->autoflush(1);
      print "Password: ";

      $stdin->setflag_echo( 0 );
      $password = <$stdin>; chomp $password; print "\n";
      $stdin->setflag_echo( 1 );
   }

   $self->do_json( POST => "/_matrix/client/r0/login",
      content => {
         type => "m.login.password",
         user => $user,
         password => $password,
      }
   )->then( sub {
      my ( $body ) = @_;

      $self->client_token_store->put(
         server => $self->{server},
         id     => $user,
         data   => $body->{access_token},
      );

      $self->output_ok( "Obtained access token" );

      Future->done();
   });
}

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut

0x55AA;
