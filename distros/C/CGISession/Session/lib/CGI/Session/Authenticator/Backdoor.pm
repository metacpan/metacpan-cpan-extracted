#!/usr/local/bin/perl5
#

package CGI::Session::Authenticator::Backdoor;

use Carp;

my %_params = ( -password => '-password' );

sub _param
  {
    my $self = shift;
    if ( scalar @_ == 1 )
      {
	my $field = shift;

	#
	my $slot = $_params{$field};
	croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	return $self->{$slot};
      }
    else
      {
	while( my $field = shift )
	  {
	    my $slot = $_params{$field};

	    #
	    croak "Programmer Error: $field is not a known parameter" unless defined $slot;
	    $self->{$slot} = shift;
	  }
      }
  }

sub set { _param(shift,@_); }

sub new
  {
    my $type = shift;
    my $self = {};
    bless $self, $type;
    $self->set( @_ );
    return $self;
  }

sub password { set( shift(), '-password', @_ ); }

sub authenticated
  {
    my ( $self, $params ) = @_;
    my $password = $params->{-password};
    my $backdoor_password = $self->password;
    return ( $password eq $backdoor_password );
  }


=item CGI::Session::Authenticator::Backdoor

Authenticator implementing a backdoor password.

$auth = new CGI::Session::Authenticator( -password => $password );

if ( $auth->authenticated( $param ) ) { ...success... }
else { ...failure... }

Returns true if the users's password matches the -password parameter.

=item CGI::Session::Authenticator::authenticated

It accepts on argument which is a reference to a hash.  This hash contains
variables which are used to attempt authentication.

The standard values which are used for comparison.  The basic ones are
'-username' and '-password'.

It returns a true value if the user was successfully authenticated, and a
false value if the user was not successfully authenticated.

=cut

1;
