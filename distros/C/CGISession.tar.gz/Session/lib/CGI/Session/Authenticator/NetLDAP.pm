#!/usr/local/bin/perl5
#

package CGI::Session::Authenticator::NetLDAP;

use Carp;
use Net::LDAP qw(:all);



my %_params = ( -host => '-host',
                -port => '-port',
                -bind => '-bind',
                -cafile => '-cafile',
                -capath => '-capath',
                -ciphers => '-ciphers', );

sub _param
  {
    my $self = shift;
    if ( scalar @_ == 1 )
      {
	my $field = shift;

	# Hack for db types.
	#
	if ( $field eq '-use_mysql' ) { return $db_type eq $DB_MYSQL; } 
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

	    # Hack for db types
	    #
	    if ( $field eq '-use_mysql' ) { $self->use_mysql if shift; return; }   
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

sub host { set( shift(), '-host', @_ ); }
sub port { set( shift(), '-port', @_ ); }
sub bind { set( shift(), '-bind', @_ ); }
sub cafile { set( shift(), '-cafile', @_ ); }
sub capath { set( shift(), '-capath', @_ ); }
sub ciphers { set( shift(), '-ciphers', @_ ); }

sub authenticated
  {
    my ( $self, $params ) = @_;
    my $password = $params->{-password};
    my $username = $params->{-username};

    $username = defined $username ? $username : "";

    my $host = $self->host();
    my $port = $self->port() ? $self->port : 389 ;
    my $bind = $self->bind();

    $bind =~ s/\$username/$username/g;

    my $connection = new Net::LDAP( $host, port=> $port );

    # Handle SSL if neccessary.
    #
    my $cafile = $self->cafile();
    my $capath = $self->capath();
    my $ciphers = $self->ciphers();
    if ( $cafile or $capath )
      {
        my %tls_args = ( verify=>'require' );
        $tls_args{cafile} = $cafile if $cafile;
        $tls_args{capath} = $capath if $capath;
        $tls_args{ciphers} = $ciphers if $ciphers;
        my $result = $connection->start_tls( %tls_args );
      }

    $result = $connection->bind( $bind, password=>$password );

    if ( $result->code eq LDAP_SUCCESS )
      {
        $connection->unbind();
        return 1;
      }
    $connection->unbind();
    return 0;
  }


=item CGI::Session::Authenticator::NetLDAP

An LDAP authenticator.  Uses Net::LDAP;

$auth = new CGI::Session::Authenticator::NetLdap( -host => $host,
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
