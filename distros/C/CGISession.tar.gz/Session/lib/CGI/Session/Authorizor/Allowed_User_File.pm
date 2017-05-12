#!/usr/local/bin/perl5
#

package CGI::Session::Authorizor::Allowed_User_File;

use Carp;

my %_params = ( -file => '-file' );

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

sub file { set( shift(), '-file', @_ ); }
sub port { set( shift(), '-port', @_ ); }
sub bind { set( shift(), '-bind', @_ ); }

# Check restricted access file if the restricted access
# switch has been set.
#
sub authorized
  {
    my ( $self, $params ) = @_;
    my $username = $params->{-username};
    my $found_flag = 0;

    my $result = CORE::open(RA_FD, $self->file);
    if(!defined($result))
      {
        carp "Could not open allowed access file\n";
        return 0;
      }
    else
      {
        while(my $line = <RA_FD>)
          {
            chomp $line;
            if($line eq $username) {
              $found_flag++;
              last;
            }
          }
      }
    if(!$found_flag)
      {
        close(RA_FD);
        return 0;
      }
    return 1;
  }



=item CGI::Session::Authenticator::LDAP

An LDAP authenticator.  Use Mozilla::LDAP.

$auth = new CGI::Session::Authenticator( -host => $host,
                                         -port => $port,
                                         -bind => 'uid=$username,ou=People,dc=mycorp,dc=com' );

if ( $auth->authenticated( $param ) ) { ...success... }
else { ...failure... }

=item CGI::Session::Authenticator::authenticated

It accepts on argument which is a reference to a hash.  This hash contains
variables which are used to attempt authentication.

The standard values which are used for comparison.  The basic ones are
'-username' and '-password'.

It returns a true value if the user was successfully authenticated, and a
false value if the user was not successfully authenticated.

=cut


1;
