package Apache2_4::AuthCookieMultiDBI;

$VERSION = 0.01;
$DATE = "01 June 2018";

use strict;
use warnings;

use base qw( Apache2_4::AuthCookie );

use Date::Calc qw( Today_and_Now Add_Delta_DHMS );
use DBI;
use Digest::MD5 qw( md5_hex );
use English qw(-no_match_vars);

use vars qw(@ISA);

my %CIPHERS = ();

use constant COLON_REGEX                           => qr/ : /mx;
use constant DATE_TIME_STRING_REGEX                => qr/ \A \d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2} \z /mx;
use constant EMPTY_STRING                          => q{};
use constant HEX_STRING_REGEX                      => qr/ \A [0-9a-fA-F]+ \z /mx;
use constant HYPHEN_REGEX                          => qr/ - /mx;
use constant PERCENT_ENCODED_STRING_REGEX          => qr/ \A [a-zA-Z0-9_\%]+ \z /mx;
use constant THIRTY_TWO_CHARACTER_HEX_STRING_REGEX => qr/  \A [0-9a-fA-F]{32} \z /mx;
use constant TRUE                                  => 1;

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
    DBI_URIRegx         => EMPTY_STRING,    # Default is don't use this feature
    DBI_LoadClientDB    => 0,               # 1 to set
    DBI_URIClientPos    => 1,
);

#===============================================================================
# P E R L D O C
#===============================================================================

=head1 NAME

Apache2_4::AuthCookieMultiDBI - An AuthCookie module backed by a DBI database for apache 2.4.

=head1 VERSION

    This is version 0.01


=head1 SYNOPSIS

    # In httpd.conf or .htaccess
    
    # Optional: Initiate a persistent database connection using Apache::DBI.
    # See: http://search.cpan.org/dist/Apache-DBI/
    # If you choose to use Apache::DBI then the following directive must come
    # before all other modules using DBI - just uncomment the next line:
    #PerlModule Apache::DBI  
   
     
    PerlModule Apache2_4::AuthCookieHandler
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
    perlSetVar WhatEverDBI_URIRegx "^/(.+)/(.+)$" # if have uri pattran like /client_id/file_name.pl
    perlSetVar WhatEverDBI_URIClientPos 0 # client_id position in uri
    perlSetVar WhatEverDBI_LoadClientDB 1 # do you have seperate database for each cleint

    # Protected by AuthCookieDBI.
    <Directory /www/domain.com/protected>
        AuthName WhatEver
        AuthType Apache2_4::AuthCookieMultiDBI
        PerlAuthenHandler Apache2_4::AuthCookieMultiDBI->authenticate
        require valid-user
    </Directory>

    # Login location.
    <Files LOGIN>
        AuthType Apache2_4::AuthCookieMultiDBI
        AuthName WhatEver
        SetHandler perl-script
        PerlResponseHandler Apache2_4::AuthCookieMultiDBI->login

        # If the directopry you are protecting is the DocumentRoot directory
        # then uncomment the following directive:
        #Satisfy any
    </Files>

=head1 DESCRIPTION

This module is an authentication handler that uses the basic mechanism provided
by Apache2_4::AuthCookie with a DBI database for ticket-based protection. Actually
it is modified version of L<Apache2::AuthCookieDBI> for apache 2.4. It
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

##-------------------------------------------------------------------------------
# _log_not_set -- Log that a particular authentication variable was not set.

sub _log_not_set {
    my ( $self, $r, $variable ) = @_;

    my $auth_name = $r->auth_name;
    my $message   = "${self} -> $variable not set for auth realm $auth_name";
    $r->server->log_error( $message );

    return;
}

#-------------------------------------------------------------------------------
# _dir_config_var -- Get a particular authentication variable.
#
sub _dir_config_var {
    my ( $self, $r, $variable ) = @_;

    my $auth_name = $r->auth_name;
    my $client    = EMPTY_STRING;

 #    if ($variable eq 'DBI_SecretKey') {
    #   $client = $self->get_client_name($r);
    # }

    #return $client . $r->dir_config("$auth_name$variable");
    return $r->dir_config("$auth_name$variable");
}

#-------------------------------------------------------------------------------
# _dbi_config_vars -- Get all authentication variable.
#
sub _dbi_config_vars {
    my ( $self, $r ) = @_;

    my %c;    # config variables hash
    foreach my $variable ( keys %CONFIG_DEFAULT ) {
        my $value_from_config = $self->_dir_config_var( $r, $variable );
        $c{$variable}
            = defined $value_from_config
            ? $value_from_config
            : $CONFIG_DEFAULT{$variable};
        if ( !defined $c{$variable} ) {
            $self->_log_not_set( $r, $variable );
        }
    }

    # If we used encryption we need to pull in Crypt::CBC.
    if ( $c{'DBI_EncryptionType'} ne 'none' ) {
        require Crypt::CBC;
    }

    # Compile module for password encryption, if needed.
    if ( $c{'DBI_CryptType'} =~ '^sha') {
        require Digest::SHA;
    }

    return %c;
}

#-------------------------------------------------------------------------------
# _get_cipher_for_type - Get the cipher from the cache, or create a new one if the
# cached cipher hasn't been created.
# 
sub _get_cipher_for_type {
    my ( $self, $dbi_encryption_type, $auth_name, $secret_key ) = @_;
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

#-------------------------------------------------------------------------------
# _defined_or_empty - Takes a list and returns a list of the same size.
# Any element in the inputs that is defined is returned unchanged. Elements that
# were undef are returned as empty strings.
# 
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

#-------------------------------------------------------------------------------
# _is_empty - check empty string
# 
sub _is_empty {
    my $string = shift;
    return TRUE if not defined $string;
    return TRUE if $string eq EMPTY_STRING;
    return;
}

#-------------------------------------------------------------------------------
# _percent_encode -- Percent-encode (like URI encoding) any non-alphanumberics
# in the supplied string.
# 
sub _percent_encode {
    my ($str) = @_;
    my $not_a_word = qr/ ( \W ) /x;
    $str =~ s/$not_a_word/ uc sprintf '%%%02x', ord $1 /xmeg;
    return $str;
}

#-------------------------------------------------------------------------------
# _percent_decode -- Percent-decode (like URI decoding) any %XX sequences in
# the supplied string.
# 
sub _percent_decode {
    my ($str) = @_;
    my $percent_hex_string_regex = qr/ %([0-9a-fA-F]{2}) /x;
    $str =~ s/$percent_hex_string_regex/ pack( "c",hex( $1 ) ) /xmge;
    return $str;
}

#-------------------------------------------------------------------------------
# _dbi_connect -- Get a database handle.
# 
sub _dbi_connect {
    my ($self, $r) = @_;

    Carp::confess('Failed to pass Apache request object') if not $r;

    my ( $pkg, $file, $line, $sub ) = caller(1);
    my $info_message = "${self} -> _dbi_connect called in $sub at line $line";
    $r->server->log_error( $info_message );

    my %c = $self->_dbi_config_vars($r);

    my $auth_name = $r->auth_name;

    # get the crypted password from the users database for this user.
    my $dbh = DBI->connect_cached( $c{'DBI_DSN'}, $c{'DBI_User'}, $c{'DBI_Password'} );
    if ( !defined $dbh ) {
        my $error_message = "${self} => couldn't connect to $c{'DBI_DSN'} for auth realm $auth_name";
        $r->server->log_error( $error_message );
        return;
    }
    
    if($c{'DBI_LoadClientDB'}) {

        my $client = $self->get_client_name($r);
        $dbh = $self->_dbi_connect_to_client($r, $client);

    }

    if ( defined $dbh ) {
        my $info_message = "${self} => connect to $c{'DBI_DSN'} for auth realm $auth_name";
        $r->server->log_error( $info_message );
        return $dbh;
    }
    
}

#-------------------------------------------------------------------------------
# _dbi_connect_to_client -- Get a database handle for client database.
# 
sub _dbi_connect_to_client {
    my ($self, $r, $client) = @_;

    my $auth_name = $r->auth_name;

    my %c = $self->get_client_database_info($r, $client);

    $r->server->log_error("dbhost = $c{'dbhost'}; dbname = $c{'dbname'}; dblogin = $c{'dblogin'}; dbpass = $c{'dbpass'}:");

    my $dbi_dns = "DBI:mysql:database=$c{'dbname'}:host=$c{'dbhost'}";
    my $dbh = DBI->connect_cached( $dbi_dns, $c{'dblogin'}, $c{'dbpass'});

    if ( !defined $dbh ) {
        my $error_message = "${self} => couldn't connect to $c{'DBI_DSN'} for auth realm $auth_name";
        $r->server->log_error( $error_message );
        return;
    }

    return $dbh;
}


#-------------------------------------------------------------------------------
# _get_crypted_password -- Get the users' password from the database
# 
sub _get_crypted_password ($$\@) {
    my $self = shift;
    my $r = shift;
    my $user = shift;

    my $dbh       = $self->_dbi_connect($r) || return;
    my %c         = $self->_dbi_config_vars($r);
    my $auth_name = $r->auth_name;

    if ( !$self->user_is_active( $r, $user ) ) {
        my $message
            = "${self}\tUser '$user' is not active for auth realm $auth_name.";
        $r->server->log_error( $message );
        return;
    }

    my $crypted_password = EMPTY_STRING;

    my $sql_query = <<"SQL";
      SELECT `$c{'DBI_PasswordField'}`
      FROM `$c{'DBI_UsersTable'}`
      WHERE `$c{'DBI_UserField'}` = ?
      AND (`$c{'DBI_PasswordField'}` != ''
      AND `$c{'DBI_PasswordField'}` IS NOT NULL)
SQL
    my $sth = $dbh->prepare_cached($sql_query);
    $sth->execute($user);
    ($crypted_password) = $sth->fetchrow_array();
    $sth->finish();

    if ( _is_empty($crypted_password) ) {
        my $message
            = "${self}\tCould not select password using SQL query '$sql_query'";
        $r->server->log_error( $message );
        return;
    }
    return $crypted_password;
}

#-------------------------------------------------------------------------------
# _now_year_month_day_hour_minute_second -- Return a string with the time in
# this order separated by dashes.
# 
sub _now_year_month_day_hour_minute_second {
    return sprintf '%04d-%02d-%02d-%02d-%02d-%02d', Today_and_Now;
}

#-------------------------------------------------------------------------------
# _check_password -- password checking
# 
sub _check_password {
    my ( $self, $password, $crypted_password, $crypt_type ) = @_;
    return
        if not $crypted_password
        ;    # https://rt.cpan.org/Public/Bug/Display.html?id=62470

    my %password_checker = (
        'none' => sub { return $password eq $crypted_password; },
        'crypt' => sub {
            $self->_crypt_digest( $password, $crypted_password ) eq
                $crypted_password;
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
# _get_expire_time -- calculating expire time
# 
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

#-------------------------------------------------------------------------------
# _get_new_session -- calculating new session
# 
sub _get_new_session {
    my $self          = shift;
    my $r              = shift;
    my $user           = shift;
    my $auth_name      = shift;
    my $session_module = shift;
    my $extra_data     = shift;

    my $dbh = $self->_dbi_connect($r);
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

#-------------------------------------------------------------------------------
# _encrypt_session_key -- calculating encrypt session key
# 
sub _encrypt_session_key {
    my $self               = shift;
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

    my $cipher = $self->_get_cipher_for_type( $dbi_encryption_type, $auth_name,
        $secret_key );
    my $encrypted_key = $cipher->encrypt_hex($session_key);
    return $encrypted_key;
}


#===============================================================================
# P U B L I C   F U N C T I O N S
#===============================================================================
#
##-------------------------------------------------------------------------------
# get_client_database_info -- Get a clients database details.
# 
sub get_client_database_info {
    my ($self, $r, $client) = @_;

    my %c;

    $c{'dbhost'}  = '';
    $c{'dbname'}  = '';
    $c{'dblogin'} = '';
    $c{'dbpass'}  = '';

    return %c;
}

#-------------------------------------------------------------------------------
# user_is_active -- check user active or not
# 
sub user_is_active {
    my $self = shift;
    my $r = shift;
    my $user = shift;

    my %c                 = $self->_dbi_config_vars($r);
    my $active_field_name = $c{'DBI_UserActiveField'};

    if ( !$active_field_name ) {
        return TRUE;    # Default is that users are active
    }

    my $dbh = $self->_dbi_connect($r) || return;
    my $sql_query = <<"SQL";
      SELECT `$active_field_name`
      FROM `$c{'DBI_UsersTable'}`
      WHERE `$c{'DBI_UserField'}` = ?
SQL

    my $sth = $dbh->prepare_cached($sql_query);
    $sth->execute($user);
    my ($user_active_setting) = $sth->fetchrow_array;
    $sth->finish();

    return $user_active_setting;
}

#-------------------------------------------------------------------------------
# decrypt_session_key -- decrypt session key
# 
sub decrypt_session_key {
    my ( $self, $r, $encryptiontype, $encrypted_session_key, $secret_key )
        = @_;

    if ( $encryptiontype eq 'none' ) {
        return $encrypted_session_key;
    }

    my $auth_name = $r->auth_name;

    my $session_key;

    # Check that this looks like an encrypted hex-encoded string.
    if ( $encrypted_session_key !~ HEX_STRING_REGEX ) {
        my $message = "${self}\tencrypted session key '$encrypted_session_key' doesn't look like it's properly hex-encoded for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    my $cipher = $self->_get_cipher_for_type( $encryptiontype, $auth_name,
        $secret_key );
    if ( !$cipher ) {
        my $message = "${self}\tunknown encryption type '$encryptiontype' for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }
    $session_key = $cipher->decrypt_hex($encrypted_session_key);
    return $session_key;
}


#===============================================================================
# O V E R R I D   F U N C T I O N S
#===============================================================================

#-------------------------------------------------------------------------------
# authen_ses_key -- Overrid authen_ses_key method from Apache2_4::AuthCookie
# 
sub authen_ses_key ($$$) {
    my ( $self, $r, $encrypted_session_key ) = @_;

    my $auth_name = $r->auth_name;

    # Get the configuration information.
    my %c = $self->_dbi_config_vars($r);

    # Get the secret key.
    my $secret_key = $c{'DBI_SecretKey'};
    if ( !defined $secret_key ) {
        my $message = "${self} -> didn't have the secret key from for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    my $session_key = $self->decrypt_session_key( $r, $c{'DBI_EncryptionType'}, $encrypted_session_key, $secret_key ) || return;

    # Break up the session key.
    my ( $enc_user, $issue_time, $expire_time, $session_id, @rest ) = split COLON_REGEX, $session_key;
    my $hashed_string = pop @rest;

    # Let's check that we got passed sensible values in the cookie.
    ($enc_user) = _defined_or_empty($enc_user);
    if ( $enc_user !~ PERCENT_ENCODED_STRING_REGEX ) {
        my $message = "${self} -> bad percent-encoded user '$enc_user' recovered from session ticket for auth_realm '$auth_name'";
        $r->server->log_error( $message );
        return;
    }

    # decode the user
    my $user = _percent_decode($enc_user);

    ($issue_time) = _defined_or_empty($issue_time);
    if ( $issue_time !~ DATE_TIME_STRING_REGEX ) {
        my $message = "${self} -> bad issue time '$issue_time' recovered from ticket for user $user for auth_realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    ($expire_time) = _defined_or_empty($expire_time);
    if ( $expire_time !~ DATE_TIME_STRING_REGEX ) {
        my $message = "${self} -> bad expire time $expire_time recovered from ticket for user $user for auth_realm $auth_name";
        $r->server->log_error( $message );
        return;
    }
    if ( $hashed_string !~ THIRTY_TWO_CHARACTER_HEX_STRING_REGEX ) {
        my $message = "${self} -> bad encrypted session_key $hashed_string recovered from ticket for user $user for auth_realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    # If we're using a session module, check that their session exist.
    if ( $c{'DBI_sessionmodule'} ne 'none' ) {
        my %session;
        my $dbh = $self->_dbi_connect($r) || return;

        my $tie_result = eval {
            tie %session, $c{'DBI_sessionmodule'}, $session_id,
                +{
                Handle     => $dbh,
                LockHandle => $dbh,
                };
        };
        if ( ( !$tie_result ) || $EVAL_ERROR ) {
            my $message
                = "${self} -> failed to tie session hash to '$c{'DBI_sessionmodule'}' using session id $session_id for user $user for auth_realm $auth_name, error was '$EVAL_ERROR'";
            $r->server->log_error( $message );
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
        my $message = "${self} -> hash '$hashed_string' in cookie did not match calculated hash '$new_hash' of contents for user $user for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    # Check that their session hasn't timed out.
    if ( _now_year_month_day_hour_minute_second gt $expire_time ) {
        my $message = "${self} -> expire time $expire_time has passed for user $user for auth realm $auth_name";
        $r->server->log_error( $message );
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

#-------------------------------------------------------------------------------
# authen_cred -- Overrid authen_cred method from Apache2_4::AuthCookie
# 
sub authen_cred ($$\@) {
    my $self = shift;
    my $r = shift;
    my $user = shift;
    my $password = shift;
    my @extra_data = @_;

    my $auth_name = $r->auth_name;
    ( $user, $password ) = _defined_or_empty( $user, $password );
    
    if ( !length $user ) {
    $r->server->log_error( "${self} no username supplied for auth realm $auth_name" );
    return;
    }
    if ( !length $password ) {
    $r->server->log_error( "${self} no password supplied for auth realm #auth_name" );
    return;
    }

    # get the configuration information.
    my %c = $self->_dbi_config_vars($r);

    # get the crypted password from the users database for this user.
    my $crypted_password = $self->_get_crypted_password( $r, $user, \%c );

    # now return unless the passwords match.
    my $crypt_type = lc $c{'DBI_CryptType'};
    if ( !$self->_check_password( $password, $crypted_password, $crypt_type ) )
    {
        my $message = "${self} crypt_type: '$crypt_type' - passwords didn't match for user '$user' for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }

    # Successful login
    my $message = "${self} Successful login for $user";
    $r->server->log_error( $message );

    # Create the expire time for the ticket.
    my $expire_time = _get_expire_time( $c{'DBI_SessionLifetime'} );

    # Now we need to %-encode non-alphanumberics in the username so we
    # can stick it in the cookie safely.
    my $enc_user = _percent_encode($user);

    # If we are using sessions, we create a new session for this login.
    my $session_id = EMPTY_STRING;
    if ( $c{'DBI_sessionmodule'} ne 'none' ) {
        my $session = $self->_get_new_session( $r, $user, $auth_name,
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
        .= $self->extra_session_info( $r, $user, $password, @extra_data );

    # Now we calculate the hash of this and the secret key and then
    # calculate the hash of *that* and the secret key again.
    my $secretkey = $c{'DBI_SecretKey'};
    if ( !defined $secretkey ) {
        my $message = "${self} -> didn't have the secret key for auth realm $auth_name";
        $r->server->log_error( $message );
        return;
    }
    my $hash = md5_hex( join q{:}, $secretkey,
                 md5_hex( join q{:}, $public_part, $secretkey ) 
               );

    # Now we add this hash to the end of the public part.
    my $session_key = "$public_part:$hash";

    # Now we encrypt this and return it.
    my $encrypted_session_key = $self->_encrypt_session_key( $session_key, $secretkey, $auth_name, $c{'DBI_EncryptionType'} );
    return $encrypted_session_key;
}

#-------------------------------------------------------------------------------
# get_client_name -- get cleint name for uri using config var
# 
sub get_client_name {
    my $self = shift;
    my $r = shift || Apache->request;

    my %c = $self->_dbi_config_vars($r);
    my $uri_regx = $c{'DBI_URIRegx'}; 

    my $uri = $r->uri;

    my @metching = ($uri =~ /$uri_regx/);
    return $metching[$c{'DBI_URIClientPos'}];
}

sub get_cookie_path {
    my $self = shift;
    my $r = shift || Apache->request;

    my $auth_name = $r->auth_name;

    my $client = $self->get_client_name($r);

    return $r->dir_config("${auth_name}Path") . "$client/";

}

sub extra_session_info {
    my ( $self, $r, $user, $password, @extra_data ) = @_;

    return EMPTY_STRING;
}

=head1 EXPORTS

None.

=head1 REVISIONS

Please see the enclosed file CHANGES.

=head1 PROBLEMS?

If this doesn't work, let me know and I'll fix the code. Or by all means send a patch.
Please don't just post a bad review on CPAN.

=head1 SEE ALSO

L<Apache2::AuthCookieDBI>: L<Apache2_4::AuthCookie>.

=head1 AUTHOR

berlin3, details -at- cpan -dot- org.

=head1 COPYRIGHT

Copyright (C) details, 2018, ff. - All Rights Reserved.

This library is free software and may be used only under the same terms as Perl itself.

=cut

1;

__END__