package Apache2::AuthenRadius;

# $Id: AuthenRadius.pm,v 1.2 2005/04/18 19:29:04 jad Exp $

use strict;
use warnings;
use vars qw($VERSION);
use Apache2::Const qw(OK HTTP_UNAUTHORIZED DECLINED HTTP_INTERNAL_SERVER_ERROR);
use Apache2::Connection;
use Apache2::RequestRec;
use Apache2::Access;
use Apache2::RequestUtil;
use Apache2::Log;
use APR::SockAddr;
use Authen::Radius;

$VERSION = '0.9';

# Create my own method to check a password
# The Authen::Radius->check_pwd method was too restrictive
# to use. We needed a function that returned all possible
# values.
sub chk_passwd {
  my ($rad, $uname, $upwd, $nas) = @_;

  $rad->clear_attributes;
  $rad->add_attributes (
			{Name => 1, Value => $uname, Type => 'string' },
			{Name => 2, Value => $upwd, Type => 'string' },
			{Name => 4, Value => $nas, Type => 'ipaddr' }
		       );

  $rad->send_packet(ACCESS_REQUEST);
  my $rcv = $rad->recv_packet();

  return($rcv);
}


sub handler {
  my $r = shift;
  
  # Continue only if the first request.
  return OK unless $r->is_initial_req();
  
  my $reqs_arr = $r->requires;
  return OK unless $reqs_arr;
  
  # Grab the password, or return if HTTP_UNAUTHORIZED
  my($res,$pass) = $r->get_basic_auth_pw;
  return $res if $res;
  
  # Get the user name.
  my $user = $r->user;
  
  # Primary Radius Server and port.
  my $host1    = $r->dir_config("Auth_Radius_host1") or return DECLINED;
  my $port1    = $r->dir_config("Auth_Radius_port1") || 1647;
  
  # Shared secret for the primary host we are running on.
  my $secret1  = $r->dir_config("Auth_Radius_secret1") or return DECLINED;
  
  # Secondary Radius Server and port.
  my $host2   = $r->dir_config("Auth_Radius_host2");
  my $port2    = $r->dir_config("Auth_Radius_port2") || 1647;
  
  # Shared secret for the secondary host we are running on.
  my $secret2  = $r->dir_config("Auth_Radius_secret2");
  
  # Timeout to wait for a response from the radius server.
  my $timeout = $r->dir_config("Auth_Radius_timeout") || 5;
  
  # Sanity for usernames and passwords.
  if (length $user > 64 or $user =~ /[^A-Za-z0-9\@\.\-\_\#\:]/) {
    $r->log_reason("Apache2::AuthenRadius username too long or"
		   ."contains illegal characters. URI:", $r->uri);
    $r->note_basic_auth_failure;
    return HTTP_UNAUTHORIZED;
  }

  # Prepend realm if set
  if ($r->dir_config("Auth_Radius_prependToUsername")) {
    $user = $r->dir_config("Auth_Radius_prependToUsername") . $user;
  }

  # Postfix realm if set
  if ($r->dir_config("Auth_Radius_postfixToUsername")) {
    $user .= $r->dir_config("Auth_Radius_postfixToUsername");
  }

  if (length $pass > 256) {
    $r->log_reason("Apache2::AuthenRadius password too long. URI:",$r->uri);
    $r->note_basic_auth_failure;
    return HTTP_UNAUTHORIZED;
  }
  
  # Create the object for the primary RADIUS query
  my $radius = Authen::Radius->new(
				   Host => "$host1:$port1",
				   Secret => $secret1,
				   TimeOut => $timeout
				  );

  # Fail if we can't create object for primary 
  # RADIUS server  
  if (!defined $radius) {
    $r->log_reason("Apache2::AuthenRadius failed to"
		   ."create object for $host1:$port1. URI:",$r->uri);	  
    return HTTP_INTERNAL_SERVER_ERROR;
  }
  
  # Get my IP address to pass as the
  # NAS IP Address
  my $c = $r->connection;
  my $sockaddr = $c->local_addr;
  my $nas_ip_address = $sockaddr->ip_get;
  
  # Check with the primary RADIUS server.
  my $access = chk_passwd($radius,$user,$pass,$nas_ip_address);
  if ($access == ACCESS_ACCEPT) {
    # Good ... we're in
    return OK;
  } elsif ($access == ACCESS_REJECT) {
    # Sorry, you can't get in
    $r->log_reason("Apache2::AuthenRadius failed for user $user. URI:",
		   $r->uri);
    $r->note_basic_auth_failure;
    return HTTP_UNAUTHORIZED;
  } elsif (!defined($access)) {
    # We didn't get a response from the primary
    # server so let's move on to the secondary
    $r->log_reason("Apache2::AuthenRadius failed to "
		   ."connect to $host1:$port1 will try $host2:$port2. URI:",$r->uri);	  
    # Create a new object for the secondary
    # server
    my $radius2 = Authen::Radius->new(
				      Host => "$host2:$port2",
				      Secret => $secret2,
				      TimeOut => $timeout
				     );
    # Fail if we can't create object for secondary 
    # RADIUS server
    if (!defined $radius2) {
      $r->log_reason("Apache2::AuthenRadius failed to"
		     ."create object for $host2:$port2. URI:",$r->uri);	  
      return HTTP_INTERNAL_SERVER_ERROR;
    }
    # Check with the secondary server
    my $access = chk_passwd($radius2,$user,$pass,$nas_ip_address);
    if ($access == ACCESS_ACCEPT) {
      # Good ... we're in
      return OK;
    } elsif ($access == ACCESS_REJECT) {
      # Sorry, you can't get in
      $r->log_reason("Apache2::AuthenRadius failed for user $user. URI:",
		     $r->uri);
      $r->note_basic_auth_failure;
      return HTTP_UNAUTHORIZED;
    } elsif (!defined($access)) {
      # We didn't get a response from the secondary
      # server either
      $r->log_reason("Apache2::AuthenRadius failed to "
		   ."connect to $host2:$port2. URI:",$r->uri);	  
      return HTTP_INTERNAL_SERVER_ERROR;
    } 
  } 
}

1;

__END__

=head1 NAME

Apache2::AuthenRadius - Authentication via a Radius server

=head1 SYNOPSIS

 # Configuration in httpd.conf

 PerlModule Apache2::AuthenRadius

 # Authentication in .htaccess

 AuthName Radius
 AuthType Basic

 # authenticate via Radius
 PerlAuthenHandler Apache2::AuthenRadius

 PerlSetVar Auth_Radius_host1 radius1.foo.com
 PerlSetVar Auth_Radius_port1 1812
 PerlSetVar Auth_Radius_secret1 MySharedSecret
 PerlSetVar Auth_Radius_host2 radius2.foo.com
 PerlSetVar Auth_Radius_port2 1812
 PerlSetVar Auth_Radius_secret2 MySharedSecret
 PerlSetVar Auth_Radius_timeout 5
 PerlSetVar Auth_Radius_prependToUsername REALM/
 PerlSetVar Auth_Radius_postfixToUsername @REALM

 require valid-user

=head1 DESCRIPTION

This module allows authentication against a Radius server.

=head1 LIST OF TOKENS

=item *
Auth_Radius_hostN

The Radius server host: either its name or its dotted quad IP number.
The parameter is passed as the PeerHost option to IO::Socket::INET->new.
You can have up to 2 RADIUS hosts configured, each with it own port &
secret parameters.

=item *
Auth_Radius_portN

The port on which the Radius server is listening: either its service
name or its actual port number. This parameter defaults to "1647"
which is the official service name for Radius servers. The parameter
is passed as the PeerPort option to IO::Socket::INET->new.

=item *
Auth_Radius_secretN

The shared secret for connection to the Radius server.

=item *
Auth_Radius_timeout

The timeout in seconds to wait for a response from the Radius server.

=item *
Auth_Radius_prependToUsername

Prefix's a string to the beginning of the user name that is sent to
the Radius Server. This would typically be in the form of REALM/ or
REALM%. Most Radius servers support prefixed or suffixed realms and
so allow for different user name  / password lists.

You can both postfix and prefix a realm at the same time.  Your
radius server might not deal with it very well.

=item *
Auth_Radius_postfixToUsername

Postfix's a string to the end of the user name that is sent to
the Radius Server. This would typically be in the form of @REALM or
%REALM. Most Radius servers support prefixed or suffixed realms and
so allow for different user name  / password lists.

You can both postfix and prefix a realm at the same time.  Your
radius server might not deal with it very well.

=head1 CONFIGURATION

The module should be loaded upon startup of the Apache daemon.
Add the following line to your httpd.conf:

 PerlModule Apache2::AuthenRadius

=head1 PREREQUISITES

For AuthenRadius you need to enable the appropriate call-back hook 
when making mod_perl: 

  perl Makefile.PL PERL_AUTHEN=1

=head1 SEE ALSO

L<Apache>, L<mod_perl>, L<Authen::Radius>

=head1 AUTHORS

=item *
mod_perl by Doug MacEachern <dougm@osf.org>

=item *
Authen::Radius by Carl Declerck <carl@miskatonic.inbe.net>

=item *
Apache::AuthenRadius by Daniel Sully <daniel-cpan-authenradius@electricrain.com>

=item *
Apache2::AuthenRadius 0.4 modified from original Apache::AuthenRadius 
by Jose Dominguez <jad@ns.uoregon.edu>

=head1 COPYRIGHT

The Apache2::AuthenRadius module is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
