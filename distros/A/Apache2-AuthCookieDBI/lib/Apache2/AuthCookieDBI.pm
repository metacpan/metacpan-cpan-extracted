#===============================================================================
#
# $Id: AuthCookieDBI.pm,v 1.60 2011/03/12 20:14:41 matisse Exp $
#
# Apache2::AuthCookieDBI
#
# An AuthCookie module backed by a DBI database.
#
# See end of this file for Copyright notices.
#
# Author:  Jacob Davies <jacob@well.com>
# Maintainer: Matisse Enzer <matisse@cpan.org> (as of version 2.0)
#
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

package Apache2::AuthCookieDBI;

use strict;
use warnings;
use 5.010_000;
our $VERSION = '2.18';

use Apache2::AuthCookie;
use base qw( Apache2::AuthCookie );

use Apache2::RequestRec;
use DBI;
use Apache2::Log;
use Apache2::Const -compile => qw( OK HTTP_FORBIDDEN SERVER_ERROR :log );
use Apache2::ServerUtil;
use Carp qw();
use Digest::MD5 qw( md5_hex );
use Date::Calc qw( Today_and_Now Add_Delta_DHMS );

# Also uses Crypt::CBC if you're using encrypted cookies.
# Also uses Apache2::Session if you're using sessions.
use English qw(-no_match_vars);

#===============================================================================
# FILE (LEXICAL)  G L O B A L S
#===============================================================================

my %CIPHERS = ();

# Stores Cipher::CBC objects in $CIPHERS{ idea:AuthName },
# $CIPHERS{ des:AuthName } etc.

use constant COLON_REGEX => qr/ : /mx;
use constant DATE_TIME_STRING_REGEX =>
    qr/ \A \d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2} \z /mx;
use constant EMPTY_STRING                 => q{};
use constant HEX_STRING_REGEX             => qr/ \A [0-9a-fA-F]+ \z /mx;
use constant HYPHEN_REGEX                 => qr/ - /mx;
use constant PERCENT_ENCODED_STRING_REGEX => qr/ \A [a-zA-Z0-9_\%]+ \z /mx;
use constant THIRTY_TWO_CHARACTER_HEX_STRING_REGEX =>
    qr/  \A [0-9a-fA-F]{32} \z /mx;
use constant TRUE             => 1;
use constant WHITESPACE_REGEX => qr/ \s+ /mx;
use constant LOG_TYPE_AUTH    => 'authentication';
use constant LOG_TYPE_SYSTEM  => 'system';
use constant LOG_TYPE_TIMEOUT => 'timeout';

#===============================================================================
# P E R L D O C
#===============================================================================

=head1 NAME

Apache2::AuthCookieDBI - An AuthCookie module backed by a DBI database.

=head1 VERSION

    This is version 2.14

=head1 COMPATIBILITY

Starting with version 2.03 the module is in the Apache2::* namespace,
L<Apache2::AuthCookieDBI>.  For F<mod_perl1> versions
there is: L<Apache::AuthCookieDBI>

=head1 SYNOPSIS

    # In httpd.conf or .htaccess
    
    # Optional: Initiate a persistent database connection using Apache::DBI.
    # See: http://search.cpan.org/dist/Apache-DBI/
    # If you choose to use Apache::DBI then the following directive must come
    # before all other modules using DBI - just uncomment the next line:
    #PerlModule Apache::DBI  
   
     
    PerlModule Apache2::AuthCookieDBI
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
    PerlSetVar WhatEverDBI_UserActiveField "" # Default is skip this feature
    PerlSetVar WhatEverDBI_CryptType "none"
    PerlSetVar WhatEverDBI_GroupsTable "groups"
    PerlSetVar WhatEverDBI_GroupField "grp"
    PerlSetVar WhatEverDBI_GroupUserField "user"
    PerlSetVar WhatEverDBI_EncryptionType "none"
    PerlSetVar WhatEverDBI_SessionLifetime 00-24-00-00

    # Protected by AuthCookieDBI.
    <Directory /www/domain.com/authcookiedbi>
        AuthType Apache2::AuthCookieDBI
        AuthName WhatEver
        PerlAuthenHandler Apache2::AuthCookieDBI->authenticate
        PerlAuthzHandler Apache2::AuthCookieDBI->authorize
        require valid-user
        # or you can require users:
        require user jacob
        # You can optionally require groups.
        require group system
    </Directory>

    # Login location.
    <Files LOGIN>
        AuthType Apache2::AuthCookieDBI
        AuthName WhatEver
        SetHandler perl-script
        PerlHandler Apache2::AuthCookieDBI->login

        # If the directopry you are protecting is the DocumentRoot directory
        # then uncomment the following directive:
        #Satisfy any
    </Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism provided
by Apache2::AuthCookie with a DBI database for ticket-based protection.  It
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

# Get the cipher from the cache, or create a new one if the
# cached cipher hasn't been created.
sub _get_cipher_for_type {
    my ( $class, $dbi_encryption_type, $auth_name, $secret_key ) = @_;
    my $lc_encryption_type = lc $dbi_encryption_type;
    my $message;

    if ( exists $CIPHERS{"$lc_encryption_type:$auth_name"} ) {
        return $CIPHERS{"$lc_encryption_type:$auth_name"};
    }

    my %cipher_for_type = (
        des => sub {
            return $CIPHERS{"des:$auth_name"}
                || Crypt::CBC->new( -key => $secret_key, -cipher => 'DES' );
        },
        idea => sub {
            return $CIPHERS{"idea:$auth_name"}
                || Crypt::CBC->new( -key => $secret_key, -cipher => 'IDEA' );
        },
        blowfish => sub {
            return $CIPHERS{"blowfish:$auth_name"}
                || Crypt::CBC->new(
                -key    => $secret_key,
                -cipher => 'Blowfish'
                );
        },
        blowfish_pp => sub {
            return $CIPHERS{"blowfish_pp:$auth_name"}
                || Crypt::CBC->new(
                -key    => $secret_key,
                -cipher => 'Blowfish_PP'
                );
        },
    );
    my $code_ref = $cipher_for_type{$lc_encryption_type}
        || Carp::confess("Unsupported encryption type: '$dbi_encryption_type'");
    my $cbc_object = $code_ref->();

    # Cache the object. Caught bug where we were not, thanks to unit tests.
    $CIPHERS{"$lc_encryption_type:$auth_name"} = $cbc_object;

    return $cbc_object;
}

sub _encrypt_session_key {
    my $class               = shift;
    my $session_key         = shift;
    my $secret_key          = shift;
    my $auth_name           = shift;
    my $dbi_encryption_type = lc shift;
    my $message;

    if ( !defined $dbi_encryption_type ) {
        Carp::confess('$dbi_encryption_type must be defined.');
    }

    if ( $dbi_encryption_type eq 'none' ) {
        return $session_key;
    }

    my $cipher = $class->_get_cipher_for_type( $dbi_encryption_type, $auth_name,
        $secret_key );
    my $encrypted_key = $cipher->encrypt_hex($session_key);
    return $encrypted_key;
}

#-------------------------------------------------------------------------------
# _log_not_set -- Log that a particular authentication variable was not set.

sub _log_not_set {
    my ( $class, $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    my $message   = "${class}\t$variable not set for auth realm $auth_name";
    $class->logger( $r, Apache2::Const::LOG_ERR, $message, undef,
        LOG_TYPE_SYSTEM, $r->uri );
    return;
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.

sub _dir_config_var {
    my ( $class, $r, $variable ) = @_;
    my $auth_name = $r->auth_name;
    return $r->dir_config("$auth_name$variable");
}

#-------------------------------------------------------------------------------
# _dbi_config_vars -- Gets the config variables from the dir_config and logs
# errors if required fields were not set, returns undef if any of the fields
# had errors or a hash of the values if they were all OK.  Takes a request
# object.

my %CONFIG_DEFAULT = (
    DBI_DSN             => undef,
    DBI_SecretKey       => undef,
    DBI_User            => undef,
    DBI_Password        => undef,
    DBI_UsersTable      => 'users',
    DBI_UserField       => 'user',
    DBI_PasswordField   => 'password',
    DBI_UserActiveField => EMPTY_STRING,    # Default is don't use this feature
    DBI_CryptType       => 'none',
    DBI_GroupsTable     => 'groups',
    DBI_GroupField      => 'grp',
    DBI_GroupUserField  => 'user',
    DBI_EncryptionType  => 'none',
    DBI_SessionLifetime => '00-24-00-00',
    DBI_sessionmodule   => 'none',
);

sub _dbi_config_vars {
    my ( $class, $r ) = @_;

    my %c;    # config variables hash
    foreach my $variable ( keys %CONFIG_DEFAULT ) {
        my $value_from_config = $class->_dir_config_var( $r, $variable );
        $c{$variable}
            = defined $value_from_config
            ? $value_from_config
            : $CONFIG_DEFAULT{$variable};
        if ( !defined $c{$variable} ) {
            $class->_log_not_set( $r, $variable );
        }
    }

    # If we used encryption we need to pull in Crypt::CBC.
    if ( $c{'DBI_EncryptionType'} ne 'none' ) {
        require Crypt::CBC;
    }

    # Compile module for password encryption, if needed.
    if ( $c{'DBI_CryptType'} =~ /^sha/ ) {
        require Digest::SHA;
    }

    return %c;
}

=head1 APACHE CONFIGURATION DIRECTIVES

All configuration directives for this module are passed in PerlSetVars.  These
PerlSetVars must begin with the AuthName that you are describing, so if your
AuthName is PrivateBankingSystem they will look like:

    PerlSetVar PrivateBankingSystemDBI_DSN "DBI:mysql:database=banking"

See also L<Apache2::Authcookie> for the directives required for any kind
of Apache2::AuthCookie-based authentication system.

In the following descriptions, replace "WhatEver" with your particular
AuthName.  The available configuration directives are as follows:

=over 4

=item C<WhatEverDBI_DSN>

Specifies the DSN for DBI for the database you wish to connect to retrieve
user information.  This is required and has no default value.

=item C<WhateverDBI_SecretKey>

Specifies the secret key for this auth scheme.  This should be a long
random string.  This should be secret; either make the httpd.conf file
only readable by root, or put the PerlSetVar in a file only readable by
root and include it.

This is required and has no default value.  (NOTE: In AuthCookieDBI versions
1.22 and earlier the secret key either could be set in the configuration file
itself or it could be placed in a separate file with the path configured with
C<PerlSetVar WhateverDBI_SecretKeyFile>.

As of version 2.0, you must use C<WhateverDBI_SecretKey> and not
C<PerlSetVar WhateverDBI_SecretKeyFile>.

If you want to put the secret key in a separate file then you can create a
separate file that uses C<PerlSetVar WhateverDBI_SecretKey> and include that
file in your main Apache configuration using Apaches' C<Include>
directive. You might wish to make the file not
world-readable. Also, make sure that the Perl environment variables are
not publically available, for example via the /perl-status handler.)
See also L</"COMPATIBILITY"> in this man page.


=item C<WhatEverDBI_User>

The user to log into the database as.  This is not required and
defaults to undef.

=item C<WhatEverDBI_Password>

The password to use to access the database.  This is not required
and defaults to undef.

Make sure that the Perl environment variables are
not publically available, for example via the /perl-status handler since the
password could be exposed.

=item C<WhatEverDBI_UsersTable>

The table that user names and passwords are stored in.  This is not
required and defaults to 'users'.

=item C<WhatEverDBI_UserField>

The field in the above table that has the user name.  This is not
required and defaults to 'user'.

=item C<WhatEverDBI_PasswordField>

The field in the above table that has the password.  This is not
required and defaults to 'password'.

=item C<WhatEverDBI_UserActiveField>

The field in the users' table that has a value indicating if the users' account
is "active".  This is optional and the default is to not use this field.
If used then users will fail authentication if the value in this field
is not a Perlish true value, so NULL, 0, and the empty string are all false
values. The I<user_is_active> class method exposes this setting (and may be
overidden in a subclass.)

=item C<WhatEverDBI_CryptType>

What kind of hashing is used on the password field in the database.  This can
be 'none', 'crypt', 'md5', 'sha256', 'sha384', or 'sha512'.

C<md5> will use Digest::MD5::md5hex() and C<sha...> will use
Digest::SHA::sha{n}_hex().

This is not required and defaults to 'none'.

=item C<WhatEverDBI_GroupsTable>

The table that has the user / group information.  This is not required and
defaults to 'groups'.

=item C<WhatEverDBI_GroupField>

The field in the above table that has the group name.  This is not required
and defaults to 'grp' (to prevent conflicts with the SQL reserved word 'group').

=item C<WhatEverDBI_GroupUserField>

The field in the above table that has the user name.  This is not required
and defaults to 'user'.

=item C<WhatEverDBI_EncryptionType>

What kind of encryption to use to prevent the user from looking at the fields
in the ticket we give them.  This is almost completely useless, so don't
switch it on unless you really know you need it.  It does not provide any
protection of the password in transport; use SSL for that.  It can be 'none',
'des', 'idea', 'blowfish', or 'blowfish_pp'.

This is not required and defaults to 'none'.

=item C<WhatEverDBI_SessionLifetime>

How long tickets are good for after being issued.  Note that presently
Apache2::AuthCookie does not set a client-side expire time, which means that
most clients will only keep the cookie until the user quits the browser.
However, if you wish to force people to log in again sooner than that, set
this value.  This can be 'forever' or a life time specified as:

    DD-hh-mm-ss -- Days, hours, minute and seconds to live.

This is not required and defaults to '00-24-00-00' or 24 hours.

=item C<WhatEverDBI_SessionModule>

Which Apache2::Session module to use for persistent sessions.
For example, a value could be "Apache2::Session::MySQL".  The DSN will
be the same as used for authentication.  The session created will be
stored in $r->pnotes( WhatEver ).

If you use this, you should put:

    PerlModule Apache2::Session::MySQL

(or whatever the name of your session module is) in your httpd.conf file,
so it is loaded.

If you are using this directive, you can timeout a session on the server side
by deleting the user's session.  Authentication will then fail for them.

This is not required and defaults to none, meaning no session objects will
be created.

=back

=cut

#-------------------------------------------------------------------------------
# _now_year_month_day_hour_minute_second -- Return a string with the time in
# this order separated by dashes.

sub _now_year_month_day_hour_minute_second {
    return sprintf '%04d-%02d-%02d-%02d-%02d-%02d', Today_and_Now;
}

sub _check_password {
    my ( $class, $password, $crypted_password, $crypt_type ) = @_;
    return
        if not $crypted_password
        ;    # https://rt.cpan.org/Public/Bug/Display.html?id=62470

    my %password_checker = (
        'none' => sub { return $password eq $crypted_password; },
        'crypt' => sub {
            return crypt( $password, $crypted_password ) eq $crypted_password;
        },
        'md5' => sub { return md5_hex($password) eq $crypted_password; },
        'sha256' => sub {
            return Digest::SHA::sha256_hex($password) eq $crypted_password;
        },
        'sha384' => sub {
            return Digest::SHA::sha384_hex($password) eq $crypted_password;
        },
        'sha512' => sub {
            return Digest::SHA::sha512_hex($password) eq $crypted_password;
        },
    );
    return $password_checker{$crypt_type}->();
}

#-------------------------------------------------------------------------------
# _percent_encode -- Percent-encode (like URI encoding) any non-alphanumberics
# in the supplied string.

sub _percent_encode {
    my ($str) = @_;
    my $not_a_word = qr/ ( \W ) /x;
    $str =~ s/$not_a_word/ uc sprintf '%%%02x', ord $1 /xmeg;
    return $str;
}

#-------------------------------------------------------------------------------
# _percent_decode -- Percent-decode (like URI decoding) any %XX sequences in
# the supplied string.

sub _percent_decode {
    my ($str) = @_;
    my $percent_hex_string_regex = qr/ %([0-9a-fA-F]{2}) /x;
    $str =~ s/$percent_hex_string_regex/ pack( "c",hex( $1 ) ) /xmge;
    return $str;
}

#-------------------------------------------------------------------------------
# _dbi_connect -- Get a database handle.

sub _dbi_connect {
    my ( $class, $r ) = @_;
    Carp::confess('Failed to pass Apache request object') if not $r;

    my ( $pkg, $file, $line, $sub ) = caller(1);
    my $info_message = "${class}\t_dbi_connect called in $sub at line $line";
    $class->logger( $r, Apache2::Const::LOG_INFO, $info_message, undef,
        LOG_TYPE_SYSTEM, $r->uri );

    my %c = $class->_dbi_config_vars($r);

    my $auth_name = $r->auth_name;

    # get the crypted password from the users database for this user.
    my $dbh = DBI->connect_cached( $c{'DBI_DSN'}, $c{'DBI_User'},
        $c{'DBI_Password'} );
    if ( defined $dbh ) {
        my $info_message
            = "${class}\tconnect to $c{'DBI_DSN'} for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_INFO, $info_message, undef,
            LOG_TYPE_SYSTEM, $r->uri );
        return $dbh;
    }
    else {

        my $error_message
            = "${class}\tcouldn't connect to $c{'DBI_DSN'} for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $error_message,
            LOG_TYPE_SYSTEM, undef, $r->uri );
        return;
    }
}

#-------------------------------------------------------------------------------
# _get_crypted_password -- Get the users' password from the database
sub _get_crypted_password {
    my ( $class, $r, $user ) = @_;
    my $dbh       = $class->_dbi_connect($r) || return;
    my %c         = $class->_dbi_config_vars($r);
    my $auth_name = $r->auth_name;

    if ( !$class->user_is_active( $r, $user ) ) {
        my $message
            = "${class}\tUser '$user' is not active for auth realm $auth_name.";
        $class->logger( $r, Apache2::Const::LOG_NOTICE, $message, $user,
            LOG_TYPE_AUTH, $r->uri );
        return;
    }

    my $crypted_password = EMPTY_STRING;

    my $PasswordField = $dbh->quote_identifier($c{'DBI_PasswordField'});
    my $UsersTable = $dbh->quote_identifier($c{'DBI_UsersTable'});
    my $UserField = $dbh->quote_identifier($c{'DBI_UserField'});

    my $sql_query = <<"SQL";
      SELECT $PasswordField
      FROM $UsersTable
      WHERE $UserField = ?
      AND ($PasswordField != ''
      AND $PasswordField IS NOT NULL)
SQL
    my $sth = $dbh->prepare_cached($sql_query);
    $sth->execute($user);
    ($crypted_password) = $sth->fetchrow_array();
    $sth->finish();

    if ( _is_empty($crypted_password) ) {
        my $message
            = "${class}\tCould not select password using SQL query '$sql_query'";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_AUTH, $r->uri );
        return;
    }
    return $crypted_password;
}

sub _get_new_session {
    my $class          = shift;
    my $r              = shift;
    my $user           = shift;
    my $auth_name      = shift;
    my $session_module = shift;
    my $extra_data     = shift;

    my $dbh = $class->_dbi_connect($r);
    my %session;
    tie %session, $session_module, undef,
        +{
        Handle     => $dbh,
        LockHandle => $dbh,
        };

    $session{'user'}       = $user;
    $session{'extra_data'} = $extra_data;
    return \%session;
}

# Takes a list and returns a list of the same size.
# Any element in the inputs that is defined is returned unchanged. Elements that
# were undef are returned as empty strings.
sub _defined_or_empty {
    my @args        = @_;
    my @all_defined = ();
    foreach my $arg (@args) {
        if ( defined $arg ) {
            push @all_defined, $arg;
        }
        else {
            push @all_defined, EMPTY_STRING;
        }
    }
    return @all_defined;
}

sub _is_empty {
    my $string = shift;
    return TRUE if not defined $string;
    return TRUE if $string eq EMPTY_STRING;
    return;
}

#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================

sub extra_session_info {
    my ( $class, $r, $user, $password, @extra_data ) = @_;

    return EMPTY_STRING;
}

sub authen_cred {
    my ( $class, $r, $user, $password, @extra_data ) = @_;
    my $auth_name = $r->auth_name;
    ( $user, $password ) = _defined_or_empty( $user, $password );

    if ( !length $user ) {
        my $message
            = "${class}\tno username supplied for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_NOTICE, $message, $user,
            LOG_TYPE_AUTH, $r->uri );
        return;
    }

    if ( !length $password ) {
        my $message
            = "${class}\tno password supplied for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_NOTICE, $message, $user,
            LOG_TYPE_AUTH, $r->uri );
        return;
    }

    # get the configuration information.
    my %c = $class->_dbi_config_vars($r);

    # get the crypted password from the users database for this user.
    my $crypted_password = $class->_get_crypted_password( $r, $user, \%c );

    # now return unless the passwords match.
    my $crypt_type = lc $c{'DBI_CryptType'};
    if ( !$class->_check_password( $password, $crypted_password, $crypt_type ) )
    {
        my $message
            = "${class}\tcrypt_type: '$crypt_type' - passwords didn't match for user '$user' for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_NOTICE, $message, $user,
            LOG_TYPE_AUTH, $r->uri );
        return;
    }

    # Successful login
    my $message = "${class}\tSuccessful login for $user";
    $class->logger( $r, Apache2::Const::LOG_DEBUG, $message, $user,
        LOG_TYPE_AUTH, $r->uri );

    # Create the expire time for the ticket.
    my $expire_time = _get_expire_time( $c{'DBI_SessionLifetime'} );

    # Now we need to %-encode non-alphanumberics in the username so we
    # can stick it in the cookie safely.
    my $enc_user = _percent_encode($user);

    # If we are using sessions, we create a new session for this login.
    my $session_id = EMPTY_STRING;
    if ( $c{'DBI_sessionmodule'} ne 'none' ) {
        my $session = $class->_get_new_session( $r, $user, $auth_name,
            $c{'DBI_sessionmodule'}, \@extra_data );
        $r->pnotes( $auth_name, $session );
        $session_id = $session->{_session_id};
    }

    # OK, now we stick the username and the current time and the expire
    # time and the session id (if any) together to make the public part
    # of the session key:
    my $current_time = _now_year_month_day_hour_minute_second;
    my $public_part  = "$enc_user:$current_time:$expire_time:$session_id";
    $public_part
        .= $class->extra_session_info( $r, $user, $password, @extra_data );

    # Now we calculate the hash of this and the secret key and then
    # calculate the hash of *that* and the secret key again.
    my $secretkey = $c{'DBI_SecretKey'};
    if ( !defined $secretkey ) {
        my $message
            = "${class}\tdidn't have the secret key for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }
    my $hash = md5_hex( join q{:}, $secretkey,
        md5_hex( join q{:}, $public_part, $secretkey ) );

    # Now we add this hash to the end of the public part.
    my $session_key = "$public_part:$hash";

    # Now we encrypt this and return it.
    my $encrypted_session_key
        = $class->_encrypt_session_key( $session_key, $secretkey, $auth_name,
        $c{'DBI_EncryptionType'} );
    return $encrypted_session_key;
}

#-------------------------------------------------------------------------------
# Take a session key and check that it is still valid; if so, return the user.

sub authen_ses_key {
    my ( $class, $r, $encrypted_session_key ) = @_;

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = $class->_dbi_config_vars($r);

    # Get the secret key.
    my $secret_key = $c{'DBI_SecretKey'};
    if ( !defined $secret_key ) {
        my $message
            = "${class}\tdidn't have the secret key from for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, undef,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }

    my $session_key = $class->decrypt_session_key( $r, $c{'DBI_EncryptionType'},
        $encrypted_session_key, $secret_key )
        || return;

    # Break up the session key.
    my ( $enc_user, $issue_time, $expire_time, $session_id, @rest )
        = split COLON_REGEX, $session_key;
    my $hashed_string = pop @rest;

    # Let's check that we got passed sensible values in the cookie.
    ($enc_user) = _defined_or_empty($enc_user);
    if ( $enc_user !~ PERCENT_ENCODED_STRING_REGEX ) {
        my $message
            = "${class}\tbad percent-encoded user '$enc_user' recovered from session ticket for auth_realm '$auth_name'";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, undef,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }

    # decode the user
    my $user = _percent_decode($enc_user);

    ($issue_time) = _defined_or_empty($issue_time);
    if ( $issue_time !~ DATE_TIME_STRING_REGEX ) {
        my $message
            = "${class}\tbad issue time '$issue_time' recovered from ticket for user $user for auth_realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }

    ($expire_time) = _defined_or_empty($expire_time);
    if ( $expire_time !~ DATE_TIME_STRING_REGEX ) {
        my $message
            = "${class}\tbad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }
    if ( $hashed_string !~ THIRTY_TWO_CHARACTER_HEX_STRING_REGEX ) {
        my $message
            = "${class}\tbad encrypted session_key $hashed_string recovered from ticket for user $user for auth_realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }

    # If we're using a session module, check that their session exist.
    if ( $c{'DBI_sessionmodule'} ne 'none' ) {
        my %session;
        my $dbh = $class->_dbi_connect($r) || return;

        my $tie_result = eval {
            tie %session, $c{'DBI_sessionmodule'}, $session_id,
                +{
                Handle     => $dbh,
                LockHandle => $dbh,
                };
        };
        if ( ( !$tie_result ) || $EVAL_ERROR ) {
            my $message
                = "${class}\tfailed to tie session hash to '$c{'DBI_sessionmodule'}' using session id $session_id for user $user for auth_realm $auth_name, error was '$EVAL_ERROR'";
            $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
                LOG_TYPE_SYSTEM, $r->uri );
            return;
        }

        # Update a timestamp at the top level to make sure we sync.
        $session{timestamp} = _now_year_month_day_hour_minute_second;
        $r->pnotes( $auth_name, \%session );
    }

    # Calculate the hash of the user, issue time, expire_time and
    # the secret key  and the session_id and then the hash of that
    # and the secret key again.
    my $new_hash = md5_hex(
        join q{:},
        $secret_key,
        md5_hex(
            join q{:},   $enc_user, $issue_time, $expire_time,
            $session_id, @rest,     $secret_key
        )
    );

    # Compare it to the hash they gave us.
    if ( $new_hash ne $hashed_string ) {
        my $message
            = "${class}\thash '$hashed_string' in cookie did not match calculated hash '$new_hash' of contents for user $user for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, $user,
            LOG_TYPE_TIMEOUT, $r->uri );
        return;
    }

    # Check that their session hasn't timed out.
    if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
        my $message
            = "${class}\texpire time $expire_time has passed for user $user for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_INFO, $message, $user,
            LOG_TYPE_TIMEOUT, $r->uri );
        return;
    }

    # If we're being paranoid about timing-out long-lived sessions,
    # check that the issue time + the current (server-set) session lifetime
    # hasn't passed too (in case we issued long-lived session tickets
    # in the past that we want to get rid of). *** TODO ***
    # if ( lc $c{'DBI_AlwaysUseCurrentSessionLifetime'} eq 'on' ) {

    # They must be okay, so return the user.
    return $user;
}

sub decrypt_session_key {
    my ( $class, $r, $encryptiontype, $encrypted_session_key, $secret_key )
        = @_;

    if ( $encryptiontype eq 'none' ) {
        return $encrypted_session_key;
    }

    my $auth_name = $r->auth_name;

    my $session_key;

    # Check that this looks like an encrypted hex-encoded string.
    if ( $encrypted_session_key !~ HEX_STRING_REGEX ) {
        my $message
            = "${class}\tencrypted session key '$encrypted_session_key' doesn't look like it's properly hex-encoded for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, undef,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }

    my $cipher = $class->_get_cipher_for_type( $encryptiontype, $auth_name,
        $secret_key );
    if ( !$cipher ) {
        my $message
            = "${class}\tunknown encryption type '$encryptiontype' for auth realm $auth_name";
        $class->logger( $r, Apache2::Const::LOG_ERR, $message, undef,
            LOG_TYPE_SYSTEM, $r->uri );
        return;
    }
    $session_key = $cipher->decrypt_hex($encrypted_session_key);
    return $session_key;
}

sub group {
    my ( $class, $r, $groups ) = @_;
    my @groups = split( WHITESPACE_REGEX, $groups );

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = $class->_dbi_config_vars($r);

    my $user = $r->user;

    # See if we have a row in the groups table for this user/group.
    my $dbh = $class->_dbi_connect($r) || return Apache2::Const::SERVER_ERROR;

    # Now loop through all the groups to see if we're a member of any:
    my $DBI_GroupUserField = $dbh->quote_identifier($c{'DBI_GroupUserField'});
    my $DBI_GroupsTable = $dbh->quote_identifier($c{'DBI_GroupsTable'});
    my $DBI_GroupField = $dbh->quote_identifier($c{'DBI_GroupField'});

    my $sth = $dbh->prepare_cached( <<"EOS" );
SELECT $DBI_GroupUserField
FROM $DBI_GroupsTable
WHERE $DBI_GroupField = ?
AND $DBI_GroupUserField = ?
EOS
    foreach my $group (@groups) {
        $sth->execute( $group, $user );
        if ( $sth->fetchrow_array ) {
            $sth->finish();

            # add the group to an ENV var that CGI programs can access:
            $r->subprocess_env( 'AUTH_COOKIE_DBI_GROUP' => $group );
            return Apache2::Const::OK;
        }
    }
    $sth->finish();

    my $message
        = "${class}\tuser $user was not a member of any of the required groups @groups for auth realm $auth_name";
    $class->logger( $r, Apache2::Const::LOG_INFO, $message, $user,
        LOG_TYPE_AUTH, $r->uri );
    return Apache2::Const::HTTP_FORBIDDEN;
}

sub user_is_active {
    my ( $class, $r, $user ) = @_;
    my %c                 = $class->_dbi_config_vars($r);
    my $active_field_name = $c{'DBI_UserActiveField'};

    if ( !$active_field_name ) {
        return TRUE;    # Default is that users are active
    }

    my $dbh = $class->_dbi_connect($r) || return;
    my $ActiveFieldName = $dbh->quote_identifier($active_field_name);
    my $DBI_UsersTable = $dbh->quote_identifier($c{'DBI_UsersTable'});
    my $DBI_UserField  = $dbh->quote_identifier($c{'DBI_UserField'});

    my $sql_query = <<"SQL";
      SELECT $ActiveFieldName
      FROM $DBI_UsersTable
      WHERE $DBI_UserField = ?
SQL

    my $sth = $dbh->prepare_cached($sql_query);
    $sth->execute($user);
    my ($user_active_setting) = $sth->fetchrow_array;
    $sth->finish();

    return $user_active_setting;
}

#-------------------------------------------------------------------------------

sub _get_expire_time {
    my $session_lifetime = shift;
    $session_lifetime = lc $session_lifetime;

    my $expire_time = EMPTY_STRING;

    if ( $session_lifetime eq 'forever' ) {
        $expire_time = '9999-01-01-01-01-01';

        # expire time in a zillion years if it's forever.
        return $expire_time;
    }

    my ( $deltaday, $deltahour, $deltaminute, $deltasecond )
        = split HYPHEN_REGEX, $session_lifetime;

    # Figure out the expire time.
    $expire_time = sprintf(
        '%04d-%02d-%02d-%02d-%02d-%02d',
        Add_Delta_DHMS( Today_and_Now, $deltaday, $deltahour,
            $deltaminute, $deltasecond
        )
    );
    return $expire_time;
}

sub logger {
    my ( $class, $r, $log_level, $message, $user, $log_type, @extra_args ) = @_;

    # $log_level should be an Apache constant, e.g. Apache2::Const::LOG_NOTICE

    # Sub-classes should override this method if they want to implent their
    # own logging strategy.
    #
    my @log_args = ( $message, @extra_args );

    my %apache_log_method_for_level = (
        Apache2::Const::LOG_DEBUG   => 'debug',
        Apache2::Const::LOG_INFO    => 'info',
        Apache2::Const::LOG_NOTICE  => 'notice',
        Apache2::Const::LOG_WARNING => 'warn',
        Apache2::Const::LOG_ERR     => 'error',
        Apache2::Const::LOG_CRIT    => 'crit',
        Apache2::Const::LOG_ALERT   => 'alert',
        Apache2::Const::LOG_EMERG   => 'emerg',
    );
    my $log_method = $apache_log_method_for_level{$log_level};
    if ( !$log_method ) {
        my ( $pkg, $file, $line, $sub ) = caller(1);
        $r->log_error(
            "Unknown log_level '$log_level' passed to logger() from $sub at line $line in $file "
        );
        $log_method = 'log_error';
    }
    $r->log->$log_method(@log_args);
}

1;

__END__

=head1 SUBCLASSING

You can subclass this module to override public functions and change
their behaviour.

=head1 CLASS METHODS

=head2 authen_cred($r, $user, $password, @extra_data)

Take the credentials for a user and check that they match; if so, return
a new session key for this user that can be stored in the cookie.
If there is a problem, return a bogus session key.

=head2 authen_ses_key($r, $encrypted_session_key)

Take a session key and check that it is still valid; if so, return the user.

=head2 decrypt_session_key($r, $encryptiontype, $encrypted_session_key, $secret_key)

Returns the decrypted session key or false on failure.

=head2 extra_session_info($r, $user, $password, @extra_data)

A stub method that you may want to override in a subclass.

This method returns extra fields to add to the session key.
It should return a string consisting of ":field1:field2:field3"
(where each field is preceded by a colon).

The default implementation returns an empty string.

=head2 group($r, $groups_string)

Take a string containing a whitespace-delimited list of groups and make sur
that the current remote user is a member of one of them.

Returns either I<Apache2::Const::HTTP_FORBIDDEN>
or I<Apache2::Const::OK>.

=head2 logger($r, $log_level, $message, $user, $log_type, @extra_args)

Calls one of the I<Apache::Log> methods with:

  ( $message, @extra_args )

for example, if the I<log_level> is I<Apache2::Const::LOG_DEBUG> then
this method will call:

  $r->log->debug( $message, @extra_args )

Sub-classes may wish to override this method to perform their own
logging, for example to log to a database.

I<$log_level> is one of the constants:

 Apache2::Const::LOG_DEBUG
 Apache2::Const::LOG_INFO
 Apache2::Const::LOG_NOTICE
 Apache2::Const::LOG_WARNING
 Apache2::Const::LOG_ERR
 Apache2::Const::LOG_CRIT
 Apache2::Const::LOG_ALERT
 Apache2::Const::LOG_EMERG

I<$message> is a text string.

I<$user> should be the username, could be undef in some cases.

I<$log_type> is always undef when called in this module, but
sub-classes may wish to use it when they override this method.

I<@extra_args> are appended to the call to the appropriate
I<Apache::Log> method. Usually this is simply the value of I<$r-E<gt>uri>.

=head2 user_is_active($r, $user)

If the C<DBI_UserActiveField> is not set then this method
returns true without checking the database (this is
the default behavior). 

If C<DBI_UserActiveField> is set then this method checks the
database and returns the value in that field for this user.

=head1 DATABASE SCHEMAS

For this module to work, the database tables must be laid out at least somewhat
according to the following rules:  the user field must be a UNIQUE KEY
so there is only one row per user; the password field must be NOT NULL.  If
you're using MD5 passwords the password field must be 32 characters long to
allow enough space for the output of md5_hex().  If you're using crypt()
passwords you need to allow 13 characters. If you're using sha256_hex()
then you need to allow for 64 characters, for sha384_hex() allow 96 characters,
and for sha512_hex() allow 128.

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
 Copyright (C) 2003-2004 Jacob Davies
 Copyright (C) 2004-2010 Matisse Enzer

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

=head1 CREDITS

  Original Author: Jacob Davies
  Incomplete list of additional contributors (alphabetical by first name):
    Carl Gustafsson
    Chad Columbus
    Jay Strauss
    Joe Ingersoll
    Keith Lawson
    Lance P Cleveland
    Matisse Enzer
    Nick Phillips
    William McKee
      
=head1 MAINTAINER

Matisse Enzer

        <matisse@cpan.org>
        
=head1 SEE ALSO

 Latest version: http://search.cpan.org/dist/Apache2-AuthCookieDBI

 Apache2::AuthCookie - http://search.cpan.org/dist/Apache2-AuthCookie
 Apache2::Session    - http://search.cpan.org/dist/Apache2-Session
 Apache::AuthDBI     - http://search.cpan.org/dist/Apache-DBI

=head1 TODO

=over 2

=item Improve test coverage.

=item Refactor authen_cred() and authen_ses_key() into several smaller private methods.

=item Refactor documentation.

=back

=cut
