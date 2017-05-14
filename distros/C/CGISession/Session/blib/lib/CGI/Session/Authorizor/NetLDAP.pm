#!/usr/local/bin/perl5
#

package CGI::Session::Authorizor::NetLDAP;

use Carp;
use Net::LDAP;

my %_params = ( -host => '-host',
                -port => '-port',
                -bind => '-bind',
                -user => '-user',
                -userdn => '-userdn',
                -group => '-group',
                -groupdn => '-groupdn',
                -cafile => '-cafile',
                -capath => '-capath',
                -ciphers => '-ciphers', );

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

sub host { set( shift(), '-host', @_ ); }
sub port { set( shift(), '-port', @_ ); }
sub groupdn { set( shift(), '-groupdn', @_ ); }
sub userdn { set( shift(), '-userdn', @_ ); }
sub cafile { set( shift(), '-cafile', @_ ); }
sub capath { set( shift(), '-capath', @_ ); }
sub ciphers { set( shift(), '-ciphers', @_ ); }

sub authorized
  {
    my ( $self, $auth_token ) = @_;
    my $password = $auth_token->{-password};
    my $username = $auth_token->{-username};
    my $group = $auth_token->{-group};
    $username = defined $username ? $username : "";
    $group = defined $group ? $group : "";
    my %ld = Mozilla::LDAP::Utils::ldapArgs();
    my $host = $self->host();
    my $port = $self->port();
    my $userdn = $self->userdn();
    $userdn =~ s/\$username/$username/g;

    # Make groups to search.
    #
    my @startdns;
    if ( $auth_token->{-groupdn} )
      {
        @startdns = @{ $auth_token->{$groupdn} };
      }
    else
      {
        @startdns = @{ $self->{$groupdn} };
        foreach my $group ( @{$self->{$groupdn}} )
          {
            @startdns = map { s/\$username/$username/g; s/\$group/$group/g; } @startdns;
          }
      }

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

    my $connection = new Mozilla::LDAP::Conn( $host, $port );
    my $visited = {};
    foreach my $dn ( @startdns )
      {
        return 1 if contained_in( $connection, $visited, $dn, lc($userdn) );
      }
    $connection->unbind();

    return $contians;
  }


sub contained_in
  {
    my ( $connection, $visited, $currentdn, $userdn ) = @_;
    return 1 if $visited{$currentdn};
    $visited->{$group}++;
    return 1 if $userdn eq lc($currentdn);
    my $entries = $connection->search( base=>$currentdn,
                                       filter=>'(objectclass=groupofuniquenames)',
                                       scope=>'base',
                                       attrs=>[ 'objectclass', 'dn', 'uniquemember' ] );
    return 0 if $entries->code != LDAP_SUCCESS;
    my $entry = $entries->pop_entry;
    return 0 unless $entry;
    return 0 unless $entry->exists( 'uniquemember' );
    foreach my $member ( $entry->get_value( 'uniquemember' ) )
      {
        return 1 if contained_in( $connection, $visited, $member, $userdn );
      }
    return 0;
  }




=item CGI::Session::Authorizor::NetLDAP

An LDAP authorization module using Net::LDAP;

$auth = new CGI::Session::Authorizor::NetLDAP( -host => $host,
                                               -port => $port,
                                               -groupdn => 'cn=$group,ou=Groups,dc=mycorp,dc=com' );

if ( $auth->authorized( $auth_token ) ) { ...success... }
else { ...failure... }

=item CGI::Session::Authorizor::NetLDAP;

It accepts on argument which is a reference to a hash.  This hash contains
variables which are used to attempt authentication.

The standard values which are used for comparison.  The basic ones are
'-username' and '-password'.

It returns a true value if the user was successfully authenticated, and a
false value if the user was not successfully authenticated.

=cut


1;
