package Apache2::AuthCookieLDAP;

# Apache2::AuthCookieLDAP
#
# An Apache2::AuthCookie backend for LDAP based authentication
#
# Author: Kirill Solomko <ksolomko@cpan.org>

use strict;
use warnings;
use 5.010_000;
our $VERSION = '1.15';

use Apache2::AuthCookie;
use base qw(Apache2::AuthCookie);

use Apache2::Connection;
use Apache2::RequestRec;
use Apache2::Log;
use Apache2::Const -compile => qw(:log);
use APR::Const -compile     => qw(:error ENOTIME SUCCESS);

use English qw(-no_match_vars);

use Digest::MD5 qw(md5_hex);
use Crypt::CBC;
use Crypt::DES;

use Net::LDAP;

use constant CIPHER_TYPES => qw(DES IDEA Blowfish Blowfish_PP);
use constant LOG_LEVELS   => {
    emerg  => Apache2::Const::LOG_EMERG,
    alert  => Apache2::Const::LOG_ALERT,
    crit   => Apache2::Const::LOG_CRIT,
    err    => Apache2::Const::LOG_ERR,
    warn   => Apache2::Const::LOG_WARNING,
    notice => Apache2::Const::LOG_NOTICE,
    info   => Apache2::Const::LOG_INFO,
    debug  => Apache2::Const::LOG_DEBUG
};

use constant NULL               => q{};
use constant C_SECRET_KEY       => '_SecretKey';
use constant C_SESSION_LIFETIME => '_SessionLifetime';
use constant C_LDAPURI          => '_LDAPURI';
use constant C_BASE             => '_Base';
use constant C_BINDDN           => '_BindDN';
use constant C_BINDPW           => '_BindPW';
use constant C_FILTER           => '_Filter';
use constant C_CIPHER           => '_Cipher';
use constant C_DEBUG            => '_Debug';
use constant C_DEBUG_LOGLEVEL   => '_DebugLogLevel';
use constant C_ERROR_LOGLEVEL   => '_ErrorLogLevel';

my %CONFIG_DEFAULT = (
    C_SECRET_KEY,     undef,          C_SESSION_LIFETIME, '00-24-00-00',
    C_LDAPURI,        undef,          C_BASE,             undef,
    C_BINDDN,         undef,          C_BINDPW,           undef,
    C_FILTER,         '(uid=%USER%)', C_CIPHER,           'des',
    C_DEBUG_LOGLEVEL, 'alert',        C_ERROR_LOGLEVEL,   'err',
    C_DEBUG,          0,
);

my $ldap_handler;
my %config_data;
my %ciphers;
my $DEBUG = C_DEBUG;

#----------------------------------------------------------------------
sub cipher {
    my ( $self, $r ) = @_;

    my $auth_name  = $r->auth_name;
    my $cipher     = $self->config( $r, C_CIPHER );
    my $cipher_key = $auth_name . ':' . lc($cipher);

    unless ( exists $ciphers{$cipher_key} ) {
        my $secret_key = $self->config( $r, C_SECRET_KEY );
        foreach my $cipher_type (CIPHER_TYPES) {
            next unless lc($cipher_type) eq $cipher;
            $ciphers{$cipher_key} = Crypt::CBC->new(
                -key    => $secret_key,
                -cipher => $cipher_type
            );
        }
    }
    exists $ciphers{$cipher_key}
      ? return $ciphers{$cipher_key}
      : $self->fatal( $r, "Wrong cipher $cipher" );
    return NULL;
}

sub config {
    my ( $self, $r, $req_key ) = @_;

    return unless defined $req_key;

    if ( keys %config_data ) {
        exists $config_data{$req_key}
          ? return $config_data{$req_key}
          : return NULL;
    }

    my $auth_name = $r->auth_name;
    foreach my $key ( keys %CONFIG_DEFAULT ) {
        my $default = $CONFIG_DEFAULT{$key};
        my $var     = $r->dir_config( $auth_name . $key );
        $config_data{$key} = defined $var ? $var : $default;
        if ( $key eq C_DEBUG ) {
            $DEBUG = $config_data{$key};
        }
    }

    foreach my $key ( ( C_DEBUG_LOGLEVEL, C_ERROR_LOGLEVEL ) ) {
        my $value = $config_data{$key};
        my $replace = $key eq C_DEBUG_LOGLEVEL ? 'alert' : 'err';
        unless ( exists LOG_LEVELS->{$value} ) {
            $self->fatal( $r,
                "Loglevel '$value' does not exist, using '$replace' instead" );
        }
    }

    my %use_files;
    foreach my $c_key ( C_BASE, C_BINDDN, C_BINDPW ) {
        my $c_var = $config_data{$c_key};
        if ( $c_var && $c_var =~ /^file:(.+):(.+)$/ ) {
            -f $1
              ? push @{ $use_files{$1} }, [ $c_key, $2 ]
              : $self->fatal( $r, "$c_key: check your file access: $1" );
        }
    }

    foreach my $file ( keys %use_files ) {
        open( my $lp_fh, $file )
          || $self->fatal( $r, "Cannot open $file: $!" );
        my $search_data = $use_files{$file};
        if ( $#$search_data != 1 ) {    # to be safe
            $self->fatal( $r, "Wrong regex pattern for file $file" );
        }

        while ( my $row = <$lp_fh> ) {
            my $matched = -1;
            for ( my $i = 0 ; $i <= $#$search_data ; $i++ ) {
                my $data = $search_data->[$i];
                my ( $var, $pattern ) = @$data;
                if ( $row =~ /$pattern/ ) {
                    $config_data{$var} = $1;
                    $matched = $i;
                }
            }
            splice @$search_data, $matched, 1 if $matched >= 0;
            last if $#$search_data < 0;
        }
        close $lp_fh;

        if ( $#$search_data >= 0 ) {
            $self->fatal( $r,
                "Wrong variable pattern specified for file " . $file );
        }
    }

    exists $config_data{$req_key}
      ? return $config_data{$req_key}
      : return NULL;
}

sub ldap {
    my ( $self, $r ) = @_;

    return $ldap_handler if $ldap_handler;
    return NULL if defined $ldap_handler;

    my $uri    = $self->config( $r, C_LDAPURI );
    my $binddn = $self->config( $r, C_BINDDN );
    my $bindpw = $self->config( $r, C_BINDPW ) || '';

    my $ldap_handler = Net::LDAP->new($uri)
      or $self->fatal( $r, "Cannot connect to the LDAP server: $!" );
    unless ($ldap_handler) {
        $ldap_handler = NULL;
        return $ldap_handler;
    }
    if ($binddn) {    # bind with a dn/pass
        my $msg = $ldap_handler->bind( $binddn, password => $bindpw );
        $msg->code && $self->fatal( $r, $msg->error );
    }
    else {            # anonymous bind
        my $msg = $ldap_handler->bind();
        $msg->code && $self->fatal( $r, $msg->error );
    }

    return $ldap_handler;
}

sub ldap_search {
    my ( $self, $r, $user ) = @_;

    return NULL unless $self->ldap($r);

    my $base = $self->config( $r, C_BASE );
    $base =~ s/%USER%/$user/;
    my $filter = $self->config( $r, C_FILTER );
    $filter =~ s/%USER%/$user/;
    my $mesg = $self->ldap($r)->search(
        base   => $base,
        scope  => 'base',
        filter => $filter
    );

    return $mesg->code ? 0 : $mesg->count;
}

sub ldap_check_user {
    my ( $self, $r, $user, $password ) = @_;

    return NULL unless $self->ldap($r);

    my $base = $self->config( $r, C_BASE );
    $base =~ s/%USER%/$user/;
    my $mesg = $self->ldap($r)->bind( $base, password => $password );

    return $mesg->is_error ? 0 : 1;
}

sub rlog {
    my ( $self, $r, $msg ) = @_;

    $r->log_rerror( Apache2::Log::LOG_MARK(),
        LOG_LEVELS->{ $self->config( $r, C_DEBUG_LOGLEVEL ) },
        APR::Const::SUCCESS, ${self} . ": " . $msg );
}

sub fatal {
    my ( $self, $r, $msg ) = @_;

    $r->log_rerror( Apache2::Log::LOG_MARK(),
        LOG_LEVELS->{ $self->config( $r, C_ERROR_LOGLEVEL ) },
        APR::Const::SUCCESS, ${self} . ": " . $msg );
}

sub encode_string {
    my ( $self, $r, $str ) = @_;

    return unpack( 'H*', $str );
}

sub decode_string {
    my ( $self, $r, $str ) = @_;

    return pack( 'H*', $str );
}

sub create_hash {
    my ( $self, $r, $str ) = @_;

    my $ip = $r->connection->remote_ip;
    $str .= $self->encode_string( $r, $ip );

    my @str_data = split '', $str;
    my @key_data = split '', $self->config( $r, C_SECRET_KEY );
    my @hash_data;

    my $idx = 0;
    foreach my $s (@str_data) {
        push @hash_data, $s;
        if ( $idx <= $#key_data ) {
            push @hash_data, $key_data[$idx];
        }
        ++$idx;
    }
    if ( $idx <= $#key_data ) {
        for ( my $i = $idx ; $i <= $#key_data ; $i++ ) {
            push @hash_data, $key_data[$i];
        }
    }

    return md5_hex( join '', @hash_data );
}

sub encrypt_session {
    my ( $self, $r, $str ) = @_;

    my $hash = $self->create_hash( $r, $str );
    my $cipher = $self->cipher($r);

    return $cipher
      ? $self->cipher($r)->encrypt_hex( $str . ':' . $hash )
      : NULL;
}

sub decrypt_session {
    my ( $self, $r, $str ) = @_;

    if ( $str !~ /^[a-zA-Z0-9]+/ ) {
        $self->rlog( $r, "Incorrectly encoded session key: $str" );
        return;
    }

    my $cipher = $self->cipher($r);

    return $cipher
      ? $self->cipher($r)->decrypt_hex($str)
      : NULL;
}

sub check_expire_time {
    my ( $self, $r, $session_time ) = @_;

    my $lifetime = $self->config( $r, C_SESSION_LIFETIME );
    return 0 if $lifetime =~ /^\s*forever\s*$/i;

    unless ( $lifetime =~ /^\s*\d{1,4}-\d{1,2}-\d{1,2}-\d{1,2}\s*$/ ) {
        $self->fatal( $r, "Incorrect session lifetime format '$lifetime'" );
        return 1;
    }

    my ( $d, $h, $m, $s ) = split '-', $lifetime;
    my $expire_time = $session_time + $d * 86400 + $h * 3600 + $m * 60 + $s;

    return $expire_time < time ? 1 : 0;
}

sub authen_cred {
    my ( $self, $r, $user, $password, @extra_data ) = @_;

    my $auth_name = $r->auth_name;
    my $remote_ip = $r->connection->remote_ip;

    unless ($user) {
        $DEBUG && $self->rlog( $r, "No username specified" );
        return;
    }

    unless ($password) {
        $DEBUG
          && $self->rlog( $r, "No password specified for user '$user'" );
        return;
    }

    unless ( $self->ldap_search( $r, $user ) ) {
        $DEBUG
          && $self->rlog( $r, "User '$user' is not found" );
        return;
    }

    unless ( $self->ldap_check_user( $r, $user, $password ) ) {
        $DEBUG
          && $self->rlog( $r, "Incorrect password for '$user'" );
        return;
    }
    else {
        $DEBUG
          && $self->rlog( $r, "Successful login for '$user' ($remote_ip)" );
    }

    my $session_data = $self->encode_string( $r, $user ) . ':' . time;

    return $self->encrypt_session( $r, $session_data );
}

sub authen_ses_key {
    my ( $self, $r, $session_key ) = @_;

    my $auth_name  = $r->auth_name;
    my $remote_ip  = $r->connection->remote_ip;
    my $secret_key = $self->config( $r, C_SECRET_KEY );

    unless ($secret_key) {
        $DEBUG
          && $self->rlog( $r, "Authorization attempt without a session key" );
        return;
    }

    my $dec_session_key = $self->decrypt_session( $r, $session_key );

    unless ($secret_key) {
        $DEBUG
          && $self->rlog( $r, "Cannot decrypt session key: $session_key" );
        return;
    }

    my ( $enc_user, $session_time, $hash ) = split ':', $dec_session_key;

    unless ( $enc_user && $session_time && $hash ) {
        $DEBUG
          && $self->rlog( $r, "Invalid session key specified: $session_key" );
        return;
    }

    my $user = $self->decode_string( $r, $enc_user );

    if ( $self->check_expire_time( $r, $session_time ) ) {
        $DEBUG
          && $self->rlog( $r, "Expiration time has passed for user '$user'" );
        return;
    }

    my $session_data = $enc_user . ':' . $session_time;
    unless ( $hash eq $self->create_hash( $r, $session_data ) ) {
        $DEBUG
          && $self->rlog( $r, "Session hash does not match for user '$user'" );
        return;
    }

    return $user;
}

1;

=pod

=head1 NAME

Apache2::AuthCookieLDAP - An Apache2::AuthCookie backend for LDAP based authentication

=head1 VERSION

Version 1.15

=head1 COMPATIBILITY

The version is compatible with Apache2 and mod_perl2

=head1 SYNOPSIS

1. Make sure that your LDAP server is configured and you have access to it 

2.  In httpd.conf or .htaccess

Apache2::AuthCookie config (check L<Apache2::AuthCookie> documentation for the additional info)

    PerlSetVar MyAuthPath /
    PerlSetVar MyAuthLoginScript /
    PerlSetVar MyAuthLogoutURL http://127.0.0.1
    PerlSetVar MyAuthSecure 1

To make "LogoutURL" working you can subsclass Apache2::ApacheCookieLDAP and provide it with:

    sub logout {
        my ( $self, $r ) = @_;
        $self->SUPER::logout($r);
        my $logout_url = $r->dir_config( $r->auth_name . 'LogoutURL' );
        if ($logout_url) {
            $r->headers_out->set( Location => $logout_url );
            $r->status(Apache2::Const::REDIRECT);
        }

        return Apache2::Const::REDIRECT;
    }
  
Apache2::AuthCookieLDAP config

    PerlSetVar MyAuth_SecretKey OGheSWkT1ixd4V0DydSarLVevF77sSibMIoUaIYuQUqp2zvZIwbS4lyWhRTFUcHE
    PerlSetVar MyAuth_SessionLifetime 00-24-00-00
    PerlSetVar MyAuth_LDAPURI ldap://127.0.0.1
    PerlSetVar MyAuth_Base uid=%USER%,ou=staff,dc=company,dc=com
    PerlSetVar MyAuth_BindDN cn=ldap,dc=company,dc=com
    PerlSetVar MyAuth_BindPW somepassword
    PerlSetVar MyAuth_Filter (uid=%USER%)

    <Directory /var/www/mysite/protected>
        AuthType Apache2::AuthCookieLDAP
        AuthName MyAuth
        PerlAuthenHandler Apache2::AuthCookieLDAP->authenticate
        PerlAuthzHandler Apache2::AuthCookieLDAP->authorize
        require valid-user
    </Directory>

    <Location /login>
        SetHandler perl-script
        AuthType Apache2::AuthCookieLDAP
        AuthName MyAuth
        PerlResponseHandler MyAuthCookieLDAP->login
    </Location>

    <Location /logout>
        SetHandler perl-script
        AuthType Apache2::AuthCookieLDAP
        AuthName MyAuth
        PerlResponseHandler Apache2::AuthCookieLDAP->logout
    </Location>

=head1 DESCRIPTION

This module acts as an authentication handler under Apache2 environment. 
It uses Apache2::AuthCookie as the base class and serves as a backend to 
provide user authentication against an LDAP server.

Make sure that you have got a reachable LDAP server and credentials to access it 
(ldapuri, base, binddn/bindpw or anonymous bind).

When there is an attempt to access a "protected" directory or location
that has 'require valid-user' option included Apache2::AuthCookieLDAP is used 
as the authentication and the authorization handler. It takes a pair of
provided username/password and tries to search the username in the LDAP directory 
(it also uses the filter MyAuth_Filter, for puropses where you want to restrict access
to the resource to only a specific group). If the user is found then it tries 
to bind with the provided username/password.  Once authorized a session key 
is generated by taking into account the provided username, authorization time 
and a hash generated by including a specific logic plus the user's IP address. 
Upon completion the session data is encrypted with the secret key (MyAuth_SecretKey) 
and the according cookie is generated by Apache2::AuthCookie.  
All the following requests to the protected resource take the cookie (if exists)
and the encrypted session key is validated (decrypted, the user is checked, 
the session time is checked for expiration and the hash is regenerated 
and compared with the provided one).
Upon success the user is authorized to access the protected resource.

Should you require any additional information how the cookies logic works 
please check L<Apache2::AuthCookie> documentation.

=head1 APACHE CONFIGURATION DIRECTIVES

All the configuration directives as used in the following format:

    PerlSetVar "AuthName""DirectiveName"

So if your have:
    
    <Directory /var/www/mysite/protected>
        AuthType Apache2::AuthCookieLDAP
        AuthName WhateverAuthName
    ...

Then the directive name for you will be (for instance):

    PerlSetVar WhatEverAuthName_SecretKey

=over 4

=item C<MyAuth_SecretKey> 

Use your own secret key !!!DONT USE THE ONE FROM THE EXAMPLE!!!

=item C<MyAuth_SessionLifetime> [optional, default: 00-24-00-00]

Format is: days-hours-minutes-seconds or 'forever' for endless sessions

=item C<MyAuth_LDAPURI>

Your LDAP server URI

Format: ldap://127.0.0.1 or ldap://myldaphost

Use ldaps:// for secure connections (if your LDAP server supports it)

=item C<MyAuth_Base> 

LDAP Base. Please note that '%USER%' macro is substituted in the request
with a username that is being authenticated.

Example: uid=%USER%,ou=staff,dc=company,dc=com

=item C<MyAuth_BindDN> [optional]

Use the option if your LDAP does not accept anonymous bind 
for search.

Example: cn=ldap,dc=company,dc=com

=item C<MyAuth_BindPW> [optional]

If you  BindDN then you most likely want to specify
a password here to bind with.

=item C<MyAuth_Cipher> [optinal, default: 'des']

An encryption method used for the session key.

Supported methods: 'des', 'idea', 'blowfish', 'blowfish_pp'

=item C<MyAuth_Filter> [optinal, default: '(uid=%USER%)']

You can additionally check if a user belongs to a specific group or has 
specific LDAP attributes. Where '%USER%' macro is substituted in the request
with a username that is being authenticated.

For instance: (&(uid=%USER%)(objectClass=posixAccount))

perldoc Net::LDAP::Filter for additional info

=item C<MyAuth_DebugLogLevel> [optional, default: 'alert']

A log level that will be used to send debug messages into your 
Apache log file.

Supported levels: 'emerg', 'alert', 'crit', 'err', 'warn', 'notice', 'info', 'debug'

=item C<MyAuth_ErrorLogLevel> [optional, default: 'err']

A log level that will be used to send error messages into your 
Apache log file.

Supported levels: 'emerg', 'alert', 'crit', 'err', 'warn', 'notice', 'info', 'debug'

NOTE: In case of misconfiguration or your LDAP access unaviability the errors 
will not cause Apache to fall with the 500 error but you will not be 
able to login instead. 
Please check your log file to trace and fix such issues/misconfiguration.

=item C<MyAuth_Debug> [optional, default: '0']

Set the option to '1' if you expect to see debug messages from the module in your 
Apache log file.

=back

NOTE: It is also possible to fetch Base/BindDN/BindPW from a file(s)

Use the following syntax for that:

Example: 

PerlSetVar MyAuth_Base file:/etc/ldap_base.conf:^\s*base\s+(.+)\r*\n$

PerlSetVar MyAuth_BindDN file:/etc/pam_ldap.conf:^\s*binddn\s+(.+)\r*\n$

PerlSetVar MyAuth_BindPW file:/etc/pam_ldap.conf:^\s*bindpw\s+(.+)\r*\n$

Format: "file:<filename>:<regular expression>" 
    Where $1 will be the variable.

=over 4

=back

=head1 CLASS METHODS

=head2 cipher($r)

Returns a cipher for the encyption method specified in
the corresponding apache config directive.

=head2 config($r, $req_key)

Returns a value for the specified $req_key.

=head2 ldap($r)

Returns Net::LDAP handler or NULL if there were errors.

=head2 ldap_search($r, $user)

Performs Net::LDAP->search(base => $base, scope => 'base', filter => $filter)
and returns '1' if the specified $user is found or otherwise '0'.

=head2 ldap_check_user($r, $user, $password)

Performs Net::LDAP->bind($base, password => $password).

(%USER% is replaced by $user in $base)

=head2 rlog($r, $msg)

Logs $msg using $r->log_rerror and the current debug log level.

=head2 fatal($r, $msg)

Logs $msg using $r->log_rerror and the current error log level.

=head2 encode_string($r, $msg)

Encodes the specified string into a hex string.

=head2 decode_string($r, $msg)

Decodes the specified hex string and returns a string.

=head2 create_hash($r, $str)

Generates and returns a hash from the provided string.

=head2 encrypt_session($r, $str)

Encrypts $str and returns the provided session string.

=head2 decrypt_session($r, $str)

Decrypts $str and returns the provided encrypted session string.

=head2 check_expire_time($r, $session_time)

Checks the provided session time (unixtime) with the current time
and returns '0' if the session time is still valid or '1' if passed.

=head2 authen_cred($r, $user, $password, @extra_data) 

This is the overridden method of Apache::AuthCookie and is used to
authenticate $user with the provided $password

Returns the encrypted session key in case of successfull authentication.

Please follow to Apache2::AuthCookie if you need more information about the method.

=head2 authen_ses_key($r, $session_key)

This is the overridden method of Apache::AuthCookie and is used to
validate the provided $session_key. 

Returns the authenticated username in case of success or redirects to the login page otherwise.

Please follow to Apache2::AuthCookie if you need more information about the method.

=head1 SUBCLASSING

You can subclass the module and override any of the available methods.

=head1 CREDITS

"SecretKey", "Lifetime" Apache config directive names and their definition style 
are similar to Apache2::AuthCookieDBI to keep it common for those 
who use both of the modules.

Authors of Apache2::AuthCookieDBI 

Authors of Apache2::AuthCookie

=head1 COPYRIGHT

Copyright (C) 2013 Kirill Solomko

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 BUGS

Please report any bugs or feature requests through the web interface at:
 http://rt.cpan.org/Public/Dist/Display.html?Name=Apache2-AuthCookieLDAP

=head1 TODO

=over 4

=item Add package tests.

=back

=head1 SEE ALSO

L<perl(1)>, L<Apache2::AuthCookie>, L<Apache2::AuthCookieDBI>

=cut

__END__

# vim: sw=4 ts=4 et

