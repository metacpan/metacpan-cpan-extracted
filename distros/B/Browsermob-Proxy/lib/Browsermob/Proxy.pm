package Browsermob::Proxy;
$Browsermob::Proxy::VERSION = '0.17';
# ABSTRACT: Perl client for the proxies created by the Browsermob server
use Moo;
use Carp;
use JSON;
use Net::HTTP::Spore;
use Net::HTTP::Spore::Middleware::DefaultParams;
use Net::HTTP::Spore::Middleware::Format::Text;


my $spec = {
    name => 'BrowserMob Proxy',
    formats => ['json'],
    version => '0.01',
    # server name and port are constructed in the _spore builder
    # base_url => '/proxy',
    methods => {
        get_proxies => {
            method => 'GET',
            path => '/',
            description => 'Get a list of ports attached to ProxyServer instances managed by ProxyManager'
        },
        create => {
            method => 'POST',
            path => '/',
            optional_params => [
                'port'
            ],
            description => 'Create a new proxy. Returns a JSON object {"port": your_port} on success"'
        },
        delete_proxy => {
            method => 'DELETE',
            path => '/:port',
            required_params => [
                'port'
            ],
            description => 'Shutdown the proxy and close the port'
        },
        create_new_har => {
            method => 'PUT',
            path => '/:port/har',
            optional_params => [
                'initialPageRef',
                'captureHeaders',
                'captureContent',
                'captureBinaryContent'
            ],
            required_params => [
                'port'
            ],
            description => 'creates a new HAR attached to the proxy and returns the HAR content if there was a previous HAR.'
        },
        retrieve_har => {
            method => 'GET',
            path => '/:port/har',
            required_params => [
                'port'
            ],
            description => 'returns the JSON/HAR content representing all the HTTP traffic passed through the proxy'
        },
        auth_basic => {
            method => 'POST',
            path => '/:port/auth/basic/:domain',
            required_params => [
                'port',
                'domain'
            ],
            description => 'Sets automatic basic authentication for the specified domain'
        },
        filter_request => {
            method => 'POST',
            path => '/:port/filter/request',
            required_params => [
                'port'
            ],
            description => 'Modify request/payload with javascript'
        },
        set_timeout => {
            method => 'PUT',
            path => '/:port/timeout',
            required_params => [
                'port',
            ],
            optional_params => [
                'requestTimeout',
                'readTimeout',
                'connectionTimeout',
                'dnsCacheTimeout'
            ],
            description => 'Handles different proxy timeouts'
        }
    }
};


has server_addr => (
    is => 'rw',
    default => sub { '127.0.0.1' }
);



has server_port => (
    is => 'rw',
    default => sub { 8080 }
);


has port => (
    is => 'rw',
    lazy => 1,
    predicate => 'has_port',
    default => sub { '' }
);


has trace => (
    is => 'ro',
    default => sub { 0 }
);

has mock => (
    is => 'rw',
    lazy => 1,
    predicate => 'has_mock',
    default => sub { '' }
);

has _spore => (
    is => 'ro',
    lazy => 1,
    handles => [keys %{ $spec->{methods} }],
    builder => sub {
        my $self = shift;
        my $client = Net::HTTP::Spore->new_from_string(
            to_json($self->_spec),
            trace => $self->trace
        );

        $self->_set_middlewares($client, 'json');

        return $client;
    }
);

around filter_request => sub {
    my ($orig, $self, @args) = @_;
    my $client = $self->_spore;
    $self->_set_middlewares($client, 'text');
    $orig->($self, @args);
    $self->_set_middlewares($client, 'json');
};

sub _set_middlewares {
    my ($self, $client, $type) = @_;
    $client->reset_middlewares;

    if ($type eq 'json') {
        $client->enable('Format::JSON');
    }
    elsif ($type eq 'text') {
        $client->enable('Format::Text');
    }

    if ($self->has_port) {
        $client->enable('DefaultParams', default_params => {
            port => $self->port
        });
    }

    if ($self->has_mock) {
        # The Mock middleware ignores any middleware enabled after
        # it; make sure to enable everything else first.
        $client->enable('Mock', tests => $self->mock);
    }
}

has _spec => (
    is => 'ro',
    lazy => 1,
    builder => sub {
        my $self = shift;
        $spec->{base_url} = 'http://' . $self->server_addr . ':' . $self->server_port . '/proxy';
        return $spec;
    }
);

sub BUILD {
    my ($self, $args) = @_;
    my $res = $self->create;

    unless ($self->has_port) {
        $self->port($res->body->{port});
        $self->_set_middlewares( $self->_spore, 'json' );
    }
}


sub new_har {
    my ($self, $initial_page_ref) = @_;
    my $payload = {};

    croak "You need to create a proxy first!" unless $self->has_port;
    if (defined $initial_page_ref) {
        $payload->{initialPageRef} = $initial_page_ref;
    }

    $self->_spore->create_new_har(payload => $payload);
}


sub har {
    my ($self) = @_;

    croak "You need to create a proxy first!" unless $self->has_port;
    return $self->_spore->retrieve_har->body;
}


sub selenium_proxy {
    my ($self, $initiate_manually) = @_;
    $self->new_har unless $initiate_manually;

    return {
        proxyType => 'manual',
        httpProxy => 'http://' . $self->server_addr . ':' . $self->port,
        sslProxy => 'http://' . $self->server_addr . ':' . $self->port
    };
}


sub firefox_proxy {
    my ($self, $initiate_manually) = @_;
    $self->new_har unless $initiate_manually;

    return {
        'network.proxy.type' => 1,
        'network.proxy.http' => $self->server_addr,
        'network.proxy.http_port' => $self->port,
        'network.proxy.ssl' => $self->server_addr,
        'network.proxy.ssl_port' => $self->port
    };
}


sub ua_proxy {
    my ($self, $initiate_manually) = @_;
    $self->new_har unless $initiate_manually;

    return ('http', 'http://' . $self->server_addr . ':' . $self->port);
}


sub set_env_proxy {
    my ($self, $initiate_manually) = @_;
    $self->new_har unless $initiate_manually;

    $ENV{http_proxy} = 'http://' . $self->server_addr . ':' . $self->port;
    $ENV{https_proxy} = 'http://' . $self->server_addr . ':' . $self->port;
    $ENV{ssl_proxy} = 'http://' . $self->server_addr . ':' . $self->port;
}


sub add_basic_auth {
    my ($self, $args) = @_;
    foreach (qw/domain username password/) {
        croak "$_ is a required parameter for add_basic_auth"
        unless exists $args->{$_};
    }

    $self->auth_basic(
        domain => delete $args->{domain},
        payload => $args
    );
}


sub set_request_header {
    my ($self, $header, $value) = @_;
    croak 'Please pass a ($header, $value) as arguments when setting a header'
      unless $header and $value;

    $self->_set_header('request', $header, $value);
}

sub _set_header {
    my ($self, $type, $header, $value) = @_;

    $self->filter_request(
        payload => "
$type.headers().remove('$header');
$type.headers().add('$header', '$value');
"
    );
}



sub DEMOLISH {
    my ($self, $gd) = @_;
    return if $gd;

    eval { $self->delete_proxy };
    warn $@ if $@ and $self->trace;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Browsermob::Proxy - Perl client for the proxies created by the Browsermob server

=for markdown [![Build Status](https://travis-ci.org/gempesaw/Browsermob-Proxy.svg?branch=master)](https://travis-ci.org/gempesaw/Browsermob-Proxy)

=head1 VERSION

version 0.17

=head1 SYNOPSIS

Standalone:

    my $proxy = Browsermob::Proxy->new(
        server_port => 9090
        # port => 9092
    );

    print $proxy->port;
    $proxy->new_har('Google');
    # create network traffic across your port
    $proxy->har; # returns a HAR as a hashref, converted from JSON

with L<Browsermob::Server>:

    my $server = Browsermob::Server->new(
        server_port => 9090
    );
    $server->start; # ignore if your server is already running

    my $proxy = $server->create_proxy;
    $proxy->new_har('proxy from server!');

=head1 DESCRIPTION

From L<http://bmp.lightbody.net/>:

=over 4

BrowserMob proxy is based on technology developed in the Selenium open
source project and a commercial load testing and monitoring service
originally called BrowserMob and now part of Neustar.

It can capture performance data for web apps (via the HAR format), as
well as manipulate browser behavior and traffic, such as whitelisting
and blacklisting content, simulating network traffic and latency, and
rewriting HTTP requests and responses.

=back

This module is a Perl client interface to interact with the server and
its proxies. It uses L<Net::HTTP::Spore>. You can use
L<Browsermob::Server> to manage the server itself in addition to using
this module to handle the proxies.

=head2 INSTALLATION

We depend on L<Net::HTTP::Spore> to set up our communication with the
Browsermob server. Unfortunately, there hasn't been a recent release
and due to breaking changes in new versions of its dependencies, you
might run in to problems installing its current CPAN version
v0.06. And, thus installing this module may be difficult.

We're using a fork of L<Net::HTTP::Spore> that is kept slightly ahead
of master with the bug fixes merged in; installation via
L<App::cpanminus> looks like:

    cpanm git://github.com/gempesaw/net-http-spore.git@build/master

=head1 ATTRIBUTES

=head2 server_addr

Optional: specify where the proxy server is; defaults to 127.0.0.1

    my $proxy = Browsermob::Proxy->new(server_addr => '127.0.0.1');

=head2 server_port

Optional: Indicate at what port we should expect a Browsermob Server
to be running; defaults to 8080

    my $proxy = Browsermob::Proxy->new(server_port => 8080);

=head2 port

Optional: When instantiating a proxy, you can choose the proxy port on
your own, or let the server automatically assign you an unused port.

    my $proxy = Browsermob::Proxy->new(port => 9091);

=head2 trace

Set Net::HTTP::Spore's trace option; defaults to 0; set it to 1 to see
headers and 2 to see headers and responses. This can only be set during
construction; changing it afterwards will have no impact.

    my $proxy = Browsermob::Proxy->new( trace => 2 );

=head1 METHODS

=head2 new_har

After creating a proxy, C<new_har> creates a new HAR attached to the
proxy and returns the HAR content if there was a previous one. If no
argument is passed, the initial page ref will be "Page 1"; you can
also pass a string to choose your own initial page ref.

    $proxy->new_har;
    $proxy->new_har('Google');

This convenience method is just a helper around the actual endpoint
method C</create_new_har>; it uses the defaults of not capturing
headers, request/response bodies, or binary content. If you'd like to
capture those items, you can use C<create_new_har> as follows:

    $proxy->create_new_har(
        payload => {
            initialPageRef => 'payload is optional'
        },
        captureHeaders => 'true',
        captureContent => 'true',
        captureBinaryContent => 'true'
    );

=head2 har

After creating a proxy and initiating a L<new_har>, you can retrieve
the contents of the current HAR with this method. It returns a hashref
HAR, and may in the future return an isntance of L<Archive::HAR>.

    my $har = $proxy->har;
    print Dumper $har->{log}->{entries}->[0];

=head2 selenium_proxy

Generate the proper capabilities for use in the constructor of a new
Selenium::Remote::Driver object.

    my $proxy = Browsermob::Proxy->new;
    my $driver = Selenium::Remote::Driver->new(
        browser_name => 'chrome',
        proxy        => $proxy->selenium_proxy
    );
    $driver->get('http://www.google.com');
    print Dumper $proxy->har;

N.B.: C<selenium_proxy> will AUTOMATICALLY call L</new_har> for you
initiating an unnamed har, unless you pass it something truthy.

    my $proxy = Browsermob::Proxy->new;
    my $driver = Selenium::Remote::Driver->new(
        browser_name => 'chrome',
        proxy        => $proxy->selenium_proxy(1)
    );
    # later
    $proxy->new_har;
    $driver->get('http://www.google.com');
    print Dumper $proxy->har;

=head2 firefox_proxy

Generate a hash with the proper keys and values that for use in
setting preferences for a
L<Selenium::Remote::Driver::Firefox::Profile>. This method returns a
hashref; dereference it when you pass it to
L<Selenium::Remote::Driver::Firefox::Profile/set_preference>:

    my $profile = Selenium::Remote::Driver::Firefox::Profile->new;

    my $firefox_pref = $proxy->firefox_proxy;
    $profile->set_preference( %{ $firefox_pref } );

    my $driver = Selenium::Remote::Driver->new_from_caps(
        desired_capabilities => {
            browserName => 'Firefox',
            firefox_profile => $profile->_encode
        }
    );

N.B.: C<firefox_proxy> will AUTOMATICALLY call L</new_har> for you
initiating an unnamed har, unless you pass it something truthy.

=head2 ua_proxy

Generate the proper arguments for the proxy method of
L<LWP::UserAgent>. By default, C<ua_proxy> will initiate a new har for
you automatically, the same as L</selenium_proxy> does. If you want to
initialize the har yourself, pass in something truthy.

    my $proxy = Browsermob::Proxy->new;
    my $ua = LWP::UserAgent->new;
    $ua->proxy($proxy->ua_proxy);

=head2 set_env_proxy

Export to C<%ENV> the properties of this proxy's port. This can be
used in tandem with <LWP::UserAgent/env_proxy>. This will set the
appropriate environment variables, and then your C<$ua> will pick it
up when its C<env_proxy> method is invoked aftewards. As usual, this
will create a new HAR unless you deliberately inhibit it.

    $proxy->set_env_proxy;
    $ua->env_proxy;

In particular, we set C<http_proxy>, C<https_proxy>, and C<ssl_proxy>
to the appropriate server and port by defining them as keys in C<%ENV>.

=head2 add_basic_auth

Set up automatic Basic authentication for a specified domain. Accepts
as input a HASHREF with the keys C<domain>, C<username>, and
C<password>. For example,

    $proxy->add_basic_auth({
        domain => '.google.com',
        username => 'username',
        password => 'password'
    });

=head2 set_request_header ( $header, $value )

Takes two STRINGs as arguments. (Unhelpfully) returns a
Net::HTTP::Spore::Response. With this method, we will remove the
specified C<$header> from every request the proxy sees, and replace it
with the C<$header> C<$value> pair that you pass in.

    $proxy->set_request_header( 'User-Agent', 'superwoman' );

Under the covers, we are using L</filter_request> with a Javascript
Rhino payload.

=head2 set_timeout ( $timeoutType => $milliseconds )

Set different time outs on the instantiated proxy. You can set
multiple timeouts at once, if you like.

    $proxy->timeout(
        requestTimeout => 5000,
        readTimeout => 6000
    );

=over 4

=item *

requestTimeout

Request timeout in milliseconds. A timeout value of -1 is interpreted
as infinite timeout. It equals -1 by default.

=item *

readTimeout

Read timeout is the timeout for waiting for data or, put differently,
a maximum period inactivity between two consecutive data packets. A
timeout value of zero is interpreted as an infinite timeout. It equals
60000 by default.

=item *

connectionTimeout

Determines the timeout in milliseconds until a connection is
established. A timeout value of zero is interpreted as an infinite
timeout. It eqauls 60000 by default.

=item *

dnsCacheTimeout

Sets the maximum length of time that records will be stored in this
Cache. A nonpositive value disables this feature (that is, sets no
limit). It equals 0 by default.

=back

=head2 delete_proxy

Delete the proxy off of the server, shutting down the port. Although
we do try to do this in our DEMOLISH method, we can't do anything if
the C<$proxy> object is kept around during global destruction. If
you're noticing that your BMP server has leftover proxies, you should
start either explicitly C<undef>ing the `$proxy` object or invoking
this method.

    # calls ->delete_proxy in our DEMOLISH method, explicitly not
    # during global destruction!
    undef $proxy;

    # manually delete the proxy from the BMP server
    $proxy->delete_proxy;

After deleting the proxy, invoking any other method will probably lead
to a C<die> from inside the Net::HTTP::Spore module somewhere.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<http://bmp.lightbody.net/|http://bmp.lightbody.net/>

=item *

L<https://github.com/lightbody/browsermob-proxy|https://github.com/lightbody/browsermob-proxy>

=item *

L<Browsermob::Server|Browsermob::Server>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Browsermob-Proxy/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
