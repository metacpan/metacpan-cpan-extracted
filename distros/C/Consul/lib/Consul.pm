package Consul;
$Consul::VERSION = '0.027';
# ABSTRACT: Client library for consul

use namespace::autoclean;

use HTTP::Tiny 0.014;
use URI::Escape qw(uri_escape);
use JSON::MaybeXS qw(JSON);
use Hash::MultiValue;
use Try::Tiny;
use Carp qw(croak);

use Moo;
use Type::Utils qw(class_type);
use Types::Standard qw(Str Int Bool HashRef CodeRef);

has host => ( is => 'ro', isa => Str, default => sub { '127.0.0.1' } );
has port => ( is => 'ro', isa => Int, default => sub { 8500 } );

has ssl => ( is => 'ro', isa => Bool, default => sub { 0 } );

has timeout => ( is => 'ro', isa => Int, default => sub { 15 } );

has token => ( is => 'ro', isa => Str, predicate => '_has_token' );

has _http => ( is => 'lazy', isa => class_type('HTTP::Tiny') );
sub _build__http { HTTP::Tiny->new(timeout => shift->timeout) };

has _version_prefix => ( is => 'ro', isa => Str, default => sub { '/v1' } );

has _url_base => ( is => 'lazy' );
sub _build__url_base {
    my ($self) = @_;
    ($self->ssl ? 'https' : 'http') .'://'.$self->host.':'.$self->port;
}

sub _prep_url {
    my ($self, $path, %args) = @_;
    my $trailing = $path =~ m{/$};
    my $url = $self->_url_base.join('/', map { uri_escape($_) } split('/', $path));
    $url .= '/' if $trailing;
    $url .= '?'.$self->_http->www_form_urlencode(\%args) if %args;
    $url;
}

my $json = JSON->new->utf8->allow_nonref;

sub _prep_request {
    my $callback = pop @_;
    my ($self, $path, $method, %args) = @_;

    my %uargs = map { m/^_/ ? () : ($_ => $args{$_}) } keys %args;

    my $headers = Hash::MultiValue->new;

    if ($self->_has_token()) {
        $headers->set( 'X-Consul-Token', $self->token() );
    }

    return Consul::Request->new(
        method   => $method,
        url      => $self->_prep_url($path, %uargs),
        headers  => $headers,
        content  => defined( $args{_content} ) ? $args{_content} : "",
        callback => $callback,
        args     => \%uargs,
    );
}

sub _prep_response {
    my ($self, $resp, %args) = @_;

    my $data;
    $data = $json->decode($resp->content) if length $resp->content > 0;

    my $meta = try { Consul::Meta->new(%{$resp->headers}) };

    return ($data, $meta);
}

has request_cb => ( is => 'lazy', isa => CodeRef );
sub _build_request_cb {
    sub {
        my ($self, $req) = @_;
        my $res = $self->_http->request($req->method, $req->url, {
            headers => $req->headers->mixed,
            content => $req->content,
        });
        my $rheaders = Hash::MultiValue->from_mixed(delete $res->{headers} || {});
        my ($rstatus, $rreason, $rcontent) = @$res{qw(status reason content)};
        $req->callback->(Consul::Response->new(
            status  => $rstatus,
            reason  => $rreason,
            headers => $rheaders,
            content => $rcontent,
            request => $req,
        ));
    }
}

has error_cb => ( is => 'lazy', isa => CodeRef );
sub _build_error_cb {
    sub {
        croak shift;
    }
}

sub _api_exec {
    my $resp_cb = $#_ % 2 == 1 && ref $_[$#_] eq 'CODE' ? pop @_ : sub { pop @_ };
    my ($self, $path, $method, %args) = @_;

    my @r;
    my $cli_cb = delete $args{cb} || sub { @r = @_ };
    my $error_cb = delete $args{error_cb} || $self->error_cb;

    $self->request_cb->($self, $self->_prep_request($path, $method, %args, sub {
        my ($resp) = @_;

        my $valid_cb = $args{_valid_cb} || sub { int($resp->status/100) == 2 };

        unless ($valid_cb->($resp->status)) {
            my $content = $resp->content || "[no content]";
            $error_cb->(sprintf("%s %s: %s", $resp->status, $resp->reason, $content));
            return;
        }

        my ($data, $meta) = $self->_prep_response(@_);
        $cli_cb->($resp_cb->($data), $meta);
    }));

    return wantarray ? @r : shift @r;
};

with qw(
    Consul::API::ACL
    Consul::API::Agent
    Consul::API::Catalog
    Consul::API::Event
    Consul::API::Health
    Consul::API::KV
    Consul::API::Session
    Consul::API::Status
);

use Consul::Check;
use Consul::Service;
use Consul::Session;


package
    Consul::Request; # hide from PAUSE

use Moo;
use Types::Standard qw(Str CodeRef HashRef);
use Type::Utils qw(class_type);

has method   => ( is => 'ro', isa => Str,                            required => 1 );
has url      => ( is => 'ro', isa => Str,                            required => 1 );
has headers  => ( is => 'ro', isa => class_type('Hash::MultiValue'), required => 1 );
has content  => ( is => 'ro', isa => Str,                            required => 1 );
has callback => ( is => 'ro', isa => CodeRef,                        required => 1 );
has args     => ( is => 'ro', isa => HashRef,                        required => 1 );


package
    Consul::Response; # hide from PAUSE

use Moo;
use Types::Standard qw(Str Int);
use Type::Utils qw(class_type);

has status   => ( is => 'ro', isa => Int,                            required => 1 );
has reason   => ( is => 'ro', isa => Str,                            required => 1 );
has headers  => ( is => 'ro', isa => class_type('Hash::MultiValue'), default  => sub { Hash::MultiValue->new } );
has content  => ( is => 'ro', isa => Str,                            default  => sub { "" } );
has request  => ( is => 'ro', isa => class_type('Consul::Request'),  required => 1 );


package
    Consul::Meta; # hide from PAUSE

use Moo;
use Types::Standard qw(Int Bool);

has index        => ( is => 'ro', isa => Int,  init_arg => 'x-consul-index',       required => 1 );
has last_contact => ( is => 'ro', isa => Int,  init_arg => 'x-consul-lastcontact' );
has known_leader => ( is => 'ro', isa => Bool, init_arg => 'x-consul-knownleader', coerce => sub { my $r = { true => 1, false => 0 }->{$_[0]}; defined $r ? $r : $_[0] } );


1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/Consul.png)](http://travis-ci.org/robn/Consul)

=head1 NAME

Consul - Client library for consul

=head1 SYNOPSIS

    use Consul;
    
    my $consul = Consul->new;
    say $consul->status->leader;
    
    # shortcut to single API
    my $status = Consul->status;
    say $status->leader;

=head1 DESCRIPTION

This is a client library for accessing and manipulating data in a Consul
cluster. It targets the Consul v1 HTTP API.

This module is quite low-level. You're expected to have a good understanding of
Consul and its API to understand the methods this module provides. See L</SEE ALSO>
for further reading.

=head1 WARNING

This is still under development. The documentation isn't all there yet (in
particular about the return types) and a couple of APIs aren't implemented.
It's still very useful and I don't expect huge changes, but please take care
when upgrading. Open an issue if there's something you need that isn't here and
I'll get right on it!

=head1 CONSTRUCTOR

=head2 new

    my $consul = Consul->new( %args );

This constructor returns a new Consul client object. Valid arguments include:

=over 4

=item *

C<host>

Hostname or IP address of an Consul server (default: C<127.0.0.1>)

=item *

C<port>

Port where the Consul server is listening (default: C<8500>)

=item *

C<ssl>

Use SSL/TLS (ie HTTPS) when talking to the Consul server (default: off)

=item *

C<timeout>

Request timeout. If a request to Consul takes longer that this, the endpoint
method will fail (default: 15).

=item *

C<token>

Consul ACL token.  This is used to set the C<X-Consul-Token> HTTP header.  Typically
Consul agents are pre-configured with a default ACL token, or ACLs are not enabled
at all, so this option only needs to be set in certain cases.

=item *

C<request_cb>

A callback to an alternative method to make the actual HTTP request. The
callback is of the form:

    sub {
        my ($self, $req) = @_;
        ... do HTTP call
        $req->callback->(Consul::Response->new(...));
    }

C<$req> is a C<Consul::Request> object, and has the following attributes:

=over 4

=item *

C<method>

The HTTP method for the request.

=item *

C<url>

The complete URL to request. This is fully formed, and includes scheme, host,
port and query parameters. You shouldn't need to touch it.

=item *

C<headers>

A L<Hash::MultiValue> object containing any headers that should be added to the
request.

=item *

C<content>

The body content for the request.

=item *

C<callback>

A callback to call when the request is completed. It takes a single
C<Consul::Response> object as its parameter.

=item *

C<args>

A hashref containing the original arguments passed in to the endpoint method.

=back

The C<callback> function should be called with a C<Consul::Response> object
containing the values returned by the Consul server in response to the request.
Create one with C<new>, passing the following attributes:

=over 4

=item *

C<status>

The integer status code.

=item *

C<reason>

The status reason phrase.

=item *

C<headers>

A L<Hash::MultiValue> containing the response headers.

=item *

C<content>

Any body content returned in the response.

=item *

C<request>

The C<Consul::Request> object passed to the callback.

=back

Consul itself provides a default C<request_cb> that uses L<HTTP::Tiny> to make
calls to the server. If you provide one, you should honour the value of the
C<timeout> argument.

C<request_cb> can be used in conjunction with the C<cb> option to all API method
endpoints to get asynchronous behaviour. It's recommended however that you
don't use this directly, but rather use a module like L<AnyEvent::Consul> to
take care of that for you.

If you just want to use this module to make simple calls to your Consul
cluster, you can ignore this option entirely.

=item *

C<error_cb>

A callback to an alternative method to handle internal errors (usually HTTP
errors). The callback is of the form:

    sub {
        my ($err) = @_;
        ... output $err ...
    }

The default callback simply calls C<croak>.

=back

=head1 ENDPOINTS

Individual API endpoints are implemented in separate modules. The following
methods will return a context objects for the named API. Alternatively, you can
request an API context directly from the Consul package. In that case,
C<Consul-E<gt>new> is called implicitly.

    # these are equivalent
    my $agent = Consul->new( %args )->agent;
    my $agent = Consul->agent( %args );

=head2 kv

Key/value store API. See L<Consul::API::KV>.

=head2 agent

Agent API. See L<Consul::API::Agent>.

=head2 catalog

Catalog (nodes and services) API. See L<Consul::API::Catalog>.

=head2 health

Health check API. See L<Consul::API::Health>.

=head2 session

Sessions API. See L<Consul::API::Session>.

=head2 acl

Access control API. See L<Consul::API::ACL>.

=head2 event

User event API. See L<Consul::API::Event>.

=head2 status

System status API. See L<Consul::API::Status>.

=head1 METHOD OPTIONS

All API methods implemented by the endpoints can take a number of arguments.
Most of those are documented in the endpoint documentation. There are however
some that are common to all methods:

=over 4

=item *

C<cb>

A callback to call with the results of the method. Without this, the results
are returned from the method, but only if C<request_cb> is synchronous. If an
asynchronous C<request_cb> is used without a C<cb> being passed to the method, the
method return value is undefined.

If you just want to use this module to make simple calls to your Consul
cluster, you can ignore this option entirely.

C<error_cb>

A callback to an alternative method to handle internal errors (usually HTTP
errors).  errors). The callback is of the form:

    sub {
        my ($err) = @_;
        ... output $err ...
    }

The default callback calls the C<error_cb> for the API object itself, which by
default, simply calls croak.

=back

=head1 BLOCKING QUERIES

Some Consul API endpoints support a feature called a "blocking query". These
endpoints allow long-polling for changes, and support some extra information
about the server state, including the Raft index, in the response headers.

The corresponding endpoint methods, when called in array context, will return a
second value. This is an object with three methods, C<index>, C<last_contact>
and C<known_leader>, corresponding to the similarly-named header fields. You
can use these to set up state watches, CAS writes, and so on.

See the Consul API docs for more information.

=head1 SEE ALSO

=over 4

=item *

L<AnyEvent::Consul> - a wrapper providing asynchronous operation

=item *

L<https://www.consul.io/docs/agent/http.html> - Consul HTTP API documentation

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/Consul/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/Consul>

  git clone https://github.com/robn/Consul.git

=head1 CONTRIBUTORS

=over 4

=item *

Rob N ★ <robn@robn.io>

=item *

Aran Deltac <bluefeet@gmail.com>

=item *

Michael McClimon

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Rob N ★.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
