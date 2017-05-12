#===============================================================================
#
# Apache::AuthCookieLDAP
#
# An AuthCookie module backed by a LDAP database.
#
# Based on Apache::AuthCookieDBI by Jacob Davies <jacob@sfinteractive.com> <jacob@well.com>
#
# Author:  Bjorn Ardo <f98ba@efd.lth.se>
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
#
#===============================================================================

package Apache::AuthCookieLDAP;

use strict;
use 5.004;
use vars qw( $VERSION );
( $VERSION ) = '$Revision: 0.03 $' =~ /([\d.]+)/;

use Apache::AuthCookie;
use vars qw( @ISA );
@ISA = qw( Apache::AuthCookie );

use Apache;
use Apache::Constants;
use Apache::File;
use Digest::MD5 qw( md5_hex );
use Date::Calc qw( Today_and_Now Add_Delta_DHMS );
# Also uses Crypt::CBC if you're using encrypted cookies.
use Net::LDAP qw(LDAP_SUCCESS);

#===============================================================================
# F U N C T I O N   D E C L A R A T I O N S
#===============================================================================

sub _log_not_set($$);
sub _dir_config_var($$);
sub _dbi_config_vars($);
sub _now_year_month_day_hour_minute_second();
sub _percent_encode($);
sub _percent_decode($);

sub authen_cred($$\@);
sub authen_ses_key($$$);
sub group($$$);

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
	my @keyfile_vars = grep {
		$_ =~ /LDAP_SecretKeyFile$/
	} keys %{ Apache->server->dir_config() };
	foreach my $keyfile_var ( @keyfile_vars ) {
		my $keyfile = Apache->server->dir_config( $keyfile_var );
		my $auth_name = $keyfile_var;
		$auth_name =~ s/LDAP_SecretKeyFile$//;
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

Apache::AuthCookieLDAP - An AuthCookie module backed by a LDAP database.

=head1 VERSION

	$Revision: 0.02 $

=head1 SYNOPSIS

Not correct!!!


	# In httpd.conf or .htaccess
	PerlModule Apache::AuthCookieLDAP
	PerlSetVar WhatEverPath /
	PerlSetVar WhatEverLoginScript /login.pl

	# Optional, to share tickets between servers.
	PerlSetVar WhatEverDomain .domain.com
	
	# These must be set
	PerlSetVar WhatEverLDAP_DN "o=foo.com"
	PerlSetVar WhatEverLDAP_SecretKeyFile /etc/httpd/acme.com.key
	PerlSetVar WhatEverLDAP_User uid


	# These are optional, the module sets sensible defaults.

	PerlSetVar WhatEverLDAP_filter F=on
	PerlSetVar WhatEverDBI_GroupsTable "groups"
	PerlSetVar WhatEverDBI_GroupField "grp"
	PerlSetVar WhatEverDBI_GroupUserField "user"

	PerlSetVar WhatEverLDAP_host ldap.bank.com
	PerlSetVar WhatEverLDAP_EncryptionType "none"
	PerlSetVar WhatEverLDAP_SessionLifetime 00-24-00-00

	# Protected by AuthCookieLDAP.
	<Directory /www/domain.com/authcookieldap>
		AuthType Apache::AuthCookieLDAP
		AuthName WhatEver
		PerlAuthenHandler Apache::AuthCookieLDAP->authenticate
		PerlAuthzHandler Apache::AuthCookieLDAP->authorize
		require valid-user
		# or you can require users:
		require user jacob

		# You can optionally require groups.
		require group system
	</Directory>

	# Login location.  *** DEBUG *** I still think this is screwy
	<Files LOGIN>
		AuthType Apache::AuthCookieLDAP
		AuthName WhatEver
		SetHandler perl-script
		PerlHandler Apache::AuthCookieLDAP->login
	</Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism provided
by Apache::AuthCookie with a LDAP database for ticket-based protection.  It
is based on two tokens being provided, a username and password, which can
be any strings (there are no illegal characters for either).  The username is
used to set the remote user as if Basic Authentication was used.

On an attempt to access a protected location without a valid cookie being
provided, the module prints an HTML login form (produced by a CGI or any
other handler; this can be a static file if you want to always send people
to the same entry page when they log in).  This login form has fields for
username and password.  On submitting it, the username and password are looked
up in the LDAP database. If this succeeds, the user is issued
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
user jacob" settings are passed. If all these
checks pass, the document requested is displayed.

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
	my $auth_name = $r->auth_name;
	$r->log_error( "Apache::AuthCookieLDAP: $variable not set for auth realm
$auth_name", $r->uri );
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.

sub _dir_config_var($$)
{
	my( $r, $variable ) = @_;
	my $auth_name = $r->auth_name;
	return $r->dir_config( "$auth_name$variable" );
}

#-------------------------------------------------------------------------------
# _dbi_config_vars -- Gets the config variables from the dir_config and logs
# errors if required fields were not set, returns undef if any of the fields
# had errors or a hash of the values if they were all OK.  Takes a request
# object.

sub _dbi_config_vars($)
{
	my( $r ) = @_;

	my %c; # config variables hash

=head1 APACHE CONFIGURATION DIRECTIVES


All configuration directives for this module are passed in PerlSetVars.  These
PerlSetVars must begin with the AuthName that you are describing, so if your
AuthName is PrivateBankingSystem they will look like:

	PerlSetVar PrivateBankingSystemLDAP_DN "o=bank.com"

See also L<Apache::Authcookie> for the directives required for any kind
of Apache::AuthCookie-based authentication system.

In the following descriptions, replace "WhatEver" with your particular
AuthName.  The available configuration directives are as follows:

=over 4

=item C<WhatEverLDAP_DN>

Specifies the BaseDN for LDAP for the database you wish to connect to retrieve
user information.  This is required and has no default value.

=cut

	unless ( $c{ LDAP_DN } = _dir_config_var $r, 'LDAP_DN' ) {
		_log_not_set $r, 'LDAP_DN';
		return undef;
	}

=item C<WhatEverLDAP_user>

Specifies the user id in the database you wish to connect to retrieve
user information.  This is required and has no default value.

=cut

	unless ( $c{ LDAP_user } = _dir_config_var $r, 'LDAP_user' ) {
		_log_not_set $r, 'LDAP_user';
		return undef;
	}

=item C<WhatEverLDAP_host>
The host to connect to.  This is not required and defaults to localhost.


=cut

	$c{ LDAP_host       } = _dir_config_var( $r, 'LDAP_host'       )
	            || "localhost";




=item C<WhatEverLDAP_filter>
An extra filter for the search for the user. Is not required


=cut

	$c{ LDAP_filter       } = _dir_config_var( $r, 'LDAP_filter') || "";



=item C<WhatEverLDAP_SecretKeyFile>

The file that contains the secret key (on the first line of the file).  This
is required and has no default value.  This key should be owned and only
readable by root.  It is read at server startup time.
The key should be long and fairly random.  If you want, you
can change it and restart the server, (maybe daily), which will invalidate
all prior-issued tickets.

=cut

	unless (
	   $c{ LDAP_secretkeyfile } = _dir_config_var $r, 'LDAP_SecretKeyFile'
	) {
		_log_not_set $r, 'LDAP_SecretKeyFile';
		return undef;
	}

=item C<WhatEverLDAP_EncryptionType>

What kind of encryption to use to prevent the user from looking at the fields
in the ticket we give them.  This is almost completely useless, so don't
switch it on unless you really know you need it.  It does not provide any
protection of the password in transport; use SSL for that.  It can be 'none',
'des', 'idea', 'blowfish', or 'blowfish_pp'.

This is not required and defaults to 'none'.

=cut

	$c{ LDAP_encryptiontype } = _dir_config_var( $r, 'LDAP_EncryptionType' )
	            || 'none';
	# If we used encryption we need to pull in Crypt::CBC.
	if ( $c{ LDAP_encryptiontype } ne 'none' ) {
		require Crypt::CBC;
	}

=item C<WhatEverLDAP_SessionLifetime>

How long tickets are good for after being issued.  Note that presently
Apache::AuthCookie does not set a client-side expire time, which means that
most clients will only keep the cookie until the user quits the browser.
However, if you wish to force people to log in again sooner than that, set
this value.  This can be 'forever' or a life time specified as:

	DD-hh-mm-ss -- Days, hours, minute and seconds to live.

This is not required and defaults to '00-24-00-00' or 24 hours.

=cut

	$c{ LDAP_sessionlifetime }
	   = _dir_config_var( $r, 'LDAP_SessionLifetime' ) || '00-24-00-00';






## This is for some leftover DBI code:

=item C<WhatEverDBI_DSN>

Specifies the DSN for DBI for the database you wish to connect to retrieve
user information.  This is required and has no default value.

=cut

        unless ( $c{ DBI_DSN } = _dir_config_var $r, 'DBI_DSN' ) {
                _log_not_set $r, 'DBI_DSN';
                return undef;
        }

=item C<WhatEverDBI_User>

The user to log into the database as.  This is not required and
defaults to undef.

=cut

        $c{ DBI_user           } = _dir_config_var( $r, 'DBI_User')
                    || undef;

=item C<WhatEverDBI_Password>

The password to use to access the database.  This is not required
and defaults to undef.

=cut

        $c{ DBI_password       } = _dir_config_var( $r, 'DBI_Password' )
                    || undef;



=item C<WhatEverDBI_GroupsTable>

The table that has the user / group information.  This is not required and
defaults to 'groups'.

=cut

        $c{ DBI_groupstable    } = _dir_config_var( $r, 'DBI_GroupsTable')
                    || 'groups';

=item C<WhatEverDBI_GroupField>

The field in the above table that has the group name.  This is not required
and defaults to 'grp' (to prevent conflicts with the SQL reserved word
'group').

=cut

        $c{ DBI_groupfield     } = _dir_config_var( $r, 'DBI_GroupField')
                    || 'grp';

=item C<WhatEverDBI_GroupUserField>

The field in the above table that has the user name.  This is not required
and defaults to 'user'.

=cut

        $c{ DBI_groupuserfield } = _dir_config_var( $r, 'DBI_GroupUserField' )
                    || 'user';





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
	my( $self, $r, @credentials ) = @_;

	my $auth_name = $r->auth_name;

	# Username goes in credential_0
	my $user = $credentials[ 0 ];
	unless ( $user =~ /^.+$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: no username supplied for auth realm $auth_name", $r->uri );
		return 'bad';
	}
	# Password goes in credential_1
	my $password = $credentials[ 1 ];
	unless ( $password =~ /^.+$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: no password supplied for auth realm $auth_name", $r->uri );
		return 'bad';
	}

	# get the configuration information.
	my %c = _dbi_config_vars $r;




	# Connect to the host
	my $con;
	unless ($con = Net::LDAP->new($c{LDAP_host}))
	{
	    $r->log_reason("LDAP Connection Failed", $r->uri);
	    return 'bad';
	}
		
	# Bind annonymously


	my $mess = $con->bind();
	unless ($mess->code == LDAP_SUCCESS) {
	    $r->log_reason("LDAP Bind Failed", $r->uri);
	    return 'bad';
	}


	# Search for the user
	my $filter = "($c{LDAP_user}=$user)";
	if($c{LDAP_filter} ne "")
	{
	 $filter = "(& $filter ($c{LDAP_filter}))";
	}	
	$mess = $con->search(base => $c{LDAP_DN}, filter => $filter);
	unless ($mess->code == LDAP_SUCCESS) {
	    $r->log_reason("LDAP Search Failed", $r->uri);
	    return 'bad';
	}


	# Does the user exsists
	unless ($mess->count) {
	    $r->log_reason("User: $user does not excist", $r->uri);
	    return 'bad';
	}
  
	# Take the first user
	my $entry = $mess->first_entry;
	my $dn = $entry->dn;

	# Bind as the user we're authenticating
	$mess = $con->bind($dn, password => $password);
	unless ($mess->code == LDAP_SUCCESS) {
	    $r->log_reason("User $user har wrong password", $r->uri);
	    return 'bad';
	}
	$con->unbind;



	# Create the expire time for the ticket.
	my $expire_time;
	# expire time in a zillion years if it's forever.
	if ( lc $c{ LDAP_sessionlifetime } eq 'forever' ) {
		$expire_time = '9999-01-01-01-01-01';
	} else {
		my( $deltaday, $deltahour, $deltaminute, $deltasecond )
		   = split /-/, $c{ LDAP_sessionlifetime };
		# Figure out the expire time.
		$expire_time = sprintf(
			'%04d-%02d-%02d-%02d-%02d-%02d',
			Add_Delta_DHMS( Today_and_Now,
			                $deltaday, $deltahour,
					$deltaminute, $deltasecond )
		);
	}

	# Now we need to %-encode non-alphanumberics in the username so we
	# can stick it in the cookie safely.  *** DEBUG *** check this
	my $enc_user = _percent_encode $user;

	# OK, now we stick the username and the current time and the expire
	# time together to make the public part of the session key:
	my $current_time = _now_year_month_day_hour_minute_second;
	my $public_part = "$enc_user:$current_time:$expire_time";

	# Now we calculate the hash of this and the secret key and then
	# calculate the hash of *that* and the secret key again.
	my $secret_key = $SECRET_KEYS{ $auth_name };
	unless ( defined $secret_key ) {
		$r->log_reason( "Apache::AuthCookieLDAP: didn't have the secret key for auth realm $auth_name", $r->uri );
		return 'bad';
	}
	my $hash = md5_hex( join ':', $secret_key, md5_hex(
		join ':', $public_part, $secret_key
	) );

	# Now we add this hash to the end of the public part.
	my $session_key = "$public_part:$hash";

	# Now we encrypt this and return it.
	my $encrypted_session_key;
	if ( $c{ LDAP_encryptiontype } eq 'none' ) {
		$encrypted_session_key = $session_key;
	} elsif ( lc $c{ LDAP_encryptiontype } eq 'des'      ) {
		$CIPHERS{ "des:$auth_name"      }
		   ||= Crypt::CBC->new( $secret_key, 'DES'      );
		$encrypted_session_key = $CIPHERS{
			"des:$auth_name"
		}->encrypt_hex( $session_key );
	} elsif ( lc $c{ LDAP_encryptiontype } eq 'idea'     ) {
		$CIPHERS{ "idea:$auth_name"      }
		   ||= Crypt::CBC->new( $secret_key, 'IDEA'     );
		$encrypted_session_key = $CIPHERS{
			"idea:$auth_name"
		}->encrypt_hex( $session_key );
	} elsif ( lc $c{ LDAP_encryptiontype } eq 'blowfish' ) {
		$CIPHERS{ "blowfish:$auth_name" }
		   ||= Crypt::CBC->new( $secret_key, 'Blowfish' );
		$encrypted_session_key = $CIPHERS{
			"blowfish:$auth_name"
		}->encrypt_hex( $session_key );
	}

	return $encrypted_session_key;
}

#-------------------------------------------------------------------------------
# Take a session key and check that it is still valid; if so, return the user.

sub authen_ses_key($$$)
{
	my( $self, $r, $encrypted_session_key ) = @_;

	my $auth_name = $r->auth_name;

	# Get the configuration information.
	my %c = _dbi_config_vars $r;

	# Get the secret key.
	my $secret_key = $SECRET_KEYS{ $auth_name };
	unless ( defined $secret_key ) {
		$r->log_reason( "Apache::AuthCookieLDAP: didn't the secret key from for auth realm $auth_name", $r->uri );
		return undef;
	}
	
	# Decrypt the session key.
	my $session_key;
	if ( $c{ LDAP_encryptiontype } eq 'none' ) {
		$session_key = $encrypted_session_key;
	} else {
		# Check that this looks like an encrypted hex-encoded string.
		unless ( $encrypted_session_key =~ /^[0-9a-fA-F]+$/ ) {
			$r->log_reason( "Apache::AuthCookieLDAP: encrypted session key $encrypted_session_key doesn't look like it's properly hex-encoded for auth realm $auth_name", $r->uri );
			return undef;
		}

		# Get the cipher from the cache, or create a new one if the
		# cached cipher hasn't been created, & decrypt the session key.
		my $cipher;
		if ( lc $c{ LDAP_encryptiontype } eq 'des' ) {
			$cipher = $CIPHERS{ "des:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'DES' );
		} elsif ( lc $c{ LDAP_encryptiontype } eq 'idea' ) {
			$cipher = $CIPHERS{ "idea:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'IDEA' );
		} elsif ( lc $c{ LDAP_encryptiontype } eq 'blowfish' ) {
			$cipher = $CIPHERS{ "blowfish:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'Blowfish' );
		} elsif ( lc $c{ LDAP_encryptiontype } eq 'blowfish_pp' ) {
			$cipher = $CIPHERS{ "blowfish_pp:$auth_name" }
			   ||= Crypt::CBC->new( $secret_key, 'Blowfish_PP' );
		} else {
			$r->log_reason( "Apache::AuthCookieLDAP: unknown encryption type $c{ LDAP_encryptiontype } for auth realm $auth_name", $r->uri );
			return undef;
		}
		$session_key = $cipher->decrypt_hex( $encrypted_session_key );
	}
	
	# Break up the session key.
	my( $enc_user, $issue_time, $expire_time, $supplied_hash )
	   = split /:/, $session_key;
	# Let's check that we got passed sensible values in the cookie.
	unless ( $enc_user =~ /^[a-zA-Z0-9_\%]+$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: bad percent-encoded user $enc_user recovered from session ticket for auth_realm $auth_name", $r->uri );
		return undef;
	}
	# decode the user
	my $user = _percent_decode $enc_user;
	unless ( $issue_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: bad issue time $issue_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}
	unless ( $expire_time =~ /^\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2}$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: bad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}
	unless ( $supplied_hash =~ /^[0-9a-fA-F]{32}$/ ) {
		$r->log_reason( "Apache::AuthCookieLDAP: bad hash $supplied_hash recovered from ticket for user $user for auth_realm $auth_name", $r->uri );
		return undef;
	}

	# Calculate the hash of the user, issue time, expire_time and
	# the secret key and then the hash of that and the secret key again.
	my $hash = md5_hex( join ':', $secret_key, md5_hex(
		join ':', $enc_user, $issue_time, $expire_time, $secret_key
	) );

	# Compare it to the hash they gave us.
	unless ( $hash eq $supplied_hash ) {
		$r->log_reason( "Apache::AuthCookieLDAP: hash in cookie did not match calculated hash of contents for user $user for auth realm $auth_name", $r->uri );
		return undef;
	}

	# Check that their session hasn't timed out.
	if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
		$r->log_reason( "Apache:AuthCookieLDAP: expire time $expire_time has passed for user $user for auth realm $auth_name", $r->uri );
		return undef;
	}

	# If we're being paranoid about timing-out long-lived sessions,
	# check that the issue time + the current (server-set) session lifetime
	# hasn't passed too (in case we issued long-lived session tickets
	# in the past that we want to get rid of). *** DEBUG ***
	# if ( lc $c{ DBI_AlwaysUseCurrentSessionLifetime } eq 'on' ) {

	# They must be okay, so return the user.
	return $user;
}

###########################################################################
# This is taken from AuthCookieDBI and checks user groups from a database #
###########################################################################



sub group($$$)
{
        my( $self, $r, $groups ) = @_;
	my @groups = split(/\s+/, $groups);

        my $auth_name = $r->auth_name;

        # Get the configuration information.
        my %c = _dbi_config_vars $r;

        my $user = $r->connection->user;

        # See if we have a row in the groups table for this user/group.
        my $dbh = DBI->connect( $c{ DBI_DSN },
                                $c{ DBI_user }, $c{ DBI_password } );
        unless ( defined $dbh ) {
                $r->log_reason( "Apache::AuthCookieDBI: couldn't connect to $c{ DBI_DSN } for auth realm $auth_name", $r->uri );
                return undef;
        }

        # Now loop through all the groups to see if we're a member of any:
        my $sth = $dbh->prepare( <<"EOS" );
SELECT $c{ DBI_groupuserfield }
FROM $c{ DBI_groupstable }
WHERE $c{ DBI_groupfield } = ?
AND $c{ DBI_groupuserfield } = ?
EOS
        foreach my $group ( @groups ) {
                $sth->execute( $group, $user );
                return OK if ( $sth->fetchrow_array );
        }
        $r->log_reason( "Apache::AuthCookieDBI: user $user was not a member of any of the required groups @groups  for auth realm $auth_name", $r->uri );
        return FORBIDDEN;
}




1;
__END__

=back


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

Bjorn Ardo

        <f98ba@efd.lth.se>

=head1 SEE ALSO

Apache::AuthCookie(1)

=cut


