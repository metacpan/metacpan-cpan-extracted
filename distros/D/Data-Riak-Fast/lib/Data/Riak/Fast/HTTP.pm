package Data::Riak::Fast::HTTP;
# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface

use Mouse;

use Furl;
use Net::DNS::Lite;
use Cache::LRU;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;

use Data::Riak::Fast;
use Data::Riak::Fast::HTTP::Request;
use Data::Riak::Fast::HTTP::Response;

=head2 host

The host the Riak server is on. Can be set via the environment variable
DATA_RIAK_HTTP_HOST, and defaults to 127.0.0.1.

=cut

has host => (
    is => 'ro',
    isa => 'Str',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_HOST'} || '127.0.0.1';
    }
);

=head2 port

The port of the host that the riak server is on. Can be set via the environment
variable DATA_RIAK_HTTP_PORT, and defaults to 8098.

=cut

has port => (
    is => 'ro',
    isa => 'Int',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_PORT'} || '8098';
    }
);

=head2 timeout

The maximum value (in seconds) that a request can go before timing out. Can be set
via the environment variable DATA_RIAK_HTTP_TIMEOUT, and defaults to 15.

=cut

has timeout => (
    is => 'ro',
    isa => 'Num',
    default => sub {
        $ENV{'DATA_RIAK_HTTP_TIMEOUT'} || '15';
    }
);

=head2 user_agent

This is the instance of L<LWP::UserAgent> we use to talk to Riak.

=cut

=head1 METHOD
=head2 base_uri

The base URI for the Riak server.

=cut

sub base_uri {
    my $self = shift;
    return sprintf('http://%s:%s/', $self->host, $self->port);
}

=head2 ping

Tests to see if the specified Riak server is answering. Returns 0 for no, 1 for yes.

=cut

sub ping {
    my $self = shift;
    my ($response,) = $self->send({ method => 'GET', uri => 'ping' });
    return 0 unless($response->code eq '200');
    return 1;
}

=head2 send ($request)

Send a Data::Riak::Fast::HTTP::Request to the server. If you pass in a hashref, it will
create the Request object for you on the fly.

=cut

sub send {
    my ($self, $request) = @_;
    unless(blessed $request) {
        $request = Data::Riak::Fast::HTTP::Request->new($request);
    }
    my ($response, $url) = $self->_send($request);
    return $response, $url;
}

sub _send {
    my ($self, $request) = @_;

    my $uri = URI->new( sprintf('%s%s', $self->base_uri, $request->uri) );

    if ($request->has_query) {
        $uri->query_form($request->query);
    }

    my @headers;
    push @headers, 'Accept' => $request->accept if $request->method eq 'GET';
    push @headers, 'Content-Type' => $request->content_type if $request->method =~ /^(POST|PUT)$/;
    if(my $links = $request->links) {
        push @headers, 'Link' => $request->links;
    }

    if(my $indexes = $request->indexes) {
        foreach my $index (@{$indexes}) {
            my $field = $index->{field};
            my $values = $index->{values};
            push @headers, ":X-Riak-Index-$field" => $values;
        }
    }

    $Net::DNS::Lite::CACHE = Cache::LRU->new(
        size => 256,
    );

    my $furl = Furl::HTTP->new(
        agent   => "Data::Riak::Fast/$Data::Riak::Fast::VERSION",
        timeout => $self->timeout,
        inet_aton => \&Net::DNS::Lite::inet_aton,
    );
    my ( $mv, $code, $msg, $headers, $content ) = $furl->request(
        method  => $request->method,
        url     => $uri->as_string,
        headers => \@headers,
        content => $request->data,
    );
    my $http_response = HTTP::Response->new($code, $msg, $headers, $content);

    my $response = Data::Riak::Fast::HTTP::Response->new({
        http_response => $http_response
    });

    return $response, $uri;
}

=begin :postlude

=head1 ACKNOWLEDGEMENTS


=end :postlude

=cut

__PACKAGE__->meta->make_immutable;
no Mouse;

1;
