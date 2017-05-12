#===============================================================================
#
# Apache::AuthCookiePAM
#
# An AuthCookie module backed by a PAM.
#
# Copyright (C) 2002 SF Interactive.
#
# Author:  Vandana Awasthi
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
# 
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#===============================================================================

package Apache::AuthCookiePAM;

use strict;
use 5.004;
use vars qw( $VERSION );
( $VERSION ) = '$Revision: 1.0 $' =~ /([\d.]+)/;

use Apache;
use Apache::Table;
use Apache::Constants qw(:common M_GET FORBIDDEN REDIRECT);
use Apache::AuthCookie::Util;
use Apache::Util qw(escape_uri);
use Apache::AuthCookie;
use Authen::PAM;
use vars qw( @ISA );
@ISA = qw( Apache::AuthCookie );

use Apache::File;
use Digest::MD5 qw( md5_hex );
use Date::Calc qw( Today_and_Now Add_Delta_DHMS );
# Also uses Crypt::CBC if you're using encrypted cookies.

#===============================================================================
# F U N C T I O N   D E C L A R A T I O N S
#===============================================================================

sub _log_not_set($$);
sub _dir_config_var($$);
sub _config_vars($);
sub _now_year_month_day_hour_minute_second();
sub _percent_encode($);
sub _percent_decode($);

sub authen_cred($$\@);
sub authen_ses_key($$$);
sub group($$\@);

#===============================================================================
# P A C K A G E   G L O B A L S
#===============================================================================

use vars qw( %CIPHERS );
# Stores Cipher::CBC objects in $CIPHERS{ idea:AuthName },
# $CIPHERS{ des:AuthName } etc.

use vars qw( %SECRET_KEYS );
# Stores secret keys for MD5 checksums and encryption for each auth realm in
# $SECRET_KEYS{ AuthName }.

#===============================================================================
# S E R V E R   S T A R T   I N I T I A L I Z A T I O N
#===============================================================================

BEGIN {
	my (@keyfile_vars, $keyfile_var);
	@keyfile_vars = grep {
		$_ =~ /PAM_SecretKeyFile$/
	} keys %{ Apache->server->dir_config() };
	
	foreach  $keyfile_var ( @keyfile_vars ) {
		my $keyfile ;
		$keyfile = Apache->server->dir_config( $keyfile_var );
		my $auth_name ; $auth_name = $keyfile_var;
		
		$auth_name =~ s/PAM_SecretKeyFile$//;
		unless ( open( KEY, "<$keyfile" ) ) {
			Apache::log_error( "Could not open keyfile for $auth_name in file $keyfile" );
		} else {
			$SECRET_KEYS{ $auth_name } = <KEY>;
		close KEY;
		}
	}
}

#===============================================================================
# P E R L D O C
#===============================================================================

=head1 NAME

Apache::AuthCookiePAM - An AuthCookie module backed by a PAM .

=head1 VERSION

	$Revision: 1.0 $

=head1 SYNOPSIS

	# In httpd.conf or .htaccess
	# This PerlSetVar MUST precede the PerlModule line because the
	# key is read in a BEGIN block when the module is loaded.
	PerlSetVar WhatEverPaM_SecretKeyFile /etc/httpd/acme.com.key
	PerlSetVar WhatEverPAM_service login

	PerlModule Apache::AuthCookiePAM
	PerlSetVar WhatEverPath /
	PerlSetVar WhatEverLoginScript /login.pl

	# Optional, to share tickets between servers.
	PerlSetVar WhatEverDomain .domain.com
	PerlSetVar WhatEverChangePwdScript /changepwd.pl
	
	# These are optional, the module sets sensible defaults.
	PerlSetVar WhatEverPAM_SessionLifetime 00-24-00-00

	# Protected by AuthCookiePAM.
	<Directory /www/domain.com/authcookiepam>
		AuthType Apache::AuthCookiePAM
		AuthName WhatEver
		PerlAuthenHandler Apache::AuthCookiePAM->authenticate
		PerlAuthzHandler Apache::AuthCookiePAM->authorize
		require valid-user
	</Directory>

	# Login location.  *** DEBUG *** I still think this is screwy
	<Files LOGIN>
		AuthType Apache::AuthCookiePAM
		AuthName WhatEver
		SetHandler perl-script
		PerlHandler Apache::AuthCookiePAM->login
	</Files>

	<Files ChangePwd>
		AuthType Apache::AuthCookiePAM
		AuthName WhatEver
		SetHandler perl-script
		PerlHandler Apache::AuthCookiePAM->changepwd
	</Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism 
provided by Apache::AuthCookie with PAM (based on DBI) .  It is based on
two tokens being provided, a username and password, which can be any 
strings (there are no illegal characters for either).  The username is 
used to set the remote user as if Basic Authentication was used.

On an attempt to access a protected location without a valid cookie being
provided, the module prints an HTML login form (produced by a CGI or any
other handler; this can be a static file if you want to always send people
to the same entry page when they log in).  This login form has fields for
username and password.  On submitting it, the username and password are verfied 
using PAM. If this succeeds, the user is issued a ticket.  This ticket contains 
the username, an issue time, an expire time, and an MD5 checksum of those and a 
secret key for the server.  It can optionally be encrypted before returning it 
to the client in the cookie;
encryption is only useful for preventing the client from seeing the expire
time.  If you wish to protect passwords in transport, use an SSL-encrypted
connection.  The ticket is given in a cookie that the browser stores.

After a login the user is redirected to the location they originally wished
to view (or to a fixed page if the login "script" was really a static file).

On this access and any subsequent attempt to access a protected document, the
browser returns the ticket to the server.  The server unencrypts it if
encrypted tickets are enabled, then extracts the username, issue time, expire
time and checksum.  A new checksum is calculated of the username, issue time,
expire time and the secret key again; if it agrees with the checksum that
the client supplied, we know that the data has not been tampered with.  We
next check that the expire time has not passed.  If not, the ticket is still
good, so we set the username.

Authorization checks then check that any "require valid-user" . If checks pass, 
the document requested is displayed.

If a ticket has expired or is otherwise invalid it is cleared in the browser
and the login form is shown again.

=cut

#===============================================================================
# P R I V A T E   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# _log_not_set -- Log that a particular authentication variable was not set.

sub _log_not_set($$)
{
	my( $r, $variable ) = @_;
	my $auth_name; $auth_name = $r->auth_name;
	$r->log_error( "Apache::AuthCookiePAM: $variable not set for auth realm
$auth_name", $r->uri );
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.

sub _dir_config_var($$)
{
	my( $r, $variable ) = @_;
	my $auth_name; $auth_name = $r->auth_name;
	return $r->dir_config( "$auth_name$variable" );
}

#-------------------------------------------------------------------------------
# _config_vars -- Gets the config variables from the dir_config and logs
# errors if required fields were not set, returns undef if any of the fields
# had errors or a hash of the values if they were all OK.  Takes a request
# object.

sub _config_vars($)
{
	my( $r ) = @_;

	my %c; # config variables hash

=head1 APACHE CONFIGURATION DIRECTIVES

All configuration directives for this module are passed in PerlSetVars.  These
PerlSetVars must begin with the AuthName that you are describing, so if your
AuthName is PrivateBankingSystem they will look like:

	PerlSetVar ProvateBankingSystemLoginScript /bvsm/login.pl


See also L<Apache::Authcookie> for the directives required for any kind
of Apache::AuthCookie-based authentication system.

In the following descriptions, replace "WhatEver" with your particular
AuthName.  The available configuration directives are as follows:

=over 4

=item C<WhatEverPAM_SecretKeyFile>

The file that contains the secret key (on the first line of the file).  This
is required and has no default value.  This key should be owned and only
readable by root.  It is read at server startup time.  The key should be long
and fairly random.  If you want, you can change it and restart the server,
(maybe daily), which will invalidate all prior-issued tickets.

This directive MUST be set before the PerlModule line that loads this module,
because the secret key file is read immediately (at server start time).  This
is so you can have it owned and only readable by root even though Apache
then changes to another user.

=cut

	unless (
	   $c{ PAM_secretkeyfile } = _dir_config_var $r, 'PAM_SecretKeyFile'
	) {
		_log_not_set $r, 'PAM_SecretKeyFile';
		return undef;
	}

=item C<WhatEverPAM_SessionLifetime>

How long tickets are good for after being issued.  Note that presently
Apache::AuthCookie does not set a client-side expire time, which means that
most clients will only keep the cookie until the user quits the browser.
However, if you wish to force people to log in again sooner than that, set
this value.  This can be 'forever' or a life time specified as:

	DD-hh-mm-ss -- Days, hours, minute and seconds to live.

This is not required and defaults to '00-24-00-00' or 24 hours.

=cut

	$c{ PAM_sessionlifetime }
	   = _dir_config_var( $r, 'PAM_SessionLifetime' ) || '00-24-00-00';

=item C<WhatEverPAM_EncryptionType>

What kind of encryption to use to prevent the user from looking at the fields
in the ticket we give them.  This is almost completely useless, so don't
switch it on unless you really know you need it.  It does not provide any
protection of the password in transport; use SSL for that.  It can be 'none',
'des', 'idea', 'blowfish', or 'blowfish_pp'.

This is not required and defaults to 'none'.

=cut

	$c{ PAM_encryptiontype } = _dir_config_var( $r, 'PAM_EncryptionType' )
	            || 'none';
	# If we used encryption we need to pull in Crypt::CBC.
	if ( $c{ PAM_encryptiontype } ne 'none' ) {
		require Crypt::CBC;
	}

=item C<WhatEverPAM_service>

The service that will be using PAM libraries for authentication.
These will be one of the services configured in  /etc/pam.conf or /etc/pam.d/<service>

This directive defaults to "login"

=cut

	$c{ PAM_service } = _dir_config_var ( $r, 'PAM_service' ) || 'login';

	return %c;
}

#-------------------------------------------------------------------------------
# _now_year_month_day_hour_minute_second -- Return a string with the time in
# this order separated by dashes.

sub _now_year_month_day_hour_minute_second()
{
	return sprintf '%04d-%02d-%02d-%02d-%02d-%02d', Today_and_Now;
}

#-------------------------------------------------------------------------------
# _percent_encode -- Percent-encode (like URI encoding) any non-alphanumberics
# in the supplied string.

sub _percent_encode($)
{
	my( $str ) = @_;
	$str =~ s/([^\w])/ uc sprintf '%%%02x', ord $1 /eg;
	return $str;
}

#-------------------------------------------------------------------------------
# _percent_decode -- Percent-decode (like URI decoding) any %XX sequences in
# the supplied string.

sub _percent_decode($)
{
	my( $str ) = @_;
	$str =~ s/%([0-9a-fA-F]{2})/ pack( "c",hex( $1 ) ) /ge;
	return $str;
}

#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# Take the credentials for a user and check that they match; if so, return
# a new session key for this user that can be stored in the cookie.
# If there is a problem, return a bogus session key.

sub authen_cred($$\@)
{
    my( $self, $r, @credentials ) ;
    ( $self, $r, @credentials ) = @_;

    my $auth_name; $auth_name = $r->auth_name;
    my %c ; %c = _config_vars $r;

    # Username goes in credential_0
    my $user; $user = $credentials[ 0 ];
    $user=~ tr/A-Z/a-z/;
    unless ( $user =~ /^.+$/ ) {
	$r->log_reason( "Apache::AuthCookiePAM: no username supplied for auth realm $auth_name", $r->uri );
        $r->subprocess_env('AuthenReason', 'No username provided. Try again.');
	return undef;
    }
    # Password goes in credential_1
    my $password; $password = $credentials[ 1 ];
    unless ( $password =~ /^.+$/ ) {
	$r->log_reason( "Apache::AuthCookiePAM: no password supplied for auth realm $auth_name", $r->uri );
        $r->subprocess_env('AuthenReason', 'No password provided. Try again.');
	return undef;
    }
    # service to be used for authentication
    my $service; $service = $c{PAM_service};
    my ($pamh,$res,$funcref);
    $funcref=create_conv_func($r,$user,$password); 
      
    ref($pamh = new Authen::PAM($service, $user,$funcref)) || die "Error code $pamh during PAM init!";
    # call auth module to authenticate user
    $res = $pamh->pam_authenticate;
    $funcref=0;
    if ( $res != PAM_SUCCESS()) {
        $r->log_error("ERROR: Authentication for $user Failed\n");
        $r->subprocess_env('AuthenReason', 'Authentication failed. Username/Password provided incorrect.');
        $pamh=0;
	undef $pamh;
        return undef;
    } 
    else { # Now check if account is valid
        $res = $pamh->pam_acct_mgmt();
	if ( $res == PAM_ACCT_EXPIRED() ) {
           $r->log_error("ERROR: Account for $user is locked. Contact your Administrator.\n");
           $r->subprocess_env('AuthenReason', 'Account for $user is locked. Contact your Administrator.');
           return 'bad';
	}
	if ( $res == PAM_NEW_AUTHTOK_REQD() ) {
           $r->log_error("ERROR: PAssword for $user expired. Change Password\n");
           $r->subprocess_env('AuthenReason', 'Password Expired. Please Change your password.');
	   return $r->auth_type->changepwd_form ($user);
	}
	if ( $res == PAM_SUCCESS() ) {
           # Create the expire time for the ticket.
           my $expire_time;
           # expire time in a zillion years if it's forever.
           if ( lc $c{ PAM_sessionlifetime } eq 'forever' ) {
              $expire_time = '9999-01-01-01-01-01';
           } else {
	      my( $deltaday, $deltahour, $deltaminute, $deltasecond ) = split /-/, $c{ PAM_sessionlifetime };
	      # Figure out the expire time.
	      $expire_time = sprintf( '%04d-%02d-%02d-%02d-%02d-%02d',
					Add_Delta_DHMS( Today_and_Now,
					                $deltaday, $deltahour,
							$deltaminute, $deltasecond ));
          }

	   # Now we need to %-encode non-alphanumberics in the username so we
	   # can stick it in the cookie safely.  *** DEBUG *** check this
	   my $enc_user; $enc_user = _percent_encode $user;

	   # OK, now we stick the username and the current time and the expire
	   # time together to make the public part of the session key:
	   my $current_time; $current_time = _now_year_month_day_hour_minute_second;
	   my $public_part; $public_part = "$enc_user:$current_time:$expire_time";

	   # Now we calculate the hash of this and the secret key and then
	   # calculate the hash of *that* and the secret key again.
	   my $secret_key; $secret_key = $SECRET_KEYS{ $auth_name };
	   unless ( defined $secret_key ) {
		$r->log_reason( "Apache::AuthCookiePAM: didn't have the secret key for auth realm $auth_name", $r->uri );
		return 'bad';
	   }
	   my $hash ; $hash = md5_hex( join ':', $secret_key, md5_hex(
	                  	join ':', $public_part, $secret_key
	                     ) );

	   # Now we add this hash to the end of the public part.
	   my $session_key; $session_key = "$public_part:$hash";

	   # Now we encrypt this and return it.
	   my $encrypted_session_key;
	   if ( $c{ PAM_encryptiontype } eq 'none' ) {
		$encrypted_session_key = $session_key;
	   } elsif ( lc $c{ PAM_encryptiontype } eq 'des'      ) {
		$CIPHERS{ "des:$auth_name"      }
		   ||= Crypt::CBC->new( $secret_key, 'DES'      );
		$encrypted_session_key = $CIPHERS{
			"des:$auth_name"
		}->encrypt_hex( $session_key );
	   } elsif ( lc $c{ PAM_encryptiontype } eq 'idea'     ) {
		$CIPHERS{ "idea:$auth_name"      }
		   ||= Crypt::CBC->new( $secret_key, 'IDEA'     );
		$encrypted_session_key = $CIPHERS{
			"idea:$auth_name"
		}->encrypt_hex( $session_key );
	   } elsif ( lc $c{ PAM_encryptiontype } eq 'blowfish' ) {
		$CIPHERS{ "blowfish:$auth_name" }
		   ||= Crypt::CBC->new( $secret_key, 'Blowfish' );
		$encrypted_session_key = $CIPHERS{
			"blowfish:$auth_name"
		}->encrypt_hex( $session_key );
	   }
	   $pamh=0;
	   undef $pamh;
	   return $encrypted_session_key;
        }
    }
}


#-------------------------------------------------------------------------------
# Conversation function for PAM - authentication and change of password
sub create_conv_func 
{
   my ($r,$user,$pass,$newpass,$confpass);
   ($r,$user,$pass,$newpass,$confpass) = @_;

   my $state; $state = 0;

   return sub {
       my (@res);
       while ( @_ ) 
          {
	  my ($code, $msg, $ans); 
	  $code = shift;
	  $msg = shift ;
	  $ans = "";

          $ans = $user if ($code == PAM_PROMPT_ECHO_ON() );
	  if ($code == PAM_PROMPT_ECHO_OFF() ) {
	  if ($state == 0) {
	       $ans = $pass ;
	  } 
          if ($state == 1) {
	       $ans = $newpass ;
	  } 
          if ($state == 2) {
	       $ans = $confpass ;
	  }
	  $r->log_error("VA: $msg $user $pass $newpass $confpass $state=$ans");
          $state++;
	  }
          push @res, (PAM_SUCCESS(),$ans);
          }
       push @res, PAM_SUCCESS();
       return @res;
      };
}

#-------------------------------------------------------------------------------
# Take a session key and check that it is still valid; if so, return the user.

sub authen_ses_key($$$)
{
	my( $self, $r, $encrypted_session_key ) = @_;

	my $auth_name ; $auth_name = $r->auth_name;

	# Get the configuration information.
	my %c; %c = _config_vars $r;

	# Get the secret key.
	my $secret_key; $secret_key = $SECRET_KEYS{ $auth_name };
	unless ( defined $secret_key ) {
		$r->log_reason( "Apache::AuthCookiePAM: didn't the secret key from for auth realm $auth_name", $r->uri );
		return undef;
	}
	
	# Decrypt the session key.
	my $session_key;
	if ( $c{ PAM_encryptiontype } eq 'none' ) {
		$session_key = $encrypted_session_key;
	} else {
		# Check that this looks like an encrypted hex-encoded string.
		unless ( $encrypted_session_key =~ /^[0-9a-fA-F]+$/ ) {
			$r->log_reason( "Apache::AuthCookiePAM: encrypted session key $encrypted_session_key doesn't look like it's properly hex-encoded for auth realm $auth_name", $r->uri );
			return undef;
		}

		# Get the cipher from the cache, or create a new one if the
		# cached cipher hasn't been created, & decrypt the session key.
		my $cipher;
		if ( lc $c{ PAM_encryptiontype } eq 'des' ) {
			$cipher = $CIPHERS{ "des:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'DES' );
		} elsif ( lc $c{ PAM_encryptiontype } eq 'idea' ) {
			$cipher = $CIPHERS{ "idea:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'IDEA' );
		} elsif ( lc $c{ PAM_encryptiontype } eq 'blowfish' ) {
			$cipher = $CIPHERS{ "blowfish:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'Blowfish' );
		} elsif ( lc $c{ PAM_encryptiontype } eq 'blowfish_pp' ) {
			$cipher = $CIPHERS{ "blowfish_pp:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'Blowfish_PP' );
		} else {
			$r->log_reason( "Apache::AuthCookiePAM: unknown encryption type $c{ PAM_encryptiontype } for auth realm $auth_name", $r->uri );
			return undef;
		}
		$session_key = $cipher->decrypt_hex( $encrypted_session_key );
	}
	
	# Break up the session key.
	my( $enc_user, $issue_time, $expire_time, $supplied_hash )
	   = split /:/, $session_key;
	# Let's check that we got passed sensible values in the cookie.
	unless ( $enc_user =~ /^[a-zA-Z0-9_\%]+$/ ) {
		$r->log_reason( "Apache::AuthCookiePAM: bad percent-encoded user $enc_user recovered from session ticket for auth_realm $auth_name", $r->uri );
		return undef;
	}
	# decode the user
	my $user; $user = _percent_decode $enc_user;
	unless ( $issue_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
		$r->log_reason( "Apache::AuthCookiePAM: bad issue time $issue_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}
	unless ( $expire_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
		$r->log_reason( "Apache::AuthCookiePAM: bad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}
	unless ( $supplied_hash =~ /^[0-9a-fA-F]{32}$/ ) {
		$r->log_reason( "Apache::AuthCookiePAM: bad hash $supplied_hash recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}

	# Calculate the hash of the user, issue time, expire_time and
	# the secret key and then the hash of that and the secret key again.
	my $hash; $hash = md5_hex( join ':', $secret_key, md5_hex(
		join ':', $enc_user, $issue_time, $expire_time, $secret_key
	) );

	# Compare it to the hash they gave us.
	unless ( $hash eq $supplied_hash ) {
		$r->log_reason( "Apache::AuthCookiePAM: hash in cookie did not match calculated hash of contents for user $user for auth realm $auth_name", $r->uri );
		return undef;
	}

	# Check that their session hasn't timed out.
	if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
		$r->log_reason( "Apache:AuthCookiePAM: expire time $expire_time has passed for user $user for auth realm $auth_name", $r->uri );
		return undef;
	}

	# If we're being paranoid about timing-out long-lived sessions,
	# check that the issue time + the current (server-set) session lifetime
	# hasn't passed too (in case we issued long-lived session tickets
	# in the past that we want to get rid of). *** DEBUG ***
	# if ( lc $c{ PAM_AlwaysUseCurrentSessionLifetime } eq 'on' ) 

	# They must be okay, so return the user.
	return $user;
}


sub changepwd_form 
{  
  my $self; $self = shift;
  my $user; $user = shift;

  my $r; $r = Apache->request or die "no request";
  $r->log_error(" $self ");
  $r->subprocess_env("AuthenChangePwdUser","$user");
  my $auth_name; $auth_name = $r->auth_name;

  my %args; %args = $r->method eq 'POST' ? $r->content : $r->args;

  $self->_convert_to_get($r, \%args) if $r->method eq 'POST';

  # There should be a PerlSetVar directive that gives us the URI of
  # the script to execute for the login form.
  
  my $script;
  unless ($script = $r->dir_config($auth_name . "ChangePwdScript")) {
    $r->log_reason("PerlSetVar '${auth_name}ChangePwdScript' not set", $r->uri);
    return SERVER_ERROR;
  }
  $r->log_error("Redirecting to $script");
  $r->custom_response(REDIRECT, $script);
  
  return REDIRECT;
}

sub _convert_to_get 
{
    my ($self, $r, $args) ;
    ($self, $r, $args) = @_;

    return unless $r->method eq 'POST';

    my $debug ; $debug = $r->dir_config("AuthCookieDebug") || 0;

    $r->log_error("Converting POST -> GET") if $debug >= 2;

    my @pairs ; @pairs =();
    my ($name, $value);
    
    while ( ($name, $value) = each %$args) {
      # we dont want to copy login data, only extra data
      next if $name eq 'destination'
           or $name =~ /^credential_\d+$/;

      $value = '' unless defined $value;
      push @pairs, escape_uri($name) . '=' . escape_uri($value);
    }
    $r->args(join '&', @pairs) if scalar(@pairs) > 0;

    $r->method('GET');
    $r->method_number(M_GET);
    $r->headers_in->unset('Content-Length');
}

sub changepwd ($$) 
{
  my ($self, $r) ;
  ($self, $r) = @_;
  
  my $debug; $debug = $r->dir_config("AuthCookieDebug") || 0;

  my ($auth_type, $auth_name);  
  ($auth_type, $auth_name) = ($r->auth_type, $r->auth_name);

  my %args; %args = $r->method eq 'POST' ? $r->content : $r->args;

  $self->_convert_to_get($r, \%args) if $r->method eq 'POST';

  unless (exists $args{'destination'}) {
    $r->log_error("No key 'destination' found in form data");
    $r->subprocess_env('AuthenReason', 'no_cookie');
    return $auth_type->login_form;
  }
  $r->subprocess_env('AuthenReason', 'Password Change requested/required');
  
  # Get the credentials from the data posted by the client
  my @credentials;
  #user in credential_0
  my $user; $user = $args{"credential_0"};
  $user=~ tr/A-Z/a-z/;
  unless ( $user =~ /^.+$/ ) {
	$r->log_reason( "Apache::AuthCookiePAM: no username supplied for auth realm $auth_name", $r->uri );
  }
  # Old Password goes in credential_1
  my $oldpassword; $oldpassword = $args{"credential_1"};
  unless ( $oldpassword =~ /^.+$/ ) {
	$r->log_reason( "Apache::AuthCookiePAM: no password supplied ", $r->uri );
  }
  # New Password goes in credential_2
  my $newpassword ; $newpassword = $args{"credential_2"};
  unless ( $newpassword =~ /^.+$/ ) {
	$r->log_reason( "Apache::AuthCookiePAM: no password supplied ", $r->uri );
  }
  # Repeat Password goes in credential_3
  my $confirmpassword; $confirmpassword = $args{"credential_3"};
  unless ( $confirmpassword =~ /^.+$/  ) {
	$r->log_reason( "Apache::AuthCookiePAM: passwords don't match", $r->uri );
  }
  
  # Now do password change
  #
  my ($pamh,$res);
  my $funcref;
  $funcref=create_conv_func($r,$user,$oldpassword,$newpassword,$confirmpassword);
									  
  my %c; %c = _config_vars $r;

  my $service; $service = $c{PAM_service};
  ref($pamh = new Authen::PAM($service, $user,$funcref)) || die "Error code $pamh during PAM init!";
  $res = $pamh->pam_chauthtok();
  $pamh=0;
  undef $pamh;

  if ( $res == PAM_SUCCESS()) {
       $r->subprocess_env('AuthenReason', 'Password Updated. Please login with your new password');
       $r->log_reason("AuthenCookiePAM:". $args{'destination'}."Password for $user Updated. Please login with your new password");
       # 
       $auth_type->logout($r);
       $r->err_header_out("Location" => $args{'destination'});
       return REDIRECT;
  }
  else { 
       $r->subprocess_env('AuthenReason', "Password Not Updated. New password did not satisfy specified rules or failed authentication");
       $r->log_reason("AuthenCookiePAM: Password for $user Not Updated. ");
       return $auth_type->changepwd_form($user);
    }
}

#-------------------------------------------------------------------------------
# Take a list of groups and make sure that the current remote user is a member
# of one of them.

__END__

=back


=head1 COPYRIGHT

Copyright (C) 2002 SF Interactive.

=head1 LICENSE

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHOR

Vandana Awasthi


=head1 SEE ALSO

Apache::AuthCookie(1)

=cut
