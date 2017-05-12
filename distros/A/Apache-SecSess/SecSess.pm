#
# SecSess.pm - Perl module for Apache secure session management
#
# $Id: SecSess.pm,v 1.17 2002/05/22 05:40:33 pliam Exp $
#

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Apache::SecSess
# Copyright (c) 2001, 2002 John Pliam (pliam@atbash.com)
# This is open-source software.
# See file 'COPYING' in original distribution for complete details.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

package Apache::SecSess;
use strict;

use MIME::Base64;
use Apache::Constants qw(:common :response M_GET M_POST);
use Apache::Log;
use Apache::URI;
use Apache::SecSess::Wrapper;

use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", (q$Name: SecSess_Release_0_09 $ =~ /\d+/g));

sub new {
	my $class = shift;
	my $self = {@_};
	bless($self, $class);
	$self->_init;
}

sub _init {
	my $self = shift;

	my $wrapper = Apache::SecSess::Wrapper->new(
		file => $self->{secretFile}
	);
	unless (defined($wrapper)) { die "Cannot instantiate wrapper"; }
	$self->{wrapper} = $wrapper;

	return $self;
}

## authenticate session
sub authen ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($cred, $resp, $msg);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->authen():");

	$cred = $self->getCredentials($r);
	$resp = $self->validateCredentials($r, $cred);
	if (ref($resp)) {
		if ($msg = $resp->{message}) { $log->info($msg); }
		unless ($resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $resp->{uri});
		return REDIRECT;
	}
	return OK;
}

## authorize request
sub authz ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($req, $resp, $msg);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->authz():");

	$req = $self->getRequirements($r);
	$resp = $self->authorizeRequest($r, $req);
	if (ref($resp)) {
		if ($msg = $resp->{message}) { $log->info($msg); }
		if ($resp->{forbidden}) { return FORBIDDEN; }
		unless ($resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $resp->{uri});
		return REDIRECT;
	}
	return DECLINED;
}

## authenticate user & issue credentials
sub issue ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($resp, $msg);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->issue():");

	$resp = $self->verifyIdentity($r);
	if (ref($resp)) {
		if ($msg = $resp->{message}) { $log->info($msg); }
		if ($resp->{fill_form}) { return OK; }
		if ($resp->{auth_required}) { return AUTH_REQUIRED; }
		unless ($resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $resp->{uri});
		return REDIRECT;
	}
	$resp = $self->issueCredentials($r);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	if ($msg = $resp->{message}) { $log->info($msg); }
	unless ($resp->{uri}) { return SERVER_ERROR; }
	$r->header_out(Location => $resp->{uri});
	return REDIRECT;
}

## renew credentials
sub renew ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($cred, $resp, $msg);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->renew():");

	$cred = $self->getCredentials($r);
	$resp = $self->validateCredentials($r, $cred);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	unless ($resp->{renew}) { # make sure credentials are sufficiently fresh
		$log->warn("Timeout before renewal."); # or replay attempt?
		if ($msg = $resp->{message}) { $log->info($msg); }
		unless ($resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $resp->{uri});
		return REDIRECT;
	}
	$resp = $self->issueCredentials($r);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	if ($msg = $resp->{message}) { $log->info($msg); }
	unless ($resp->{uri}) { return SERVER_ERROR; }
	$r->header_out(Location => $resp->{uri});
	return REDIRECT;
}

## delete credentials
sub delete ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($resp, $msg);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->delete():");

	$resp = $self->deleteCredentials($r);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	if ($msg = $resp->{message}) { $log->info($msg); }
	return OK;
}

## change user ID (only for administrators)
sub changeid ($$) {
	my($self, $r) = @_;
	my $log = $r->log;
	my($cred, $resp, $msg, $uri, $uid);

	## don't perform in subrequests
	unless ($r->is_initial_req) { return OK; }

	$log->debug(ref($self), "->changeid():");

	## admin functions must be explicitly allowed in httpd.conf
	unless ($r->dir_config('SecSess::AllowRemoteAdmin') eq 'true') { 
		$log->error('Remote administration not permitted.');
		return FORBIDDEN;
	}

	## get credentials and validate them in usual way
	$cred = $self->getCredentials($r);
	$resp = $self->validateCredentials($r, $cred);
	if (ref($resp)) {
		if ($msg = $resp->{message}) { $log->info($msg); }
		unless ($resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $resp->{uri});
		return REDIRECT;
	}

	## make sure request is consistent and comes from an administrator
	$resp = $self->verifyAdminRequest($r);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	if ($msg = $resp->{message}) { $log->info($msg); }
	if ($resp->{forbidden}) { return FORBIDDEN; } # non-admin
	if ($resp->{fill_form}) { return OK; }
	unless ($uid = $resp->{newuid}) {
		unless ($uri = $resp->{uri}) { return SERVER_ERROR; }
		$r->header_out(Location => $uri);
		return REDIRECT;
	}

	## every looks good, set uid and issue new credentials
	$r->user($uid);
	$resp = $self->issueCredentials($r);
	unless (ref($resp)) { $log->error($resp); return SERVER_ERROR; } 
	if ($msg = $resp->{message}) { $log->info($msg); }
	unless ($resp->{uri}) { return SERVER_ERROR; }
	$r->header_out(Location => $resp->{uri});
	return REDIRECT;
}

#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#		Common Code: methods called from subclasses
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#

#
# constants (not sure which should be dir_config'd in future ...)
#

## tag and cookie attributes
sub authRealm { my $self = shift; return $self->{authRealm}; }
sub cookieDomain { my $self = shift; return $self->{cookieDomain}; }

## security attributes
sub minSessQOP { my $self = shift; return $self->{minSessQOP}; }
sub minAuthQOP { my $self = shift; return $self->{minAuthQOP}; }
sub sessQOP { my $self = shift; return $self->{sessQOP}; }
sub authQOP { my $self = shift; return $self->{authQOP}; }

## session expiration and timeout attributes
sub lifeTime { my $self = shift; return $self->{lifeTime}; }
sub idleTime { my $self = shift; return $self->{idleTime}; }
sub renewRate { my $self = shift; return $self->{renewRate}; }

## session states
sub authenURL { my $self = shift; return $self->{authenURL}; }
sub defaultURL { my $self = shift; return $self->{defaultURL}; }
sub timeoutURL { my $self = shift; return $self->{timeoutURL}; }
sub renewURL { my $self = shift; return $self->{renewURL}; }
sub errorURL { my $self = shift; return $self->{errorURL}; }
sub issueURL { my $self = shift; return $self->{issueURL}; }
sub chainURLS { my $self = shift; return $self->{chainURLS}; }

## admin form
sub adminURL { my $self = shift; return $self->{adminURL}; }

#
# routines
#

## validate common hash credentials from
sub validateCredentials {
	my $self = shift;
	my($r, $cred) = @_;
	my $log = $r->log;
	my($uri, $requri, $resp, $uid);

    $log->debug(ref($self), "->validateCredentials():");

	## were illegitimate credentials found?
	unless (defined($cred)) { # probably a key-change, treat as timeout
		# but possibly tampering, so log as warning
		$log->warn("Decryption Error");
		$uri = $self->timeoutURL;
		return {
			message => "Decryption failure, redirecting to '$uri'.",
			uri => "$uri?type=notvalid"
		};
	}

	## were any credentials found at all?
	unless (ref($cred)) {
		$uri =  sprintf('%s?url=%s',
			$self->authenURL,
			$self->requested_uri($r)
		);
		return {
			message => "$cred Redirecting to '$uri'",
			uri => $uri
		};
	}

	## set user id for Apache 
	$uid = $cred->{uid};
	$log->debug("Setting user ID: '$uid'.");
	$r->user($uid);
 
	## checksum is good, examine the protection qualities and freshness
	if ($resp = $self->validateQOP($r, $cred)) { return $resp; }
	if ($resp = $self->validateAge($r, $cred)) { return $resp; }

	## user authenticated
	$log->info("User '$uid' authenticated.");
	return undef;
}

## validate quality of protection
sub validateQOP {
	my $self = shift;
	my($r, $cred) = @_;
	my($uri, $requri);

	unless ($cred->{qop} >= $self->minSessQOP) {
		$uri = $self->authenURL;
		$requri = $self->requested_uri($r);
		return {
			message => "Insufficient session protection.",
			uri => "$uri?url=$requri"
		}
	}
	unless ($cred->{authqop} >= $self->minAuthQOP) {
		$uri = $self->authenURL;
		$requri = $self->requested_uri($r);
		return {
			message => "Insufficient authentication protection.",
			uri => "$uri?url=$requri"
		}
	}

	return undef;
}

## validated time stamp
sub validateAge {
	my $self = shift;
	my($r, $cred) = @_;
	my($life, $idle, $renew, $uid, $ts, $t, $uri, $requri);

	## get object timing constants
	$life =  $self->lifeTime;
	$idle =  $self->idleTime;
	$renew = $self->renewRate;

	## check times
	$uid = $cred->{uid};
	$ts = $cred->{timestamp};
	$t = time;
	$r->log->debug(sprintf(
		"validateAge(): uid = '%s', time - ts = %.02f (min):"
			. " vs renew = %d, idle = %d, life = %d",
		$uid, ($t-$ts)/60.0, $renew, $idle, $life
	));
	if ($t > $ts + 60*$life) { # hard timeout
		$uri = $self->timeoutURL;
		return {
			message => "Expired, redirecting '$uid' to '$uri?type=expire'.",
			uri => "$uri?type=expire"
		};
	}
	if ($t > $ts + 60*($idle+$renew)) { # idle timeout
		$uri = $self->timeoutURL;
		return {
			message => "Cookie idle too long '$uid'.",
			uri => "$uri?type=idle"
		};
	}
	if ($t > $ts + 60*$renew) { # renew
		$uri = $self->renewURL;
		$requri = $self->requested_uri($r);
		return {
			message => "Renewing credentials for user '$uid'.",
			renew => 'true',
			uri => "$uri?url=$requri"
		};
	}

	return undef;
}

## get requirements
sub getRequirements {
	my $self = shift;
	my($r) = @_;
	return $r->requires;
}

## authorize request
sub authorizeRequest {
	my $self = shift;
	my($r, $req) = @_;

	return undef;
}

#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# 		Utilities
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#

## extract the requested URI as base64 wrapped
sub requested_uri {
	my $self = shift;
	my($r) = @_;
	my($u, %args, $requrl);

	%args = $r->args;
	unless ($requrl = $args{url}) { # will already be wrapped
		$u = Apache::URI->parse($r);
		$requrl = $self->wrap_uri($u->unparse);
	}
	return $requrl;
}

## (un)wrap a URI, with more armor than Apache::Util::escape_uri
sub wrap_uri {
	my $self = shift;
	my($u) = @_;
	$u = encode_base64($u, '');
    $u =~ tr/\+\/\=/-._/;
	return $u;
}
sub unwrap_uri {
	my $self = shift;
	my($u) = @_;
    $u =~ tr/\-\.\_/+\/=/;
	return decode_base64($u);
}

1;

__END__

#
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# 		Man Page
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#

=head1 NAME

Apache::SecSess - Secure Apache session management library

=head1 SYNOPSIS

  In startup.pl,

    $My::obj = Apache::SecSess::Cookie::X509->new(...)

  In httpd.conf,

    <Location /protected>
      PerlAuthenHandler $My::obj->authen
      ...
    </Location>

  See section EXAMPLE below for more details.

=head1 DESCRIPTION

This package is a software library for managing HTTP and HTTPS 
session security within the Apache mod_perl framework.  It offers the 
flexibility to securely configure distributed web services, across 
multiple hosts and domains, consistent with a common security policy.

In a complex environment, there could be several Perl objects whose 
methods are specific Apache phase handlers designed to manage a user's 
session lifecycle, including: initiating, renewing and terminating the
session.  Each of these objects is an instance of some subclass of 
Apache::SecSess, which treats a particular security paradigm.

=head1 CLASS HIERARCHY

Below is a diagram of the class hierarchy

  SecSess
   `+-Cookie
    | `+--BasicAuth (for debugging)
    |  +--LoginForm
    |  +--X509
    |  +--X509PIN
    |  `--URL
    `-URL
      `---Cookie

SecSess contains (in addition to common code) all Apache phase handlers
(Currently only  PerlAuthenHandler are needed).  At this level credentials
and status are considered opaque objects. The important methods are:

->authen() Used to protect underlying resources.  Checks credentials for freshness and validity.

->issue()  Used as the "initial" identity authentication before issuing credentials (cookies or mangled URLs) used by ->authen().

->renew()  Will re-issue credentials if proper conditions are satisfied

->delete() Will delete credentials where relevant (i.e. deletes cookies).

At one level beneath SecSess (SecSess::Cookie.pm and SecSess::URL.pm),
are the methods for interpreting and manipulating credentials.

At the lowest level, are subclasses which "know" how to interpret the
*initial* identifying information during the issuance of credentials.
So, *::Cookie::LoginForm presents the client with a user/password
login form for identification.  And thus the difference between 
*::Cookie::URL and *::URL::Cookie is that the former will issue cookies
after validating an URL credential, and the latter will "issue" an URL
credential (typically it will redirect to a resource with realm=cred in
the URL) after validating a cookie.

=head1 CREDENTIAL FORMAT

Credentials in Apache::SecSess have a similar format:

    URL Credentials (defined in Apache::SecSess::URL):
        realm=E_k(md5(hash),hash)

    Cookie Credentials: (defined in Apache::SecSess::Cookie):
        realm:qop,authqop=E_k(md5(hash),hash)

The string 'realm' is any symbol (without obvious special characters 
':', '=', etc) which is used to identify cooperating security services,
thus providing a way to put credentials into their own namespace.
The 'hash' is a string representation of a Perl hash of the form:

    hash = {uid => str, timestamp => int, qop => int, authqop => int}

See README and Wrapper.pm for further details.

=head1 ARGUMENTS

=head2 Credential Arguments

  authRealm => <realm>

Defines string 'realm' as identifying tag for credentials as described
above in CREDENTIAL FORMAT.

  secretFile => <filename>

The first line of this file is used to create the secret encryption 
key for credentials as described above in CREDENTIAL FORMAT.  This
secret key is never given to users and should never leave the system
servers.

=head2 Timing Arguments

  lifeTime => <minutes>

Session will expire after the specified number of minutes.

  idleTime => <minutes> 

A session idle for the specified number of minutes will time out.

  renewRate => <minutes>

A session which is constantly active will have a transparent
renewal (resetting an implicit 'idle timer') every period of the 
specified number of minutes.

=head2 Quality of Protection Arguments

minSessQOP => 128, minAuthQOP => 128, authQOP => 128, sessQOP => 128

When credentials are validated during a request, two checks of the 
qualities of protection (QOP's) are made, namely that

        qop >= minSessQOP
and 
        authqop >= minAuthQOP

where qop and authqop indicate the session and user authentication 
protection or strength roughly measured in bits.  They are the signed 
values appearing *inside* the credential hash described above.  In the 
case of cookies, where multiple credentials with different security 
levels are may be present at request time, only the strongest credentials 
are used to make this determination.  (The cleartext pairs (qop,authqop) 
are sorted lexicographically to determine which cookies to use.  The
cleartext values are not trusted.)
  
The QOP parameters are separated to allow flexibility in the threat model.
In the simplest paradigm (and first demo examples), qop=0 and authqop=40, 
which merely indicates that the user ID's and passwords are protected with 
SSL but the web docs acquired with them are not.  This is somewhat common 
over intranets.  Under the stronger threat model of an active adversary
who controls the untrusted network, true end-to-end security is 
required, but we may still wish to separate session and authentication 
qualities of protection.  For example, if all SSL sessions never drop
below 128-bits, we may still choose to allow weaker strength during user 
authentication, say with a 20-bit PIN or one-time password.  Scientific 
cryptography cannot always afford to distinguish between an attack which 
costs 2^20 computations and one which succeeds with probability 1/2^20, 
because with 1 million users, the two situations are identical.  But, for
practical risk assessment, it may be perfectly acceptable to trade strong
session credentials for weak login credentials.

The values of qop and authqop issued are determined by the
Apache::SecSess object in all cases.  For URL credentials they come
directly from arguments sessQOP and authQOP, respectively.  For cookie
credentials, they come from the hash keys of the argument cookieDomain
described below.
 
Note that no attempt is made to check the correctness of the QOP
settings against the values of the httpd.conf directive SSLCipherSuite.
This would be mistake in fact because the session strength is dependent
on global factors as described in README.  Nevertheless, you should 
check your assumptions about your local site's openssl with the script 
utils/minstren which prints the weakest cipher strength for common 
SSLCipherSuite arguments.  At my site, I was surprised to find 
ALL:!ADH:!EXP:!EXP56 => 56 bits.

=head2 Cookie Domain Argument

  cookieDomain => <hashref>

The cookieDomain argument expects a hash reference of the form:

        { 'qop,authqop' => 'domain_string', ...  }

where 'domain_string' is literally the HTTP Set-Cookie domain string, and 
where the integers 'qop' and 'authqop' serve to define the session and 
authentication qualities of protections as described above.  A cookie will
be issued with the given domain and of the given strengths for each entry
in this hash.  The HTTP Set-Cookie secure flag is set if and only if 'qop' 
is nonzero.  As a convenient shorthand,

        int => 'domain_string'

is equivalent to

        'int,int' => 'domain_string'

Here are some examples taken from the demo.

      cookieDomain => {0 => '.acme.com', 40 => '.acme.com'}

will set two cookies for the .acme.com domain: a non-secure one of
form 'realm:0,0=value', and a secure one of form 'realm:40,40=value'.

      cookieDomain => {'0,40' => 'lysander.acme.com'}

will set a single non-secure cookie for the given host.  This is a
common paradigm for protecting passwords over an intranet.

      cookieDomain => {
        0 => '.acme.com',
        40 => '.acme.com',           # weak wildcard domain
        '64,128' => '.sec.acme.com', # stronger wildcard domain
        128 => 'milt.sec.acme.com'
      }

will set 4 cookies, all but the first being secure.  In addition to 
an explicit hostname at the end, this declaration defines two 
wildcard domains, *.acme.com supporting any export crippled, SSLv2
host, and *.sec.acme.com which intended to have a minimum of 64 bits 
throughout.

=head2 Session State URL Arguments

These have the obvious meaning and must agree in host, scheme, and
path with the corresponding Apache directives, as shown in the EXAMPLE 
section.  Generally for example,

authenURL => Where to go to get the appropriate credentials for a requested 
resource.

defaultURL => Where to go after logging in (if no initial request was made).

timeoutURL => Where to go to delete credentials.  Timeouts  and signouts 
are both sent here.

=head2 URL Chaining Arguments

  chainURLS => <arrayref>, issueURL => <string>

Apache::SecSess is designed to use cookies for most local authentication.  By 
their definition, cookies are restricted to a host, a DNS domain or subdomain.
The subclass Apache::SecSess::URL, which allows you to span authentication 
across DNS domains, requires additional arguments to accomplish this.   The 
argument chainURLS expects an array reference which defines a list of places 
to go for more (typically cookie) credentials.  For example,

      chainURLS => [
        'https://milt.sec.acme.com/authen', 
        'https://noam.acme.org/authen'
      ]

says that when URL credentials are issued, the client will be redirected
to each of the specified sites, in turn.  Each of these is expected to
be protected by a PerlAuthenHandler of type Apache::SecSess::Cookie::URL, 
which will issue local cookies.

The argument issueURL is used to tell the remote sites (listed in chainURLS 
arg) where to redirect the client back to, in order to continue chaining.

See the URL-Chaining example and the demo for more details.

=head2 Database Object Argument

 dbo => Apache::SecSess::DBI->new(
   dbifile => '/usr/local/apache/conf/private/dbilogin.txt'
 ),

UNFINISHED.  Apache::SecSess was designed to abstractly handle user
information.  All user ID, password, X.509 DN queries are handled through 
an opaque object of class Apache::SecSess::DBI.

Since there is no documentation for this version, you must follow the
instructions in INSTALL to get it to work.  Read db/* for more
info.

=head1 EXAMPLES

=head2 A Simple Cookie Example

Assuming all resources under directory /protected on one or more hosts
in a DNS domain need to be protected, place the following directive 
into 'httpd.conf':

  <Location /protected>
    SetHandler perl-script
    PerlHandler Apache::YourContentHandler
    PerlAuthenHandler $Acme::obj->authen
    require valid-user
  </Location>
  
On each such host, the secure session object $Acme::obj must be instantiated
from a 'startup.pl' file as in the following example, which uses an X.509
certificate for the original identification and authentication: 

  use Apache::SecSess::DBI;
  use Apache::SecSess::Cookie::X509;

  ## X.509 certificate authentication, issuing multiple cookies
  $Acme::obj = Apache::SecSess::Cookie::X509->new(
      dbo => SecSessDBI->new( ... ),
      secretFile => 'ckysec.txt',
      lifeTime => 1440, idleTime => 60, renewRate => 5,
      authRealm => 'Acme',
      cookieDomain => {
          0 => '.acme.com',
          40 => '.acme.com',
          128 => 'tom.acme.com'
      },
      minSessQOP => 128, minAuthQOP => 128, 
      authenURL => 'https://tom.acme.com/authen',
      defaultURL => 'https://tom.acme.com/protected',
      renewURL => 'https://tom.acme.com/renew',
      timeoutURL => 'https://tom.acme.com/signout/timeout.html',
      errorURL => 'http://tom.acme.com/error.html'
  );

Now, on the host which issues credentials, (tom.acme.com in this example),
add the following additional Apache directives to http.conf:

  ## issues cookies
  <Location /authen>
    SetHandler perl-script
    AuthName "Adam Realm"
    AuthType Basic
    PerlAuthenHandler $Acme::obj->issue
    require valid-user
  </Location>

  ## renew's cookies
  <Location /renew>
    SetHandler perl-script
    AuthName "Doesn't Matter"
    AuthType secsess
    PerlAuthenHandler $Acme::obj->renew
    require valid-user
  </Location>

  ## deletes cookies  
  <Location /signout>
    SetHandler perl-script
    AuthName "Doesn't Matter"
    AuthType secsess
    PerlAuthenHandler $Acme::obj->delete
    require valid-user
  </Location>

=head2 A URL-Chaining Example

In this example, a request for a resource in one DNS domain forces
a login to a site on another DNS domain which repeatedly redirects the 
client to a list other sites for cookies.  After all the chaining is 
finished, the client will be redirected back to the original request.

Suppose the original request is https://noam.acme.org/protected,
which is handled by:

  <Location /protected>
      PerlAuthenHandler $Acme::noam->authen
      ...
  </Location>

where the authen() method is of an object of class 
Apache::SecSess::Cookie::URL instantiated as: 

  $Acme::noam = Apache::SecSess::Cookie::URL->new(
    dbo => Apache::SecSess::DBI->new(...),
    secretFile => 'ckysec.txt',
    lifeTime => 1440, idleTime => 60, renewRate => 5,
    minSessQOP => 128, minAuthQOP => 128,
    authRealm => 'Acme',
    cookieDomain => { 128 => 'noam.acme.org' },
    authenURL => 'https://stu.transacme.com/chain',
    defaultURL => 'https://noam.acme.org/protected',
    renewURL => 'https://noam.acme.org/renew',
    timeoutURL => 'https://noam.acme.org/signout/timeout.html'
  );
  
Like any other subclass of Apache::SecSess::Cookie, URL.pm will
issue cookies based on the presentation of some identifying information,
and authenURL defines where to go to get that information.  The difference
is that it now points to a new DNS domain: stu.transacme.com.  

That 'remote login' is protected by

  <Location /chain>
    PerlAuthenHandler $Acme::chain->issue
  	...
  </Location> 

i.e., the issue() method of the object $Acme::chain which is instantiated
as

  $Acme::chain = Apache::SecSess::URL::Cookie->new(
    dbo => Apache::SecSess::DBI->new(...),
    secretFile => 'ckysec.txt',
    lifeTime => 1440, idleTime => 60, renewRate => 5,
    sessQOP => 128, authQOP => 128,
    minSessQOP => 128, minAuthQOP => 128,
    authRealm => 'Acme',
    authenURL => 'https://stu.transacme.com/authen',
    chainURLS => [
      'https://milt.sec.acme.com/authen', 
      'https://noam.acme.org/authen'
    ],
    issueURL => 'https://stu.transacme.com/chain',
    defaultURL => 'https://stu.transacme.com/protected',
    renewURL => 'https://stu.transacme.com/renew',
    timeoutURL => 'https://stu.transacme.com/signout/timeout.html'
  );

If no cookies are present, the client will be redirected again to
https://stu.transacme.com/authen or the issue() method of a standard
Cookie-based login:

  <Location /authen>
    PerlAuthenHandler $Acme::stu->issue
    ...
  </Location>

where $Acme::stu is an instance of, say Apache::SecSess::Cookie::X509,
just as in the previous example.

But if and when cookies are present, $Acme::chain->issue will walk
through the URL's listed in the chainURLS argument eventually getting
to https://noam.acme.org/authen protected by

  <Location /authen>
    PerlAuthenHandler $Acme::noam->issue
    ...
  </Location>

which is the cookie issuing URL and issue() method, corresponding to the 
original request.

When all the URL-chaining is done, the issue() method of $Acme::chain,
will automatically redirect back to https://noam.acme.org/protected.

=head1 SEE ALSO

See the README in the original distribution for further security 
architecture and motivation.

See RFC2109 and RFC2965, which describe the HTTP cookie protocol, and 
RFC2964 (BCP44) which presents some important caveats.

See demo/httpdconf/startup.pl and corresponding .conf files for complete 
working examples.

=head1 AUTHORS

John Pliam (pliam@atbash.com) coding and crypto protocols.

Jim Krajewski (jimk@echosoft.com) tips and techniques too numerous to mention.

=cut
