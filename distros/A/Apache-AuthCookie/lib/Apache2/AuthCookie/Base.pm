package Apache2::AuthCookie::Base;
$Apache2::AuthCookie::Base::VERSION = '3.32';
# ABSTRACT: Common Methods Shared by Apache2 and Apache2_4 AuthCookie Subclasses.

use strict;
use mod_perl2 1.99022;
use Carp;

use Apache::AuthCookie::Util qw(is_blank is_local_destination);
use Apache2::AuthCookie::Params;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Log;
use Apache2::Access;
use Apache2::Response;
use Apache2::URI;
use Apache2::Util;
use APR::Table;
use Apache2::Const qw(OK DECLINED SERVER_ERROR M_GET HTTP_FORBIDDEN HTTP_MOVED_TEMPORARILY HTTP_OK);
use Encode ();


sub authenticate {
    my ($auth_type, $r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    $r->server->log_error("authenticate() entry") if ($debug >= 3);
    $r->server->log_error("auth_type " . $auth_type) if ($debug >= 3);

    if (my $prev = ($r->prev || $r->main)) {
        # we are in a subrequest or internal redirect.  Just copy user from the
        # previous or main request if its is present
        if (defined $prev->user) {
            $r->server->log_error('authenticate() is in a subrequest or internal redirect.') if $debug >= 3;
            # encoding would have been handled in prev req, so do not encode here.
            $r->user( $prev->user );
            return OK;
        }
    }

    if ($debug >= 3) {
        $r->server->log_error("r=$r authtype=". $r->auth_type);
    }

    if ($r->auth_type ne $auth_type) {
        # This location requires authentication because we are being called,
        # but we don't handle this AuthType.
        $r->server->log_error("AuthType mismatch: $auth_type =/= ".$r->auth_type) if $debug >= 3;
        return DECLINED;
    }

    # Ok, the AuthType is $auth_type which we handle, what's the authentication
    # realm's name?
    my $auth_name = $r->auth_name;
    $r->server->log_error("auth_name $auth_name") if $debug >= 2;
    unless ($auth_name) {
        $r->server->log_error("AuthName not set, AuthType=$auth_type", $r->uri);
        return SERVER_ERROR;
    }

    # Get the Cookie header. If there is a session key for this realm, strip
    # off everything but the value of the cookie.
    my $ses_key_cookie = $auth_type->key($r) || '';

    $r->server->log_error("ses_key_cookie " . $ses_key_cookie) if $debug >= 1;
    $r->server->log_error("uri " . $r->uri) if $debug >= 2;

    if ($ses_key_cookie) {
        my ($auth_user, @args) = $auth_type->authen_ses_key($r, $ses_key_cookie);

        if (!is_blank($auth_user) and scalar @args == 0) {
            # We have a valid session key, so we return with an OK value.
            # Tell the rest of Apache what the authentication method and
            # user is.

            $r->ap_auth_type($auth_type);
            $r->user( $auth_type->_encode($r, $auth_user) );
            $r->server->log_error("user authenticated as $auth_user")
                if $debug >= 1;

            # send new cookie if SessionTimeout is on
            if (my $expires = $r->dir_config("${auth_name}SessionTimeout")) {
                $auth_type->send_cookie($r, $ses_key_cookie,
                                        {expires => $expires});
            }

            return OK;
        }
        elsif (scalar @args > 0 and $auth_type->can('custom_errors')) {
            return $auth_type->custom_errors($r, $auth_user, @args);
        }
        else {
            # There was a session key set, but it's invalid for some reason. So,
            # remove it from the client now so when the credential data is posted
            # we act just like it's a new session starting.
            $auth_type->remove_cookie($r);
            $r->subprocess_env('AuthCookieReason', 'bad_cookie');
        }
    }
    else {
        $r->subprocess_env('AuthCookieReason', 'no_cookie');
    }

    # This request is not authenticated, but tried to get a protected
    # document.  Send client the authen form.
    return $auth_type->login_form($r);
}


sub cookie_name {
    my ($self, $r) = @_;

    my $auth_type = $r->auth_type;
    my $auth_name = $r->auth_name;

    my $cookie_name = $r->dir_config("${auth_name}CookieName") ||
                      "${auth_type}_${auth_name}";

    return $cookie_name;
}


sub cookie_string {
    my $self = shift;
    my %p = @_;
    for (qw/request key/) {
        croak "missing required parameter $_" unless defined $p{$_};
    }
    # its okay if value is undef here.

    my $r = $p{request};

    $p{value} = '' unless defined $p{value};

    my $string = sprintf '%s=%s', @p{'key','value'};

    my $auth_name = $r->auth_name;

    if (my $expires = $p{expires} || $r->dir_config("${auth_name}Expires")) {
        $expires = Apache::AuthCookie::Util::expires($expires);
        $string .= "; expires=$expires";
    }

    $string .= '; path=' . ( $self->get_cookie_path($r) || '/' );

    if (my $domain = $r->dir_config("${auth_name}Domain")) {
        $string .= "; domain=$domain";
    }

    if ($r->dir_config("${auth_name}Secure")) {
        $string .= '; secure';
    }

    # HttpOnly is an MS extension.  See
    # http://msdn.microsoft.com/workshop/author/dhtml/httponly_cookies.asp
    if ($r->dir_config("${auth_name}HttpOnly")) {
        $string .= '; HttpOnly';
    }

    # SameSite is an anti-CSRF cookie property.  See
    # https://www.owasp.org/index.php/SameSite
    if (my $samesite = $r->dir_config("${auth_name}SameSite")) {
        if ($samesite =~ /\A(strict|lax)\z/i) {
            $samesite = lc($1);
            $string .= "; SameSite=$samesite";
        }
    }

    return $string;
}


sub decoded_requires {
    my ($self, $r) = @_;

    my $reqs     = $r->requires or return;
    my $encoding = $self->requires_encoding($r);

    unless (is_blank($encoding)) {
        for my $req (@$reqs) {
            $$req{requirement} = Encode::decode($encoding, $$req{requirement});
        }
    }

    return $reqs;
}


sub decoded_user {
    my ($self, $r) = @_;

    my $user = $r->user;

    if (is_blank($user)) {
        return $user;
    }

    my $encoding = $self->encoding($r);

    if (!is_blank($encoding)) {
        $user = Encode::decode($encoding, $user);
    }

    return $user;
}


sub encoding {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    return $r->dir_config("${auth_name}Encoding");
}


sub escape_uri {
    my ($r, $string) = @_;
    return Apache2::Util::escape_path($string, $r->pool);
}


sub get_cookie_path {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    return $r->dir_config("${auth_name}Path");
}


sub handle_cache {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    return unless $auth_name;

    unless ($r->dir_config("${auth_name}Cache")) {
        $r->no_cache(1);
        $r->err_headers_out->set(Pragma => 'no-cache');
    }
}


sub key {
    my ($self, $r) = @_;

    my $cookie_name = $self->cookie_name($r);

    my $allcook = ($r->headers_in->get("Cookie") || "");

    return ($allcook =~ /(?:^|\s)$cookie_name=([^;]*)/)[0];
}


sub login {
    my ($self, $r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    my $auth_type = $r->auth_type;
    my $auth_name = $r->auth_name;

    my $params = $self->params($r);

    if ($r->method eq 'POST') {
        $self->_convert_to_get($r);
    }

    my $default_destination = $r->dir_config("${auth_name}DefaultDestination");
    my $destination         = $params->param('destination');

    if (is_blank($destination)) {
        if (!is_blank($default_destination)) {
            $destination = $default_destination;
            $r->server->log_error("destination set to $destination");
        }
        else {
            $r->server->log_error("No key 'destination' found in form data");
            $r->subprocess_env('AuthCookieReason', 'no_cookie');
            return $auth_type->login_form($r);
        }
    }

    if ($r->dir_config("${auth_name}EnforceLocalDestination")) {
        my $current_url = $r->construct_url;
        unless (is_local_destination($destination, $current_url)) {
            $r->server->log_error("non-local destination $destination detected for uri ",$r->uri);

            if (is_local_destination($default_destination, $current_url)) {
                $destination = $default_destination;
                $r->server->log_error("destination changed to $destination");
            }
            else {
                $r->server->log_error("Returning login form: non local destination: $destination");
                $r->subprocess_env('AuthCookieReason', 'no_cookie');
                return $auth_type->login_form($r);
            }
        }
    }

    # Get the credentials from the data posted by the client
    my @credentials;
    for (my $i = 0; defined $params->param("credential_$i"); $i++) {
        my $key = "credential_$i";
        my $val = $params->param($key);
        $r->server->log_error("$key $val") if $debug >= 2;
        push @credentials, $val;
    }

    # save creds in pnotes so login form script can use them if it wants to
    $r->pnotes("${auth_name}Creds", \@credentials);

    # Exchange the credentials for a session key.
    my $ses_key = $self->authen_cred($r, @credentials);
    unless ($ses_key) {
        $r->server->log_error("Bad credentials") if $debug >= 2;
        $r->subprocess_env('AuthCookieReason', 'bad_credentials');
        $r->uri($self->untaint_destination($destination));
        return $auth_type->login_form($r);
    }

    if ($debug >= 2) {
        defined $ses_key ? $r->server->log_error("ses_key $ses_key")
                         : $r->server->log_error("ses_key undefined");
    }

    $self->send_cookie($r, $ses_key);

    $self->handle_cache($r);

    if ($debug >= 2) {
        $r->server->log_error("redirect to $destination");
    }

    $r->headers_out->set(
        "Location" => $self->untaint_destination($destination));

    return HTTP_MOVED_TEMPORARILY;
}


sub login_form {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    if ($r->method eq 'POST') {
        $self->_convert_to_get($r);
    }

    # There should be a PerlSetVar directive that gives us the URI of
    # the script to execute for the login form.

    my $authen_script;
    unless ($authen_script = $r->dir_config($auth_name . "LoginScript")) {
        $r->server->log_error("PerlSetVar '${auth_name}LoginScript' not set", $r->uri);
        return SERVER_ERROR;
    }

    my $status = $self->login_form_status($r);
    $status = HTTP_FORBIDDEN unless defined $status;

    $r->custom_response($status, $authen_script);

    return $status;
}


sub login_form_status {
    my ($self, $r) = @_;

    my $ua = $r->headers_in->get('User-Agent')
        or return HTTP_FORBIDDEN;

    if (Apache::AuthCookie::Util::understands_forbidden_response($ua)) {
        return HTTP_FORBIDDEN;
    }
    else {
        return HTTP_OK;
    }
}


sub logout {
    my ($self,$r) = @_;

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    $self->remove_cookie($r);

    $self->handle_cache($r);
}


sub params {
    my ($self, $r) = @_;

    return Apache2::AuthCookie::Params->new($r);
}


sub recognize_user {
    my ($self, $r) = @_;

    # only check if user is not already set
    return DECLINED unless is_blank($r->user);

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    my $auth_type = $r->auth_type;
    my $auth_name = $r->auth_name;

    return DECLINED if is_blank($auth_type) or is_blank($auth_name);

    return DECLINED if is_blank($r->headers_in->get('Cookie'));

    my $cookie = $self->key($r);
    my $cookie_name = $self->cookie_name($r);

    $r->server->log_error("cookie $cookie_name is $cookie")
        if $debug >= 2;

    return DECLINED if is_blank($cookie);

    my ($user,@args) = $auth_type->authen_ses_key($r, $cookie);

    if (!is_blank($user) and scalar @args == 0) {
        $r->server->log_error("user is $user") if $debug >= 2;

        # send cookie with update expires timestamp if session timeout is on
        if (my $expires = $r->dir_config("${auth_name}SessionTimeout")) {
            $self->send_cookie($r, $cookie, {expires => $expires});
        }

        $r->user( $self->_encode($r, $user) );
    }
    elsif (scalar @args > 0 and $auth_type->can('custom_errors')) {
        return $auth_type->custom_errors($r, $user, @args);
    }

    return is_blank($user) ? DECLINED : OK;
}


sub remove_cookie {
    my ($self, $r) = @_;

    my $cookie_name = $self->cookie_name($r);

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    my $str = $self->cookie_string(
        request => $r,
        key     => $cookie_name,
        value   => '',
        expires => 'Mon, 21-May-1971 00:00:00 GMT'
    );

    $r->err_headers_out->add("Set-Cookie" => "$str");
    $r->server->log_error("removed cookie $cookie_name") if $debug >= 2;
}


sub requires_encoding {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    return $r->dir_config("${auth_name}RequiresEncoding");
}


sub send_cookie {
    my ($self, $r, $ses_key, $cookie_args) = @_;

    $cookie_args = {} unless defined $cookie_args;

    my $cookie_name = $self->cookie_name($r);

    my $cookie = $self->cookie_string(
        request => $r,
        key     => $cookie_name,
        value   => $ses_key,
        %$cookie_args
    );

    $self->send_p3p($r);

    $r->err_headers_out->add("Set-Cookie" => $cookie);
}


sub send_p3p {
    my ($self, $r) = @_;

    my $auth_name = $r->auth_name;

    if (my $p3p = $r->dir_config("${auth_name}P3P")) {
        $r->err_headers_out->set(P3P => $p3p);
    }
}


sub untaint_destination {
    my ($self, $dest) = @_;

    return Apache::AuthCookie::Util::escape_destination($dest);
}

# convert current request to GET
sub _convert_to_get {
    my ($self, $r) = @_;

    return unless $r->method eq 'POST';

    my $debug = $r->dir_config("AuthCookieDebug") || 0;

    $r->server->log_error("Converting POST -> GET") if $debug >= 2;

    my $args = $self->params($r);

    my @pairs = ();

    for my $name ($args->param) {
        # we dont want to copy login data, only extra data
        next if $name eq 'destination'
             or $name =~ /^credential_\d+$/;

        for my $v ($args->param($name)) {
            push @pairs, escape_uri($r, $name) . '=' . escape_uri($r, $v);
        }
    }

    $r->args(join '&', @pairs) if scalar(@pairs) > 0;

    $r->method('GET');
    $r->method_number(M_GET);
    $r->headers_in->unset('Content-Length');
}

sub _encode {
    my ($self, $r, $value) = @_;

    my $encoding = $self->encoding($r);

    if (is_blank($encoding)) {
        return $value;
    }
    else {
        return Encode::encode($encoding, $value);
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Apache2::AuthCookie::Base - Common Methods Shared by Apache2 and Apache2_4 AuthCookie Subclasses.

=head1 VERSION

version 3.32

=head1 DESCRIPTION

This module contains common code shared by AuthCookie for Apache 2.x and Apache 2.4.

=head1 METHODS

=head2 authenticate($r): int

This method is one you'll use in a server config file (httpd.conf, .htaccess,
...) as a PerlAuthenHandler.  If the user provided a session key in a cookie,
the C<authen_ses_key()> method will get called to check whether the key is
valid.  If not, or if there is no key provided, we redirect to the login form.

=head2 cookie_name($r): string

Return the name of the auth cookie for this request.  This is either
C<${auth_name}CookieName>, or AuthCookie's self generated name.

=head2 cookie_string(%args): string

Generate a cookie string. C<%args> are:

=over 4

=item *

request

The Apache request object

=item *

key

The Cookie name

=item *

value

the Cookie value

=item *

expires (optional)

When the cookie expires. See L<Apache::AuthCookie::Util/expires()>.  Uses C<${auth_name}Expires> if not giv

=back

All other cookie settings come from C<PerlSetVar> settings.

=head2 decoded_requires($r): arrayref

This method returns the C<< $r->requires >> array, with the C<requirement>
values decoded if C<${auth_name}RequiresEncoding> is in effect for this
request.

=head2 decoded_user($r): string

If you have set ${auth_name}Encoding, then this will return the decoded value of
C<< $r-E<gt>user >>.

=head2 encoding($r): string

Return the ${auth_name}Encoding setting that is in effect for this request.

=head2 escape_uri($r, $value): string

Escape the given string so it is suitable to be used in a URL.

=head2 get_cookie_path($r): string

Returns the value of C<PerlSetVar ${auth_name}Path>.

=head2 handle_cache($r): void

If C<${auth_name}Cache> is defined, this sets up the response so that the
client will not cache the result.  This sents C<no_cache> in the apache request
object and sends the appropriate headers so that the client will not cache the
response.

=head2 key($r): string

This method will return the current session key, if any.  This can be handy
inside a method that implements a C<require> directive check (like the
C<species> method discussed above) if you put any extra information like
clearances or whatever into the session key.

=head2 login($r): int

This method handles the submission of the login form.  It will call the
C<authen_cred()> method, passing it C<$r> and all the submitted data with names
like C<credential_#>, where # is a number.  These will be passed in a simple
array, so the prototype is C<$self-E<gt>authen_cred($r, @credentials)>.  After
calling C<authen_cred()>, we set the user's cookie and redirect to the URL
contained in the C<destination> submitted form field.

=head2 login_form($r): int

This method is responsible for displaying the login form. The default
implementation will make an internal redirect and display the URL you specified
with the C<PerlSetVar WhatEverLoginScript> configuration directive. You can
overwrite this method to provide your own mechanism.

=head2 login_form_status($r): int

This method returns the HTTP status code that will be returned with the login
form response.  The default behaviour is to return HTTP_FORBIDDEN, except for
some known browsers which ignore HTML content for HTTP_FORBIDDEN responses
(e.g.: SymbianOS).  You can override this method to return custom codes.

Note that HTTP_FORBIDDEN is the most correct code to return as the given
request was not authorized to view the requested page.  You should only change
this if HTTP_FORBIDDEN does not work.

=head2 logout($r): void

This is simply a convenience method that unsets the session key for you.  You
can call it in your logout scripts.  Usually this looks like
C<$r-E<gt>auth_type-E<gt>logout($r)>.

=head2 params($r): Apache2::AuthCookie::Params

Get the GET/POST params object for this request.

=head2 recognize_user($r): int

If the user has provided a valid session key but the document isn't protected,
this method will set C<$r-E<gt>user> anyway.  Use it as a PerlFixupHandler,
unless you have a better idea.

=head2 remove_cookie($r): void

Adds a C<Set-Cookie> header that instructs the client to delete the cookie
immediately.

=head2 requires_encoding($r): string

Return the ${auth_name}RequiresEncoding setting that is in effect for this request.

=head2 send_cookie($r, $ses_key, $args): void

By default this method simply sends out the session key you give it.  If you
need to change the default behavior (perhaps to update a timestamp in the key)
you can override this method.

=head2 send_p3p($r): void

Set a P3P response header if C<${auth_name}P3P> is configured.  The value of
the header is whatever is in the C<${auth_name}P3P> setting.

=head2 untaint_destination($destination): string

This method returns a modified version of the destination parameter before
embedding it into the response header. Per default it escapes CR, LF and TAB
characters of the uri to avoid certain types of security attacks. You can
override it to more limit the allowed destinations, e.g., only allow relative
uris, only special hosts or only limited set of characters.

=for Pod::Coverage  OK
 DECLINED
 SERVER_ERROR
 M_GET
 HTTP_FORBIDDEN
 HTTP_MOVED_TEMPORARILY
 HTTP_OK

=head1 SOURCE

The development version is on github at L<https://github.com/mschout/apache-authcookie>
and may be cloned from L<https://github.com/mschout/apache-authcookie.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/mschout/apache-authcookie/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Michael Schout <mschout@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2000 by Ken Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
