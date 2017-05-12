# -*-perl-*-
# Creation date: 2003-09-30 07:55:27
# Authors: Don
# Change log:
# $Id: Generic.pm,v 1.11 2003/10/19 07:03:52 don Exp $

# Copyright (c) 2003 Don Owens

# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

 Apache::Authen::Generic - A generic authentication handler for
   the Apache webserver (under mod_perl)

=head1 SYNOPSIS

    # httpd.conf
    PerlModule Apache::Authen::Generic
    <Location /cgi-bin/secure>
            AuthType Basic
            AuthName "Test Login"
            PerlAuthenHandler Apache::Authen::Generic->authenticate
            require valid-user
            PerlSetVar generic_auth_cipher_key abcdefghijklmnopqrstuvwxyz012345
            PerlSetVar generic_auth_failed_url "/cgi-bin/login/login_form.cgi"
            PerlSetVar generic_auth_allow_url "^/cgi-bin/login"
            PerlSetVar generic_auth_cookie_name test_cookie
            PerlSetVar generic_auth_ref_url_var ref_url
            PerlSetVar generic_auth_set_cookie_env 1
    </Location>

    # cgi script
    use Apache::Authen::Generic;
    my $auth_obj = Apache::Authen::Generic->new;
    if (&check_login($user, $pwd)) {
        my $cookie = $auth_obj->($data, $key);
        print "Set-Cookie: $cookie\n";
        print "Location: $redirect_url\n";
        print "\n";
    } else {
        &handle_invalid_password()
    }

 # Efforts have been made to make this module work under Apache
 # 1.3.* and mod_perl 1.0, but it has only been tested under
 # Apache 2.0.* and mod_perl 2.0.

=head1 DESCRIPTION

=head2 Variables to set in the Apache configuration file

 The following are variables to be set in the Apache
 configuration file with the PerlSetVar directive.

=head3 generic_auth_cipher_key

 This is the encryption key used for encrypting the cookies used
 to verify authentication.  It must be 32 bytes (256-bit).  The
 encryption used is AES-256 and uses an SHA1 digest to verify
 data integrity.

=head3 generic_auth_failed_url

 This is the url users are be redirected to if they have not been
 authenticated (typically a login page).  This url can be
 relative.

=head3 generic_auth_allow_url

 This is a regular expression that will be run against the URI
 the user is trying to access.  If a match occurs, the user will
 be allowed through, as if the user had been authenticated.  This
 is useful for allowing the user to access the login page and to
 allow access to other public pages.

=head3 generic_auth_cookie_name

 This is the name of the cookie that will be used to verify
 authentication.  This must match the name passed to the
 generateAuthCookie() method when using a CGI script for the
 login process.

=head3 generic_auth_ref_url_var

 This is the name of the field the handler will use to pass the
 current URI to the authentication failed page.  This is useful
 for redirecting the user to the page the user was originally
 trying to access when prompted with the login page.

=head3 generic_auth_set_cookie_env

 If this is set to a true value, and the first argument passed to
 the generateAuthCookie() method is a hash, those values will be
 available to your CGI scripts as environment variables whose
 names are the keys of the hash prefixed with the cookie name (as
 set by generic_auth_cookie_name) and an underscore.

=head1 METHODS

=cut

use strict;
use Crypt::CBC;
use Crypt::Rijndael;
use MIME::Base64 ();
use Storable ();
use Digest::SHA1 ();

{   package Apache::Authen::Generic;

    use vars qw($VERSION);
    
    BEGIN {
        $VERSION = '0.01'; # update below in POD as well
    }

    use mod_perl;
    use constant MP2 => $mod_perl::VERSION >= 1.99;

    # for compatibility with both mod_perl 1 and 2
    BEGIN {
        if (defined($ENV{MOD_PERL}) and $ENV{MOD_PERL} ne '') {
            if (MP2) {
                require Apache2;
                require Apache::compat;
                require Apache::Const;
                Apache::Const->import(-compile => qw(:common HTTP_UNAUTHORIZED));
            } else {
                require Apache::Constants;
                Apache::Constants->import(qw(:common :response HTTP_UNAUTHORIZED));
            }
        }
    }

    sub new {
        my ($proto) = @_;
        my $self = bless {}, ref($proto) || $proto;
        return $self;
    }

=pod

=head2 generateAuthCookie($data, $key, $cookie_params, $cookie_name)

 This method is used to generate the authentication cookie from a
 CGI script.  The return value is the value to set for the header
 Set-Cookie without the end of line sequence, e.g.,

     my $cookie = $auth_obj->($data, $key);
     print "Set-Cookie: $cookie\n";
     print "Location: $redirect_url\n";
     print "\n";

 The value for $key must be the same value assigned to
 generic_auth_cipher_key in the webserver configuration.

 if $data is a reference to a hash and the
 generic_auth_set_cookie_env variable is set to a true value in
 the Apache configuration, the values from the hash will be
 available to your CGI scripts as environment variables whose
 names are the keys of the hash prefixed with the cookie name (as
 set by generic_auth_cookie_name) and an underscore.

=cut
    # This method is normally to be run from a CGI script
    sub generateAuthCookie {
        my ($self, $data, $key, $cookie_params, $cookie_name) = @_;
        $cookie_params = {} unless ref($cookie_params) eq 'HASH';
        $cookie_name = $self->getAuthCookieName if $cookie_name eq '';

        my $array = [ 1, $data ];

        # this value is encoded -- should be safe for cookies
        my $val = $self->encrypt($array, undef, $key);

        my $path = $$cookie_params{path};
        $path = '/' unless defined $path;
        my $params = [ "path=$path" ];
        if (defined($$cookie_params{domain})) {
            push @$params, "domain=$$cookie_params{domain}";
        }
        my $param_str = join('; ', @$params);
        my $str = qq{$cookie_name=$val; $param_str};
        return $str;
    }


=pod

=head2 authenticate($request_obj)

 The main interface to this module.  This is the method to be
 called as the authentication handler.  If you wish to subclass
 this module, the following information may be useful.

 The steps in authenticate() are as follows:

   1) Instantiates an Apache::Authen::Generic object by calling
      the new() method.
   2) Check if the user is already authenticated
      Calls $self->checkAlreadyAuthenticated($request_obj)
      Returns OK if return value is true
   3) Check if the current URI is always allowed through
      Calls $self->checkGloballyAllowedUrls($req)
      Returns OK if return value is true
   4) Redirect to login page if the above steps fail
      Calls $self->redirectToAuthFailedPage($req)
      Sets a Location header and returns OK

=cut
    sub authenticate($$) {
        my ($proto, $req) = @_;
        my $self = $proto->new;
        
        if ($self->checkAlreadyAuthenticated($req)) {
            return MP2 ? Apache::OK() : Apache::Constants::OK();
        }

        if ($self->checkGloballyAllowedUrls($req)) {
            return MP2 ? Apache::OK() : Apache::Constants::OK();
        }

        # redirect to login page
        return $self->redirectToAuthFailedPage($req);
    }

    sub checkAlreadyAuthenticated {
        my ($self, $req) = @_;
        
        my $cookies = $self->getCookies($req);

        my $cookie_name = $self->getAuthCookieName($req);
        my $cipher_val = $$cookies{$cookie_name};
        return undef if $cipher_val eq '';

        my $data = $self->decrypt($cipher_val, $req);
        unless (ref($data) eq 'ARRAY' and scalar(@$data) > 0) {
            local(*OUT);
            open(OUT, ">>/tmp/test_auth_log.txt");
            print OUT "\$data not an array\n";
            close OUT;
            return undef;
        }

        unless ($$data[0] == 1) {
            open(OUT, ">>/tmp/test_auth_log.txt");
            print OUT "\$\$data[0] not 1\n";
            close OUT;

            return undef;
        }
        
        # check here if wanna set environment variables
        # based on what is in the 2nd element of the array $data
        if ($req->dir_config('generic_auth_set_cookie_env')) {
            my $hash = $$data[1];
            if (defined($hash) and ref($hash) eq 'HASH') {
                while (my ($key, $value) = each %$hash) {
                    $req->subprocess_env("${cookie_name}_$key" => $value);
                }
            }
        }

        return 1;
    }

    sub getAuthCookieName {
        my ($self, $req) = @_;
        if ($req) {
            my $cookie_name = $req->dir_config('generic_auth_cookie_name');
            return $cookie_name unless $cookie_name eq '';
        }
        
        return 'generic_auth';
    }
        

    sub checkGloballyAllowedUrls {
        my ($self, $req) = @_;

        my $uri = $req->uri;
        my $regex = $self->getAuthAllowUrl($req);
        return undef if $uri eq '';

        return 1 if $uri =~ /$regex/;

        return undef;
    }

    sub getAuthAllowUrl {
        my ($self, $req) = @_;
        my $regex = $req->dir_config('generic_auth_allow_url');
        return $regex;
    }

    sub redirectToAuthFailedPage {
        my ($self, $req) = @_;

        my $url = $self->getAuthFailedPage($req);
        if ($url eq '') {
            # FIXME: need to write out a notification page
            $req->header_out('Content-Type' => 'text/html');
            # FIXME: make this work
            my $html;
            $html .= qq{No login page specified for this handler.\n};
            $req->print($html);

            return MP2 ? Apache::HTTP_UNAUTHORIZED() : Apache::Constants::HTTP_UNAUTHORIZED();
        }

        my $ref_url_var = $req->dir_config('generic_auth_ref_url_var');
        $ref_url_var = 'ref_url' if $ref_url_var eq '';
        my $cur_query = $req->args;
        my $uri = $req->uri;
        my $ref_url = $uri;
        $ref_url .= "?$cur_query" unless $cur_query eq '';
        $url = $self->_addParamsToUrl($url, { $ref_url_var => $ref_url });
        if ($url =~ m{^/}) {
            my $host_url = $self->_getSelfHostUrl($req);
            $url = "$host_url$url";
        }
        $req->header_out(Location => $url);

        # REDIRECT does not work properly in Apache 1 with Perl 5.6.0
        return MP2 ? Apache::OK() : Apache::Constants::OK();
    }

    sub getAuthFailedPage {
        my ($self, $req) = @_;

        my $url = $req->dir_config('generic_auth_failed_url');
        return $url;
    }

    sub _getSelfHostUrl {
        my ($self, $req) = @_;
        my $host = $req->hostname;
        my $scheme = $req->subprocess_env('HTTPS') eq 'on' ? 'https' : 'http';
        return "$scheme://$host";
    }

    sub getCipherKey {
        my ($self, $req) = @_;
        my $key;
        $key = $req->dir_config('generic_auth_cipher_key') if $req;
        $key = 'abcdefghijklmnopqrstuvwxyz012345' if $key eq '';

        return $key;
    }

    sub getCipherObj {
        my ($self, $req, $key) = @_;
        my $obj = $$self{_cipher_obj};
        return $obj if $obj;
        
        my $cipher = $self->getCipher($req);
        $key = $self->getCipherKey($req) if $key eq '';
        $obj = Crypt::CBC->new({ cipher => $cipher, key => $key });
        $$self{_cipher_obj} = $obj;
        return $obj;
    }

    sub getDigestObject {
        my ($self, $req, $key) = @_;
        my $obj = $$self{_digest_obj};
        return $obj if $obj;
        # $key = $self->getCipherKey($req) if $key eq '';

        # $obj = Digest::HMAC->new($key, 'Digest::HMAC_SHA1');
        $obj = Digest::SHA1->new;
        $$self{_digest_obj} = $obj;
        return $obj;
    }

    sub getCipher {
        my ($self, $req) = @_;
        return 'Crypt::Rijndael';
    }

    sub getCookies {
        my ($self, $req) = @_;
        my $headers = $req->headers_in;
        return $self->parseCookieData($$headers{Cookie});
    }

    sub parseCookieData {
        my ($self, $cookie_data) = @_;
        
        my $results = {};
        my(@pairs) = split("; ", $cookie_data);
        foreach my $key_value (@pairs) {
            my ($key, $value) = split("=", $key_value);
            $$results{$key} = $value;
        }
        return $results unless wantarray;
        return %$results;
    }

    # FIXME: add timestamp and HMAC
    sub encrypt {
        my ($self, $data, $req, $key) = @_;
        $key = $self->getCipherKey($req) if $key eq '';

        my $cipher_obj = $self->getCipherObj($req, $key);
        my $digest_obj = $self->getDigestObject($req, $key);

        my $serialized = $self->serialize($data);
        $digest_obj->add($serialized);
        my $digest = $digest_obj->b64digest;
        $$self{_digest_obj} = undef;

        my $str = time() . '|' . $digest . '|' . $serialized;
        my $crypted = $self->_encode($cipher_obj->encrypt($str));

        return $crypted;
    }

    sub decrypt {
        my ($self, $crypted, $req, $key) = @_;
        $key = $self->getCipherKey($req) if $key eq '';
        
        my $cipher_obj = $self->getCipherObj($req, $key);
        my $str = $cipher_obj->decrypt($self->_decode($crypted));
        my ($timestamp, $sent_digest, $serialized) = split /\|/, $str;
        
        if ($timestamp eq '' or $sent_digest eq '') {
            return undef;
        }
        my $digest_obj = $self->getDigestObject($req, $key);
        $digest_obj->add($serialized);
        my $digest = $digest_obj->b64digest;
        $$self{_digest_obj} = undef;

        return undef unless $sent_digest eq $digest;

        my $decrypted = $self->deserialize($serialized);
        return $decrypted;
    }

    sub serialize {
        my ($self, $data) = @_;
        return Storable::freeze($data);
    }

    sub deserialize {
        my ($self, $str) = @_;
        return Storable::thaw($str);
    }

    sub _decode {
        my ($self, $str) = @_;
        $str = MIME::Base64::decode_base64($self->_urlDecode($str));
        return $str;
    }

    sub _encode {
        my ($self, $str) = @_;
        $str = $self->_urlEncode(MIME::Base64::encode_base64($str, ''));
        return $str;
    }

    # taken from CGI::Utils
    sub _urlEncode {
        my ($self, $str) = @_;
        $str =~ s{([^A-Za-z0-9_])}{sprintf("%%%02x", ord($1))}eg;
        return $str;
    }

    # taken from CGI::Utils
    sub _urlDecode {
        my ($self, $str) = @_;
        $str =~ tr/+/ /;
        $str =~ s|%([A-Fa-f0-9]{2})|chr(hex($1))|eg;
        return $str;
    }

    # taken from CGI::Utils
    sub _urlEncodeVars {
        my ($self, $var_hash, $sep) = @_;
        $sep = ';' unless defined $sep;
        my @pairs;
        foreach my $key (keys %$var_hash) {
            my $val = $$var_hash{$key};
            my $ref = ref($val);
            if ($ref eq 'ARRAY' or $ref =~ /=ARRAY/) {
                push @pairs, map { $self->_urlEncode($key) . "=" . $self->_urlEncode($_) } @$val;
            } else {
                push @pairs, $self->_urlEncode($key) . "=" . $self->_urlEncode($val);
            }
        }

        return join($sep, @pairs);
    }

    # taken from CGI::Utils
    sub _addParamsToUrl {
        my ($self, $url, $param_hash) = @_;
        my $sep = ';';
        if ($url =~ /^([^?]+)\?(.*)$/) {
            my $query = $2;
            # if query uses & for separator, then keep it consistent
            if ($query =~ /\&/) {
                $sep = '&';
            }
            $url .= $sep unless $url =~ /\?$/;
        } else {
            $url .= '?';
        }

        $url .= $self->_urlEncodeVars($param_hash, $sep);
        return $url;
    }

    sub _formatDateTime {
        my ($self, $time) = @_;

        $time = time() unless $time;

        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($time);
        $mon += 1;
        $year += 1900;
        my $date = sprintf "%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday,
            $hour, $min, $sec;

        return $date;
    }

    sub _log {
        my ($self, @rest) = @_;
        local(*LOG);
        open(LOG, ">>/tmp/generic_auth_log");
        my $date = $self->_formatDateTime;
        print LOG "$date - ", @rest, "\n";
        close LOG;
    }

}

1;

__END__

=pod

=head1 EXAMPLES

=head1 AUTHOR

 Don Owens <don@owensnet.com>

=head1 COPYRIGHT

 Copyright (c) 2003 Don Owens

 All rights reserved. This program is free software; you can
 redistribute it and/or modify it under the same terms as Perl
 itself.

=head1 VERSION

 0.01

=cut
