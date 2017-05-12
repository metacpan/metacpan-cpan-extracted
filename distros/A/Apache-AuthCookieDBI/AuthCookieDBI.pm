#===============================================================================
#
# $Id: AuthCookieDBI.pm,v 1.22.2.4 2007/02/03 19:22:24 matisse Exp $
#
# Apache::AuthCookieDBI
#
# An AuthCookie module backed by a DBI database.
#
# Copyright (C) 2000-2003 SF Interactive.
#
# Author:  Jacob Davies <jacob@well.com>
#
# Incomplete list of additional contributors:
#     Matisse Enzer
#     Nick Phillips
#     William McKee
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

package Apache::AuthCookieDBI;

use strict;
use warnings;
use 5.004_04;

our $VERSION = 2.10;

use Apache;
use Apache::AuthCookie;
use Apache::DBI;
use Apache::Constants;
use Apache::File;
use Digest::MD5 qw( md5_hex );
use Date::Calc qw( Today_and_Now Add_Delta_DHMS );

# Also uses Crypt::CBC if you're using encrypted cookies.
use base qw( Apache::AuthCookie );

my $EMPTY_STRING = q{};

#===============================================================================
# F U N C T I O N   D E C L A R A T I O N S
#===============================================================================


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
    my @keyfile_vars =
      grep { $_ =~ /DBI_SecretKeyFile$/ }
      keys %{ Apache->server->dir_config() };
    foreach my $keyfile_var (@keyfile_vars) {
        my $keyfile   = Apache->server->dir_config($keyfile_var);
        my $auth_name = $keyfile_var;
        $auth_name =~ s/DBI_SecretKeyFile$//;
        my $key_fh;
        open( $key_fh, '<', $keyfile );
        if ( -r $key_fh ) {
            $SECRET_KEYS{$auth_name} = <$key_fh>;
            close $key_fh;
        }
        else {
            Apache::log_error(
"Could not open keyfile '$keyfile' for $auth_name in file $keyfile"
            );
        }
    }
}

#===============================================================================
# P E R L D O C
#===============================================================================

=head1 NAME

Apache::AuthCookieDBI - An AuthCookie module backed by a DBI database.

=head1 VERSION

	$Revision: 1.22.2.4 $

=head1 SYNOPSIS

	# In httpd.conf or .htaccess
        
	# This PerlSetVar MUST precede the PerlModule line because the
	# key is read in a BEGIN block when the module is loaded.
	PerlSetVar WhatEverDBI_SecretKeyFile /etc/httpd/acme.com.key

	PerlModule Apache::AuthCookieDBI
	PerlSetVar WhatEverPath /
	PerlSetVar WhatEverLoginScript /login.pl

	# Optional, to share tickets between servers.
	PerlSetVar WhatEverDomain .domain.com
	
	# These must be set
	PerlSetVar WhatEverDBI_DSN "DBI:mysql:database=test"
        PerlSetVar WhatEverDBI_SecretKey "489e5eaad8b3208f9ad8792ef4afca73598ae666b0206a9c92ac877e73ce835c"

	# These are optional, the module sets sensible defaults.
	PerlSetVar WhatEverDBI_User "nobody"
	PerlSetVar WhatEverDBI_Password "password"
	PerlSetVar WhatEverDBI_UsersTable "users"
	PerlSetVar WhatEverDBI_UserField "user"
	PerlSetVar WhatEverDBI_PasswordField "password"
	PerlSetVar WhatEverDBI_CryptType "none"
	PerlSetVar WhatEverDBI_GroupsTable "groups"
	PerlSetVar WhatEverDBI_GroupField "grp"
	PerlSetVar WhatEverDBI_GroupUserField "user"
	PerlSetVar WhatEverDBI_EncryptionType "none"
	PerlSetVar WhatEverDBI_SessionLifetime 00-24-00-00

	# Protected by AuthCookieDBI.
	<Directory /www/domain.com/authcookiedbi>
		AuthType Apache::AuthCookieDBI
		AuthName WhatEver
		PerlAuthenHandler Apache::AuthCookieDBI->authenticate
		PerlAuthzHandler Apache::AuthCookieDBI->authorize
		require valid-user
		# or you can require users:
		require user jacob
		# You can optionally require groups.
		require group system
	</Directory>

	# Login location.
	<Files LOGIN>
		AuthType Apache::AuthCookieDBI
		AuthName WhatEver
		SetHandler perl-script
		PerlHandler Apache::AuthCookieDBI->login
	</Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism provided
by Apache::AuthCookie with a DBI database for ticket-based protection.  It
is based on two tokens being provided, a username and password, which can
be any strings (there are no illegal characters for either).  The username is
used to set the remote user as if Basic Authentication was used.

On an attempt to access a protected location without a valid cookie being
provided, the module prints an HTML login form (produced by a CGI or any
other handler; this can be a static file if you want to always send people
to the same entry page when they log in).  This login form has fields for
username and password.  On submitting it, the username and password are looked
up in the DBI database.  The supplied password is checked against the password
in the database; the password in the database can be plaintext, or a crypt()
or md5_hex() checksum of the password.  If this succeeds, the user is issued
a ticket.  This ticket contains the username, an issue time, an expire time,
and an MD5 checksum of those and a secret key for the server.  It can
optionally be encrypted before returning it to the client in the cookie;
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

Authorization checks then check that any "require valid-user" or "require
user jacob" settings are passed.  Finally, if a "require group foo" directive
was given, the module will look up the username in a groups database and
check that the user is a member of one of the groups listed.  If all these
checks pass, the document requested is displayed.

If a ticket has expired or is otherwise invalid it is cleared in the browser
and the login form is shown again.

=cut

#===============================================================================
# P R I V A T E   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# _log_not_set -- Log that a particular authentication variable was not set.

sub _log_not_set {
    my ( $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    return $r->log_error(
        "Apache::AuthCookieDBI: $variable not set for auth realm
$auth_name", $r->uri
    );
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.

sub _dir_config_var {
    my ( $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    return $r->dir_config("$auth_name$variable");
}

#-------------------------------------------------------------------------------
# _dbi_config_vars -- Gets the config variables from the dir_config and logs
# errors if required fields were not set, returns undef if any of the fields
# had errors or a hash of the values if they were all OK.  Takes a request
# object.

sub _dbi_config_vars {
    my ($r) = @_;

    my %c;    # config variables hash

=head1 APACHE CONFIGURATION DIRECTIVES

All configuration directives for this module are passed in PerlSetVars.  These
PerlSetVars must begin with the AuthName that you are describing, so if your
AuthName is PrivateBankingSystem they will look like:

	PerlSetVar PrivateBankingSystemDBI_DSN "DBI:mysql:database=banking"

See also L<Apache::Authcookie> for the directives required for any kind
of Apache::AuthCookie-based authentication system.

In the following descriptions, replace "WhatEver" with your particular
AuthName.  The available configuration directives are as follows:

=over 4

=item C<WhatEverDBI_DSN>

Specifies the DSN for DBI for the database you wish to connect to retrieve
user information.  This is required and has no default value.

=cut

    unless ( $c{DBI_DSN} = _dir_config_var $r, 'DBI_DSN' ) {
        _log_not_set $r, 'DBI_DSN';
        return;
    }

=item C<WhateverDBI_SecretKey>

Specifies the secret key for this auth scheme.  This should be a long
random string.  This should be secret; either make the httpd.conf file
only readable by root, or put the PerlSetVar in a file only readable by
root and include it.

This is required and has no default value
=cut

    unless ( $c{DBI_SecretKey} = _dir_config_var $r, 'DBI_SecretKey'
        or _dir_config_var $r, 'DBI_SecretKeyFile' )
    {
        _log_not_set $r, 'DBI_SecretKey or DBI_SecretKeyFile';
        return;
    }

=item C<WhatEverDBI_User>

The user to log into the database as.  This is not required and
defaults to undef.

=cut

    $c{DBI_user} = _dir_config_var( $r, 'DBI_User' )
      || undef;

=item C<WhatEverDBI_Password>

The password to use to access the database.  This is not required
and defaults to undef.

=cut

    $c{DBI_password} = _dir_config_var( $r, 'DBI_Password' )
      || undef;

=item C<WhatEverDBI_UsersTable>

The table that user names and passwords are stored in.  This is not
required and defaults to 'users'.

=cut

    $c{DBI_userstable} = _dir_config_var( $r, 'DBI_UsersTable' )
      || 'users';

=item C<WhatEverDBI_UserField>

The field in the above table that has the user name.  This is not
required and defaults to 'user'.

=cut

    $c{DBI_userfield} = _dir_config_var( $r, 'DBI_UserField' )
      || 'user';

=item C<WhatEverDBI_PasswordField>

The field in the above table that has the password.  This is not
required and defaults to 'password'.

=cut

    $c{DBI_passwordfield} = _dir_config_var( $r, 'DBI_PasswordField' )
      || 'password';

=item C<WhatEverDBI_CryptType>

What kind of hashing is used on the password field in the database.  This can
be 'none', 'crypt', or 'md5'.  This is not required and defaults to 'none'.

=cut

    $c{DBI_crypttype} = _dir_config_var( $r, 'DBI_CryptType' )
      || 'none';

=item C<WhatEverDBI_GroupsTable>

The table that has the user / group information.  This is not required and
defaults to 'groups'.

=cut

    $c{DBI_groupstable} = _dir_config_var( $r, 'DBI_GroupsTable' )
      || 'groups';

=item C<WhatEverDBI_GroupField>

The field in the above table that has the group name.  This is not required
and defaults to 'grp' (to prevent conflicts with the SQL reserved word 'group').

=cut

    $c{DBI_groupfield} = _dir_config_var( $r, 'DBI_GroupField' )
      || 'grp';

=item C<WhatEverDBI_GroupUserField>

The field in the above table that has the user name.  This is not required
and defaults to 'user'.

=cut

    $c{DBI_groupuserfield} = _dir_config_var( $r, 'DBI_GroupUserField' )
      || 'user';

=item C<WhatEverDBI_SecretKeyFile - DEPRECATED>

The file that contains the secret key (on the first line of the file).  This
is required and has no default value.  This key should be owned and only
readable by root.  It is read at server startup time.  The key should be long
and fairly random.  If you want, you can change it and restart the server,
(maybe daily), which will invalidate all prior-issued tickets.

This directive MUST be set before the PerlModule line that loads this module,
because the secret key file is read immediately (at server start time).  This
is so you can have it owned and only readable by root even though Apache
then changes to another user.

I suggest using DBI_SecretKey instead.

=cut

    unless ( $c{DBI_secretkeyfile} = _dir_config_var $r, 'DBI_SecretKeyFile'
        or _dir_config_var $r, 'DBI_SecretKey' )
    {
        _log_not_set $r, 'DBI_SecretKeyFile or DBI_SecretKey';
        return;
    }

=item C<WhatEverDBI_EncryptionType>

What kind of encryption to use to prevent the user from looking at the fields
in the ticket we give them.  This is almost completely useless, so don't
switch it on unless you really know you need it.  It does not provide any
protection of the password in transport; use SSL for that.  It can be 'none',
'des', 'idea', 'blowfish', or 'blowfish_pp'.

This is not required and defaults to 'none'.

=cut

    $c{DBI_encryptiontype} = _dir_config_var( $r, 'DBI_EncryptionType' )
      || 'none';

    # If we used encryption we need to pull in Crypt::CBC.
    if ( $c{DBI_encryptiontype} ne 'none' ) {
        require Crypt::CBC;
    }

=item C<WhatEverDBI_SessionLifetime>

How long tickets are good for after being issued.  Note that presently
Apache::AuthCookie does not set a client-side expire time, which means that
most clients will only keep the cookie until the user quits the browser.
However, if you wish to force people to log in again sooner than that, set
this value.  This can be 'forever' or a life time specified as:

	DD-hh-mm-ss -- Days, hours, minute and seconds to live.

This is not required and defaults to '00-24-00-00' or 24 hours.

=cut

    $c{DBI_sessionlifetime} = _dir_config_var( $r, 'DBI_SessionLifetime' )
      || '00-24-00-00';

    return %c;
}

#-------------------------------------------------------------------------------
# _now_year_month_day_hour_minute_second -- Return a string with the time in
# this order separated by dashes.

sub _now_year_month_day_hour_minute_second {
    return sprintf '%04d-%02d-%02d-%02d-%02d-%02d', Today_and_Now;
}

#-------------------------------------------------------------------------------
# _percent_encode -- Percent-encode (like URI encoding) any non-alphanumberics
# in the supplied string.

sub _percent_encode {
    my ($str) = @_;
    $str =~ s/([^\w])/ uc sprintf '%%%02x', ord $1 /eg;
    return $str;
}

#-------------------------------------------------------------------------------
# _percent_decode -- Percent-decode (like URI decoding) any %XX sequences in
# the supplied string.

sub _percent_decode {
    my ($str) = @_;
    $str =~ s/%([0-9a-fA-F]{2})/ pack( "c",hex( $1 ) ) /ge;
    return $str;
}

#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================

=head1 SUBCLASSING

You can subclass this module to override public functions and change
their behaviour.

=over 4

=item C<extra_session_info()>

This method returns extra fields to add to the session key.
It should return a string consisting of ":field1:field2:field3"
(where each field is preceded by a colon).

The default implementation returns false.

=back

=cut

sub extra_session_info {
    my ( $self, $r, @credentials ) = @_;

    return;
}

#-------------------------------------------------------------------------------
# Take the credentials for a user and check that they match; if so, return
# a new session key for this user that can be stored in the cookie.
# If there is a problem, return a bogus session key.

sub authen_cred {
    my ( $self, $r,        @credentials )       = @_;
    my ( $user, $password, @extra_credentials ) = @credentials;
    my $auth_name = $r->auth_name;
    ( $user, $password ) = _defined_or_empty( $user, $password );

    if ( !length $user ) {
        $r->log_reason(
"Apache::AuthCookieDBI: no username supplied for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    if ( !length $password ) {
        $r->log_reason(
"Apache::AuthCookieDBI: no password supplied for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # get the configuration information.
    my %c = _dbi_config_vars $r;

    # get the crypted password from the users database for this user.
    my $dbh = DBI->connect( $c{DBI_DSN}, $c{DBI_user}, $c{DBI_password} );
    unless ( defined $dbh ) {
        $r->log_reason(
"Apache::AuthCookieDBI: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name",
            $r->uri
        );
        return;
    }
    my $sth = $dbh->prepare( <<"EOS" );
SELECT $c{ DBI_passwordfield }
FROM $c{ DBI_userstable }
WHERE $c{ DBI_userfield } = ?
EOS
    $sth->execute($user);
    my ($crypted_password) = $sth->fetchrow_array;
    unless ( defined $crypted_password ) {
        $r->log_reason(
"Apache::AuthCookieDBI: couldn't select password from $c{ DBI_DSN }, $c{ DBI_userstable }, $c{ DBI_userfield } for user $user for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # now return unless the passwords match.
    if ( lc $c{DBI_crypttype} eq 'none' ) {
        unless ( $password eq $crypted_password ) {
            $r->log_reason(
"Apache::AuthCookieDBI: plaintext passwords didn't match for user $user for auth realm $auth_name",
                $r->uri
            );
            return;
        }
    }
    elsif ( lc $c{DBI_crypttype} eq 'crypt' ) {
        my $salt = substr $crypted_password, 0, 2;
        unless ( crypt( $password, $salt ) eq $crypted_password ) {
            $r->log_reason(
"Apache::AuthCookieDBI: crypted passwords didn't match for user $user for auth realm $auth_name",
                $r->uri
            );
            return;
        }
    }
    elsif ( lc $c{DBI_crypttype} eq 'md5' ) {
        unless ( md5_hex($password) eq $crypted_password ) {
            $r->log_reason(
"Apache::AuthCookieDBI: MD5 passwords didn't match for user $user for auth realm $auth_name",
                $r->uri
            );
            return;
        }
    }

    # Create the expire time for the ticket.
    my $expire_time;

    # expire time in a zillion years if it's forever.
    if ( lc $c{DBI_sessionlifetime} eq 'forever' ) {
        $expire_time = '9999-01-01-01-01-01';
    }
    else {
        my ( $deltaday, $deltahour, $deltaminute, $deltasecond ) =
          split /-/, $c{DBI_sessionlifetime};

        # Figure out the expire time.
        $expire_time = sprintf(
            '%04d-%02d-%02d-%02d-%02d-%02d',
            Add_Delta_DHMS( Today_and_Now, $deltaday, $deltahour,
                $deltaminute, $deltasecond
            )
        );
    }

    # Now we need to %-encode non-alphanumberics in the username so we
    # can stick it in the cookie safely.
    my $enc_user = _percent_encode $user;

    # OK, now we stick the username and the current time and the expire
    # time together to make the public part of the session key:
    my $current_time = _now_year_month_day_hour_minute_second;
    my $public_part  = "$enc_user:$current_time:$expire_time";
    $public_part .= $self->extra_session_info( $r, @credentials );

    # Now we calculate the hash of this and the secret key and then
    # calculate the hash of *that* and the secret key again.
    my $secret_key = $SECRET_KEYS{$auth_name};
    unless ( defined $secret_key ) {
        $r->log_reason(
"Apache::AuthCookieDBI: didn't have the secret key for auth realm $auth_name",
            $r->uri
        );
        return;
    }
    my $hash =
      md5_hex( join ':', $secret_key,
        md5_hex( join ':', $public_part, $secret_key ) );

    # Now we add this hash to the end of the public part.
    my $session_key = "$public_part:$hash";

    # Now we encrypt this and return it.
    my $encrypted_session_key;
    if ( $c{DBI_encryptiontype} eq 'none' ) {
        $encrypted_session_key = $session_key;
    }
    elsif ( lc $c{DBI_encryptiontype} eq 'des' ) {
        $CIPHERS{"des:$auth_name"} ||= Crypt::CBC->new( $secret_key, 'DES' );
        $encrypted_session_key =
          $CIPHERS{"des:$auth_name"}->encrypt_hex($session_key);
    }
    elsif ( lc $c{DBI_encryptiontype} eq 'idea' ) {
        $CIPHERS{"idea:$auth_name"} ||= Crypt::CBC->new( $secret_key, 'IDEA' );
        $encrypted_session_key =
          $CIPHERS{"idea:$auth_name"}->encrypt_hex($session_key);
    }
    elsif ( lc $c{DBI_encryptiontype} eq 'blowfish' ) {
        $CIPHERS{"blowfish:$auth_name"} ||=
          Crypt::CBC->new( $secret_key, 'Blowfish' );
        $encrypted_session_key =
          $CIPHERS{"blowfish:$auth_name"}->encrypt_hex($session_key);
    }

    return $encrypted_session_key;
}

#-------------------------------------------------------------------------------
# Take a session key and check that it is still valid; if so, return the user.

sub authen_ses_key {
    my ( $self, $r, $encrypted_session_key ) = @_;

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = _dbi_config_vars $r;

    # Get the secret key.
    my $secret_key = $SECRET_KEYS{$auth_name};
    unless ( defined $secret_key ) {
        $r->log_reason(
"Apache::AuthCookieDBI: didn't have the secret key from for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # Decrypt the session key.
    my $session_key;
    if ( $c{DBI_encryptiontype} eq 'none' ) {
        $session_key = $encrypted_session_key;
    }
    else {

        # Check that this looks like an encrypted hex-encoded string.
        unless ( $encrypted_session_key =~ /^[0-9a-fA-F]+$/ ) {
            $r->log_reason(
"Apache::AuthCookieDBI: encrypted session key $encrypted_session_key doesn't look like it's properly hex-encoded for auth realm $auth_name",
                $r->uri
            );
            return;
        }

        # Get the cipher from the cache, or create a new one if the
        # cached cipher hasn't been created, & decrypt the session key.
        my $cipher;
        if ( lc $c{DBI_encryptiontype} eq 'des' ) {
            $cipher = $CIPHERS{"des:$auth_name"} ||=
              Crypt::CBC->new( $secret_key, 'DES' );
        }
        elsif ( lc $c{DBI_encryptiontype} eq 'idea' ) {
            $cipher = $CIPHERS{"idea:$auth_name"} ||=
              Crypt::CBC->new( $secret_key, 'IDEA' );
        }
        elsif ( lc $c{DBI_encryptiontype} eq 'blowfish' ) {
            $cipher = $CIPHERS{"blowfish:$auth_name"} ||=
              Crypt::CBC->new( $secret_key, 'Blowfish' );
        }
        elsif ( lc $c{DBI_encryptiontype} eq 'blowfish_pp' ) {
            $cipher = $CIPHERS{"blowfish_pp:$auth_name"} ||=
              Crypt::CBC->new( $secret_key, 'Blowfish_PP' );
        }
        else {
            $r->log_reason(
"Apache::AuthCookieDBI: unknown encryption type $c{ DBI_encryptiontype } for auth realm $auth_name",
                $r->uri
            );
            return;
        }
        $session_key = $cipher->decrypt_hex($encrypted_session_key);
    }

    # Break up the session key.
    my ( $enc_user, $issue_time, $expire_time, @rest ) =
      ( split /:/, $session_key );
    my $supplied_hash = pop @rest;
    ( $enc_user, $issue_time, $expire_time, $supplied_hash ) =
      _defined_or_empty( $enc_user, $issue_time, $expire_time, $supplied_hash );

    # Let's check that we got passed sensible values in the cookie.
    unless ( $enc_user =~ /^[a-zA-Z0-9_\%]+$/ ) {
        $r->log_reason(
"Apache::AuthCookieDBI: bad percent-encoded user $enc_user recovered from session ticket for auth_realm $auth_name",
            $r->uri
        );
        return;
    }

    # decode the user
    my $user = _percent_decode($enc_user);
    unless ( $issue_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
        $r->log_reason(
"Apache::AuthCookieDBI: bad issue time $issue_time recovered from ticket for user $user for auth_realm $auth_name",
            $r->uri
        );
        return;
    }
    unless ( $expire_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
        $r->log_reason(
"Apache::AuthCookieDBI: bad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name",
            $r->uri
        );
        return;
    }
    unless ( $supplied_hash =~ /^[0-9a-fA-F]{32}$/ ) {
        $r->log_reason(
"Apache::AuthCookieDBI: bad hash $supplied_hash recovered from ticket for user $user for auth_realm $auth_name",
            $r->uri
        );
        return;
    }

    # Calculate the hash of the user, issue time, expire_time and
    # the secret key and then the hash of that and the secret key again.
    my $hash = md5_hex(
        join ':',
        $secret_key,
        md5_hex(
            join ':',     $enc_user, $issue_time,
            $expire_time, @rest,     $secret_key
        )
    );

    # Compare it to the hash they gave us.
    unless ( $hash eq $supplied_hash ) {
        $r->log_reason(
"Apache::AuthCookieDBI: hash in cookie did not match calculated hash of contents for user $user for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # Check that their session hasn't timed out.
    if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
        $r->log_reason(
"Apache:AuthCookieDBI: expire time $expire_time has passed for user $user for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # If we're being paranoid about timing-out long-lived sessions,
    # check that the issue time + the current (server-set) session lifetime
    # hasn't passed too (in case we issued long-lived session tickets
    # in the past that we want to get rid of). *** TODO ***
    # if ( lc $c{ DBI_AlwaysUseCurrentSessionLifetime } eq 'on' ) {

    # They must be okay, so return the user.
    return $user;
}

#-------------------------------------------------------------------------------
# Take a list of groups and make sure that the current remote user is a member
# of one of them.

sub group {
    my ( $self, $r, @groups ) = @_;

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = _dbi_config_vars $r;

    my $user = $r->connection->user;

    # See if we have a row in the groups table for this user/group.
    my $dbh = DBI->connect( $c{DBI_DSN}, $c{DBI_user}, $c{DBI_password} );
    unless ( defined $dbh ) {
        $r->log_reason(
"Apache::AuthCookieDBI: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name",
            $r->uri
        );
        return;
    }

    # Now loop through all the groups to see if we're a member of any:
    my $sth = $dbh->prepare( <<"EOS" );
SELECT $c{ DBI_groupuserfield }
FROM $c{ DBI_groupstable }
WHERE $c{ DBI_groupfield } = ?
AND $c{ DBI_groupuserfield } = ?
EOS
    foreach my $group (@groups) {
        $sth->execute( $group, $user );
        return OK if ( $sth->fetchrow_array );
    }
    $r->log_reason(
"Apache::AuthCookieDBI: user $user was not a member of any of the required groups @groups for auth realm $auth_name",
        $r->uri
    );
    return FORBIDDEN;
}

# Takes a list and returns a list of the same size.
# Any element in the inputs that is defined is returned unchanged. Elements that
# were undef are returned as empty strings.
sub _defined_or_empty {
    my @args        = @_;
    my @all_defined = ();
    for ( my $i = 0 ; $i < scalar @args ; $i++ ) {
        my $arg = $args[$i];
        if ( defined $arg ) {
            push @all_defined, $arg;
        }
        else {
            push @all_defined, $EMPTY_STRING;
        }
    }
    return @all_defined;
}

1;
__END__

=back

=head1 DATABASE SCHEMAS

For this module to work, the database tables must be laid out at least somewhat
according to the following rules:  the user field must be a primary key
so there is only one row per user; the password field must be NOT NULL.  If
you're using MD5 passwords the password field must be 32 characters long to
allow enough space for the output of md5_hex().  If you're using crypt()
passwords you need to allow 13 characters.

An minimal CREATE TABLE statement might look like:

	CREATE TABLE users (
		user VARCHAR(16) PRIMARY KEY,
		password VARCHAR(32) NOT NULL
	)

For the groups table, the access table is actually going to be a join table
between the users table and a table in which there is one row per group
if you have more per-group data to store; if all you care about is group
membership though, you only need this one table.  The only constraints on
this table are that the user and group fields be NOT NULL.

A minimal CREATE TABLE statement might look like:

	CREATE TABLE groups (
		grp VARCHAR(16) NOT NULL,
		user VARCHAR(16) NOT NULL
	)

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

Jacob Davies

        <jacob@well.com>

=head1 SEE ALSO

Apache::AuthCookie(1)

=cut
