package Catalyst::Authentication::Credential::GSSAPI;
our $VERSION = '0.0.5';
use strict;
use warnings;

# perform_negotiation is implemented in native code.
use XSLoader;
XSLoader::load('Catalyst::Authentication::Credential::GSSAPI',$VERSION);

use MIME::Base64 ();

sub _config {
    my $self = shift;
    if (@_) {
	$self->{_config} = shift;
    }
    return $self->{_config};
}

sub realm {
    my $self = shift;
    if (@_) {
	$self->{realm} = shift;
    }
    return $self->{realm};
}

sub new {
    my ($class, $config, $app, $realm) = @_;
    $config ||= {};
    $config->{username_field} ||= 'username';
    return bless
      { _config => $config,
	realm   => $realm
      }, $class;
}

sub detach_negotiation {
    my ($self, $c) = @_;
    $c->res->status(401);
    $c->res->content_type('text/plain');
    $c->res->body("GSSAPI Authentication Required");
    die $Catalyst::DETACH;
}

sub detach_forbidden {
    my ($self, $c) = @_;
    $c->res->status(403);
    $c->res->content_type('text/plain');
    $c->res->body("Access Denied");
    die $Catalyst::DETACH;
}

my $status_codes = status_codes();
sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;
    my $headers = $c->req->headers();
    $c->res->header('WWW-Authenticate' => "Negotiate");
    my $auth = $headers->header('Authorization');
    if ($auth && $auth =~ /^Negotiate\s+(.*)$/) {
	my $token = MIME::Base64::decode_base64($1);
	if ($token) {
	    my $ret = perform_negotiation({ token => $token });
 	    if ($ret->{output_token}) {
		my $output_token =
		  MIME::Base64::encode_base64($ret->{output_token},'');
		$c->res->header('WWW-Authenticate' =>
				"Negotiate $output_token");
	    }
	    if (!$ret || $ret->{status} != 0) {
                if ($ret && $ret->{status}) {
                    if ($status_codes->{$ret->{status}}) {
                        if ($status_codes->{$ret->{status}} eq
                            'GSS_S_CONTINUE_NEEDED') {
                            $c->log->debug("GSSAPI Continue Needed");
                            # detach without reset, for continuation
                            $self->detach_negotiation($c);
                        } else {
                            $c->log->error("Failed to init GSSAPI context: ".
                                           $status_codes->{$ret->{status}});
                        }
                    } else {
                        $c->log->error("Failed to init GSSAPI context: ".
                                       "Status code: ".$ret->{status});
                    }
                } else {
                    $c->log->error("Failed to init GSSAPI context: ".
                                   "Unspecified error");
                }
                reset_negotiation();
                $self->detach_negotiation($c);
	    }
            # we now we already negotiated at this point, reset it.
            reset_negotiation();
	    if (my $client_name = $ret->{src_name}) {
		$c->log->debug("Authentication::Credential::GSSAPI: ".
			       "user is $client_name");
		if ($self->_config->{strip_realm}) {
		    $client_name =~ s/\@.+$//;
		}
		my $user = $realm->find_user
		  ({ %$authinfo,
		     $self->_config->{username_field} => $client_name });
		if ($user) {
		    return $user;
		} else {
		    $c->log->error("user $client_name not found");
		    $self->detach_forbidden($c);
		}
	    } else {
		$c->log->debug("No user in token");
		$self->detach_negotiation($c);
	    }
	} else {
	    $c->log->debug("No Valid GSSAPI token received");
            reset_negotiation();
	    $self->detach_negotiation($c);
	}
    } else {
	$c->log->debug("No GSSAPI token received");
        reset_negotiation();
	$self->detach_negotiation($c);
    }
}

1;

__END__


=head1 NAME

Catalyst::Authentication::Credential::GSSAPI - rfc4559 SPNEGO/GSSAPI

=head1 SYNOPSIS

In your application configuration:

  <authentication>
    default_realm "myrealm"
    <realms>
      <myrealm>
        <credential>
          class "GSSAPI"
        </credential>
        <store>
          class "LDAP"
          ldap_server "myrealm.mydomain.com"
          binddn "anonymous"
          bindpw "dontcarehow"
          user_basedn "OU=Users,DC=myrealm,DC=mydomain,DC=com"
          user_field "userprincipalname"
          user_filter "(userprincipalname=%s)"
          user_scope "sub"
        </store>
      </myrealm>
    </realms>
  </authentication>

On your application code:

  $c->authenticate({ });

=head1 DESCRIPTION

This module implements the HTTP negotiation described in rfc4559. The
authentication is implemented by the natively calling the gssapi from
the krb5 library. It provides only the "Credential" part of the
system. You are required to plugin a different "Storage", such as
LDAP, in order to get the data for the user info.

This allows your application to perform Single-Sign-On (SSO) if you
are in an environment with Kerberos authentication. One example of
such scenario is for environments managed with Microsoft Active
Directory.

This module will not, however, perform password-based authentication
on the Kerberos realm. It will only accept token-based negotiation
with GSSAPI.

Like L<Catalyst::Authentication::Credential::HTTP>, this module will
detach your action for the HTTP negotiation to happen and will only
return when a valid user was authenticated and retrieved from the
store.

=head1 KEYTABS AND PRINCIPALS

When implementing GSSAPI negotiation over HTTP, the convention specify
that the name of the principal for the service will always be:

  HTTP/hostname.of.the.server

Such that if the client is connecting to

  http://myservice.mydomain.com

the name of Service Principal Name (SPN) will be required to be

  HTTP/myservice.mydomain.com

The SPN needs to be registered with the kerberos server, and
application needs to be run with a keytab that contains that
principal. One way to verify that is by doing:

  $ k5srvutil -f mykeytabfile.keytab list
  Keytab name: FILE:mykeytabfile.keyttab
  KVNO Principal
  ---- --------------------------------------------------------------------
   3 serviceaccount@MYREALM.MYDOMAIN.COM
   3 HTTP/myservice.mydomain.com@MYREALM.MYDOMAIN.COM

With the MIT krb5 library, you can use the keytab by exporting the
following environment variable for the process running the
application:

  export KRB5_KTNAME=FILE:/full/path/to/mykeytabfile.keytab

That way the application will be able to participate in the
authentication.

=head1 CLIENT SIDE

The client side, of course, also has to support this negotiation.

=head2 BROWSER SUPPORT

All major browsers support this negotiation, some configuration may be
required in order to enable it.

=head2 CURL

Curl can be built with krb5 support, at which point you should be able
to use:

  curl --negotiate -u x:x http://myservice.mydomain.com

The "-u x:x" argument is necessary in order to tell curl to enable
authentication, the user name and password will not be used and can be
set to a dummy value, like "x:x".

=head1 CONFIGURATION

=over

=item username_field

This configures what field should the username be set to in the
authinfo hash. Defaults to "username".

The authentication will send the "src name" from gssapi as the user
name for the find_user call.

=item strip_realm

When using kerberos, the full principal name is returned, which is
usually in the form of user@REALM. Setting this will strip everything
after the '@' before sending it to the credential store. This is
useful if you are using a store that is not connected to the kerberos
authentication.

=back

=head1 USING WITH LDAP ON MICROSOFT ACTIVE DIRECTORY

Active Directory offers the LDAP attribute "userprincipalname" that
will match the kerberos principal used by this API. If you set the
user_field and user_filter configurations of the LDAP store, it will
seamlessly integrate and return you a valid LDAP user.

=head1 COPYRIGHT

Copyright 2015 Bloomberg Finance L.P.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.


