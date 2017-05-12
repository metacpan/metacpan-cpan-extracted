package Authen::Simple::WebForm;

use warnings;
use strict;
use base 'Authen::Simple::Adapter';

use URI;
use LWP;
use LWP::ConnCache;
use Params::Validate qw[];

=head1 NAME

Authen::Simple::WebForm - Simple authentication against existing web based forms.

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

__PACKAGE__->options({
    initial_url => {
        type        => Params::Validate::SCALAR,
        default     => '',
        optional    => 1,
    },
    # compiled regex or string
    initial_expect => {
        type        => Params::Validate::SCALAR,
        default     => '',
        optional    => 1,
    },
    # compiled regex or string
    initial_expect_cookie => {
        type        => Params::Validate::SCALAR | Params::Validate::SCALARREF,
        default     => '',
        optional    => 1,
    },
    check_initial_status_code => {
        type        => Params::Validate::BOOLEAN,
        default     => 1,
        optional    => 1,
    },
    initial_request_method => {
        type        => Params::Validate::SCALAR,
        default     => 'GET',
        optional    => 1,
    },
    login_url => {
        type        => Params::Validate::SCALAR,
        default     => '',
        optional    => 0,
    },
    # compiled regex or string
    login_expect => {
        type        => Params::Validate::SCALAR | Params::Validate::SCALARREF,
        default     => '',
        optional    => 1,
    },
    # compiled regex or string
    login_expect_cookie => {
        type        => Params::Validate::SCALAR | Params::Validate::SCALARREF,
        default     => '',
        optional    => 1,
    },
    check_login_status_code => {
        type        => Params::Validate::BOOLEAN,
        default     => 1,
        optional    => 1,
    },
    login_request_method => {
        type        => Params::Validate::SCALAR,
        default     => 'POST',
        optional    => 1,
    },
    # for "domain\" if needed
    username_prefix => {
        type        => Params::Validate::SCALAR,
        default     => '',
        optional    => 1,
    },
    username_field => {
        type        => Params::Validate::SCALAR,
        default     => 'username',
        optional    => 1,
    },
    password_field => {
        type        => Params::Validate::SCALAR,
        default     => 'password',
        optional    => 1,
    },
    lwp_user_agent => {
        type        => Params::Validate::SCALAR,
        default     => 'Authen::Simple::WebForm/'.$VERSION,
        optional    => 1,
    },
    lwp_timeout     => {
        type        => Params::Validate::SCALAR,
        default     => '15',
        optional    => 1,
    },
    lwp_protocols_allowed => {
        type        => Params::Validate::ARRAYREF,
        default     => ['http', 'https'],
        optional    => 1,
    },
    lwp_use_conn_cache => {
        type        => Params::Validate::BOOLEAN,
        default     => 1,
        optional    => 1,
    },
    lwp_requests_redirectable => {
        type        => Params::Validate::ARRAYREF,
        default     => ['GET', 'POST'],
        optional    => 1,
    },
    # yes, this looks like a hash, but it's not (allows keys to show up twice)
    # [ field => value, field => value ]
    extra_fields => {
        type        => Params::Validate::ARRAYREF,
        default     => [],
        optional    => 1,
    },
    # yes, this looks like a hash, but it's not (allows keys to show up twice)
    # [ field => value, field => value ]
    extra_headers => {
        type        => Params::Validate::ARRAYREF,
        default     => [],
        optional    => 1,
    },
    trace => {
        type        => Params::Validate::BOOLEAN,
        default     => 0,
        optional    => 1,
    },
});


=head1 SYNOPSIS

    use Authen::Simple::WebForm;

    my $webform = Authen::Simple::WebForm->new(
        login_url       => 'http://host.company.com/login.pl',
        login_expect    => 'Successful Login',
    );

    if ($webform->authenticate( $username, $password ) ) {
        # successful authentication
    }

    # or as a mod_perl Authen handler
    
    PerlModule Authen::Simple::Apache
    PerlModule Authen::Simple::WebForm

    PerlSetVar AuthenSimpleWebForm_login_url "http://host.company.com/login.pl"
    PerlSetVar AuthenSimpleWebForm_login_expect "Successful Login"

    <Location /protected>
      PerlAuthenHandler Authen::Simple::WebForm
      AuthType          Basic
      AuthName          "Protected Area"
      Require           valid-user
    </Location>

=head1 DESCRIPTION

Authentication against a variety of login forms. This wraps up the LWP (libwww-perl)
calls needed to attempt a login to a site that uses an HTML form for logins. It supports
logins that require cookies, various form variables, special headers, and more.

You can also subclass this to make it easier to setup, such as the
L<Authen::Simple::OWA2003> module.

There are a log of options, but they all have sane defaults. In most cases, you'll only need to use the following:

=over

=item login_url

=item login_expect

=item uesrname_field

=item password_field

=item extra_fields

=back


Also helpful may be the "trace" option, which may help you to configure
your settings. It will print out the response code, cookies, and the resulting
page to STDERR.


=head1 INSTALLATION

To install this module, run the following commands:

    perl Makefile.PL
    make
    make test
    make install


=head1 METHODS

=head2 new

This method takes a hash of parameters. The following options are accepted:

=over

=item initial_url

A URL to go to prior to logging in.

If the login page requires you to go to some page prior to posting, use this.
It will accept and store any cookies returned, and use this page as the 
referrer when submitting to the login form.

Off by default.


=item initial_expect

String or a compiled regex (eg. C<qr/please\s+login/i>).

If you want to make sure the page you got is the login form, you can set
a string here to check for. The page content will be tested against this,
and authentication will fail (with a logged error) if this doesn't match.

With this, you can make sure the server isn't returning a sorry server page, or similar.

Off by default.


=item initial_expect_cookie

String or a compiled regex (eg. C<qr/please\s+login/i>).

Similar to initial_expect, but checks the cookies returned by the page.

NOTE: this matches the cookie key, and the value must simple have some length.

Off by default.


=item check_initial_status_code

Boolean, set to 0 to disable.

Set to undef to skip checking the response status code from the initial page. Otherwise, it must match HTTP::Status->is_success.

Defaults to enabled (1).


=item initial_request_method

This can be either "GET" or "POST".

How the initial url will be sent to the server, either via HTTP GET request, or HTTP POST.

Defaults to "GET".


=item login_url

REQUIRED

The URL to which the login credentials will be submitted.

For example: https://host.company.com/login.pl


=item login_expect

String or a compiled regex (eg. C<qr/login\s+successful/i>).

Set to a unique string to expect in the resulting page when the login was successful.

Be default, this is not turned on. If you do not set this, then as long as the
server returns a successful status code (see HTTP::Status::is_success), then
the user will be authenticated. Most form based login systems return a successful
status code even when the login fails, so you'll probably want to set this.

A notable exception is the use of something like L<Apache::AuthCookie>, which
will return a 403 Forbidden error code when authentication fails.

Off by default.


=item login_expect_cookie

String or a compiled regex (eg. C<qr/please\s+login/i>).

Similar to login_expect, but checks the cookies returned by the page. If you are also using "initial_url", please be aware that an cookies set by that page will also test true here (ie. this checks our cookie jar, not the content of the page). The cookie jar is reset on every authentication request, so you don't have to worry about stale cookies from previous authentication attempts.

NOTE: this matches the cookie key, and the value must simple have some length.

Off by default.


=item check_login_status_code

Boolean, set to 0 to disable.

Set to undef to skip checking the response status code from the login page. Otherwise, it must match HTTP::Status->is_success.

Defaults to enabled (1).


=item login_request_method

This can be either "GET" or "POST".

How the initial url will be sent to the server, either via HTTP GET request, or HTTP POST.

Defaults to "POST".


=item username_prefix

Username prefix string.

With this, you can automatically prefix your the submitted username with
some string. This can can be useful if loging into a windows domain, for
example. In that case, you would set it to something like "MyDomain\".

Off be default.


=item username_field

Form field name for the username.

Defaults to "username".


=item password_field

Form field name for the password.

Defaults to "password".


=item extra_fields

Array reference of key => value pairs, representing additional form fields to submit.

Often when submitting to a login form, other form fields are expected by the
login script. You may specify any number of them, and their repsective values,
using this option.

Example:

    extra_fields => [
        'language' => 'en_US',
        'trusted'  => 1
        ],

None submitted by default.


=item extra_headers

Array reference of key => value pairs, representing additional HTTP headers.

You can use this if you need to further mask your client to appear as 
a popular web browser. Some misbehaved servers may reject your script
if these are not set.

Example: (pose as netscape)

    extra_headers => [
       'User-Agent' => 'Mozilla/4.76 [en] (Win98; U)',
       'Accept' => 'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, image/png, */*',
       'Accept-Charset' => 'iso-8859-1,*,utf-8',
       'Accept-Language' => 'en-US'
        ],

None submitted by default.


=item lwp_user_agent

The HTTP User Agent string to submit to the server in the HTTP headers.

Some servers may restrict access to certain user agents (ie. limit only
to MS Internet Explorer and Mozilla clients). You can forge a user agent
string with this.

Example:

    lwp_user_agent => 'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.14) Gecko/2009090216 Ubuntu/9.04 (jaunty) Firefox/3.0.14',

Defaults to "Authen::Simple::WebForm/$VERSION".


=item lwp_timeout

Timeout in seconds. Set to zero to disable.

This is how long the script will wait for a response for each page fetch.

Defaults to "15" seconds.


=item lwp_protocols_allowed

Array reference of protocols to allow.

This will limit what protocols will be fetched. You're already setting the
URLS that will be loaded, but if you allow redirects (via lwp_requests_redirectable)
then those may go to a different protocol. For example, you may submit to an
SSL protected site (https) but be redirected to an unprotected page (http).

Defaults to ["http", "https"]


=item lwp_use_conn_cache

Boolean, set to 0 to disable.

Whether to use connection caching. See L<LWP::ConnCache> for details, as well as the "conn_cache" option to L<LWP>.

Defaults to enabled (1).


=item lwp_requests_redirectable

Array reference of request names for which we will automatically redirect.

See L<LWP> option requests_redirectable for details. This affects the responses
we get from the server. For example, if you are posting form data
(login_request_method == POST), and the successful login page returns a redirect
to some other page, "POST" would be needed here. We allow GET and POST by
default, so you only need to set this is if do not want this behavior.

Defaults to ["GET", "POST"]


=item trace

Boolean, set to 1 to enable.

If set to true, the data we recieve will be dumped out to STDERR.
This can be useful while you're trying to determine what fields need
passed, and what might be going wrong. When running your test scripts,
assuming your are starting from a test script, simply dump STDERR
to a file:

    perl test.pl 2>somefile.txt

Defaults to disabled (0).


=back


=head2 log

Any object that supports C<debug>, C<info>, C<error> and C<warn>.

    log => Log::Log4perl->get_logger('Authen::Simple::WebForm')

See L<Authen::Simple::Log> for a simple logging class you may use,
or L<Log::Log4perl> for more advanced logging.


=head2 authenticate( $username, $password )

Returns true on success and false on failure.

=head2 check($user, $pass)

Internal method used to do the actual authentication check.

=cut


sub check
{
    my ($self, $username, $password) = @_;

    # prepend prefix. If none set, or blank, this will just be $username
    my $full_username = join('', ($self->username_prefix, $username));

    # prep any additional headers we might need
    my @headers;
    my $extra_headers = $self->extra_headers;
    if (ref($extra_headers) eq 'ARRAY' && @$extra_headers)
    {
        if ((@$extra_headers % 2) == 0)
        {
            push(@headers, @$extra_headers);
        } else {
            $self->log->error("Invalid extra_headers option.") if $self->log;
            return 0;
        }
    }

    # determine request method
    my $initial_req_method = uc($self->initial_request_method || 'GET');
    unless ($initial_req_method =~ /^(GET|POST)$/i) {
        $self->log->error("Invalid initial_request_method.") if $self->log;
        return 0;
    }
    my $login_req_method = uc($self->login_request_method || 'GET');
    unless ($login_req_method =~ /^(GET|POST)$/i) {
        $self->log->error("Invalid login_request_method.") if $self->log;
        return 0;
    }

    # initialize the user agent
    my $ua = LWP::UserAgent->new() or die "Unable to init LWP::UserAgent : $@";
    # keep in memory cookie jar
    $ua->cookie_jar({});
    $ua->agent($self->lwp_user_agent) if $self->lwp_user_agent;
    $ua->timeout( $self->lwp_timeout ) if $self->lwp_timeout;
    $ua->conn_cache(LWP::ConnCache->new()) if $self->lwp_use_conn_cache;

    my $req_redirectable = $self->lwp_requests_redirectable;
    if (ref($req_redirectable) eq 'ARRAY' && @$req_redirectable) {
        push @{$ua->requests_redirectable}, @$req_redirectable;
    }

    # get an inital page?
    if ($self->initial_url)
    {
        my $res = ($initial_req_method eq 'GET') ? $ua->get($self->initial_url, @headers):
                                                   $ua->post($self->initial_url, @headers);
        if ($self->trace)
        {
            print STDERR ("-"x80)."\n";
            print STDERR "TRACE: initial response, response code [".$res->code."]\n";
            print STDERR "TRACE: initial response, cookies [".$ua->cookie_jar->as_string()."]\n";
            print STDERR $res->decoded_content;
            print STDERR "\n\n\n";
            print STDERR ("-"x80)."\n";
        }
        # make sure status code is ok?
        if ($self->check_initial_status_code)
        {
            unless ($res->is_success)
            {
                $self->log->error("Can't get ".$self->initial_url." -- ".$res->status_line)
                    if $self->log;
                return 0;
            }
        }

        # do we care to check the content?
        if ($self->initial_expect)
        {
            my $expect = $self->initial_expect;
            unless (ref($expect) eq 'Regexp') {
                $expect = qr/\Q$expect\E/;
            }
            unless ($res->decoded_content =~ /$expect/)
            {
                $self->log->error("Initial url didn't return expected results.") if $self->log;
                return 0;
            }
        }

        # do we care to check for a cookie
        if ($self->initial_expect_cookie)
        {
            my $expect = $self->initial_expect_cookie;

            my $found = 0;
            my $search; # cookie_jar search callback

            if (ref($expect) eq 'Regexp')
            {
                $search = sub { $found++ if $_[1] =~ /$expect/ && length($_[2]); };
            } else {
                $search = sub { $found++ if $_[1] eq $expect && length($_[2]); };
            }

            # search the cookie jar
            $ua->cookie_jar->scan($search);
            unless ($found)
            {
                $self->log->debug("Failed to authenticate user '$full_username'. Reason: Initial Cookie $expect was not found.")
                    if $self->log;
                return 0;
            }
        }
    }


    # build data to post
    my @data = (
        $self->username_field   => $full_username,
        $self->password_field   => $password
        );
    # add an extra fields to submit
    my $extra_fields = $self->extra_fields;
    if (ref($extra_fields) eq 'ARRAY' && @$extra_fields)
    {
        if ((@$extra_fields % 2) == 0)
        {
            push(@data, @$extra_fields);
        } else {
            $self->log->error("Invalid extra_fields option.") if $self->log;
            return 0;
        }
    }

    # attempt to login
    my $res;
    if ($login_req_method eq 'GET')
    {
        my $url = URI->new($self->login_url);
        unless ($url) {
            $self->log->error("Unable to parse login_url. $@") if $self->log;
            return 0;
        }
        $url->query_form( \@data );
        $res = $ua->get($url, @headers);
    } else { # POST
        $res = $ua->post($self->login_url, \@data, @headers);
    }
    if ($self->trace)
    {
        print STDERR ("-"x80)."\n";
        print STDERR "TRACE: initial response, response code [".$res->code."]\n";
        print STDERR "TRACE: initial response, cookies [".$ua->cookie_jar->as_string()."]\n";
        print STDERR $res->decoded_content;
        print STDERR "\n\n\n";
        print STDERR ("-"x80)."\n";
    }

    # make sure status code is ok?
    if ($self->check_login_status_code)
    {
        unless ($res->is_success)
        {
            if ($res->is_redirect)
            {
                $self->log->debug("Failed to authenticate user '$full_username'. Reason: Login page returned redirect status code '".$res->code."'. You may wish to enable lwp_requests_redirectable -- ".$res->status_line)
                    if $self->log;
            } else {
                $self->log->debug("Failed to authenticate user '$full_username'. Reason: Login page returned invalid status code '".$res->code."' -- ".$res->status_line)
                    if $self->log;
            }
            return 0;
        }
    }

    # do we care to check the content?
    if ($self->login_expect)
    {
        my $expect = $self->login_expect;
        unless (ref($expect) eq 'Regexp') {
            $expect = qr/\Q$expect\E/;
        }
        unless ($res->decoded_content =~ /$expect/)
        {
            $self->log->debug("Failed to authenticate user '$full_username'. Reason: Login page response did not match expected value.")
                if $self->log;
            return 0;
        }
    }

    # do we care to check for a cookie
    if ($self->login_expect_cookie)
    {
        my $expect = $self->login_expect_cookie;

        my $found = 0;
        my $search; # cookie_jar search callback

        if (ref($expect) eq 'Regexp')
        {
            $search = sub { $found++ if $_[1] =~ /$expect/ && length($_[2]); };
        } else {
            $search = sub { $found++ if $_[1] eq $expect && length($_[2]); };
        }

        # search the cookie jar
        $ua->cookie_jar->scan($search);
        unless ($found)
        {
            $self->log->debug("Failed to authenticate user '$full_username'. Reason: Login Cookie $expect was not found.")
                if $self->log;
            return 0;
        }
    }

    $self->log->debug("Successfully authenticated user '$full_username'.") if $self->log;
    return 1;
}

=head1 TODO

Add lwp_cookie_jar option(s) so that it may use a file.

Add a debug mode. It's often difficult to determine what content is being returned, and what to look for. The debug mode should print each step out to STDERR, and include the relevant response information from the page.

Write tests using HTTP::Daemon as a local webserver. See LWP test t/local/http.t and t/local/chunked.t for example.

=head1 AUTHOR

Joshua I. Miller, C<< <unrtst at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-authen-simple-webform at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Authen-Simple-WebForm>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Authen::Simple::WebForm


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Authen-Simple-WebForm>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Authen-Simple-WebForm>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Authen-Simple-WebForm>

=item * Search CPAN

L<http://search.cpan.org/dist/Authen-Simple-WebForm>

=back


=head1 SEE ALSO

L<Authen::Simple>

L<Authen::Simple::OWA2003>

examples/ex1.pl (an example that can be used to auth against freshmeat.net).

L<LWP>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Joshua I. Miller, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Authen::Simple::WebForm
