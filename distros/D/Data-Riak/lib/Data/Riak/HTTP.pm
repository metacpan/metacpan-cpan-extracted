package Data::Riak::HTTP;
{
  $Data::Riak::HTTP::VERSION = '2.0';
}
# ABSTRACT: An interface to a Riak server, using its HTTP (REST) interface

use strict;
use warnings;

use Moose;
use Carp 'cluck';

use LWP::UserAgent;
use LWP::ConnCache;
use HTTP::Headers;
use HTTP::Response;
use HTTP::Request;

use Data::Riak::HTTP::Request;
use Data::Riak::HTTP::Response;
use Data::Riak::HTTP::ExceptionHandler::Default;

use namespace::autoclean;


{
    my ($warned_host_env, $warned_host_default);

    has host => (
        is      => 'ro',
        isa     => 'Str',
        default => sub {
            if (exists $ENV{DATA_RIAK_HTTP_HOST}) {
                cluck 'Environment variable DATA_RIAK_HTTP_HOST is deprecated'
                    unless $warned_host_env;

                return $ENV{DATA_RIAK_HTTP_HOST};
            }

            cluck 'host defaulting to localhost is deprecated'
                unless $warned_host_default;

            return '127.0.0.1';
        }
    );
}


{
    my ($warned_port_env, $warned_port_default);

    has port => (
        is      => 'ro',
        isa     => 'Int',
        default => sub {
            if (exists $ENV{DATA_RIAK_HTTP_PORT}) {
                cluck 'Environment variable DATA_RIAK_HTTP_PORT is deprecated'
                    unless $warned_port_env;

                return $ENV{DATA_RIAK_HTTP_PORT};
            }

            cluck 'port defaulting to 8098 is deprecated'
                unless $warned_port_default;

            return '8098';
        }
    );
}


{
    my $warned_timeout_env;

    has timeout => (
        is => 'ro',
        isa => 'Int',
        default => sub {
            if (exists $ENV{DATA_RIAK_HTTP_TIMEOUT}) {
                cluck 'Environment variable DATA_RIAK_HTTP_TIMEOUT is deprecated'
                    unless $warned_timeout_env;

                return $ENV{DATA_RIAK_HTTP_TIMEOUT};
            }

            return '15';
        }
    );
};


our $CONN_CACHE;

has user_agent => (
    is => 'ro',
    isa => 'LWP::UserAgent',
    lazy => 1,
    default => sub {
        my $self = shift;

        # NOTE:
        # Much of the following was copied from
        # Net::Riak (franck cuny++ && robin edwards++)
        # - SL

        # The Links header Riak returns (esp. for buckets) can get really long,
        # so disable limits LWP puts on the length of response lines
        # (default = 8192)
        my %opts = @LWP::Protocol::http::EXTRA_SOCK_OPTS;
        $opts{MaxLineLength} = 0;
        @LWP::Protocol::http::EXTRA_SOCK_OPTS = %opts;

        my $ua = LWP::UserAgent->new(
            timeout => $self->timeout,
            keep_alive => 1,
        );

        $CONN_CACHE ||= LWP::ConnCache->new;

        $ua->conn_cache( $CONN_CACHE );

        $ua;
    }
);


sub send {
    my ($self, $request) = @_;

    my $http_request = $self->create_request($request);
    my $http_response = $self->_send($http_request);

    $self->exception_handler->try_handle_exception(
        $request, $http_request, $http_response,
    );

    return $http_response;
}

sub _send {
    my ($self, $request) = @_;

    my $uri = URI->new( sprintf('%s%s', $self->base_uri, $request->uri) );

    if ($request->has_query) {
        $uri->query_form($request->query);
    }

    my $headers = HTTP::Headers->new(
        'X-Riak-ClientId' => $self->client_id,
        ($request->method eq 'GET' ? ('Accept' => $request->accept) : ()),
        ($request->method eq 'POST' || $request->method eq 'PUT' ? ('Content-Type' => $request->content_type) : ()),
        %{ $request->headers },
    );

    if(my $links = $request->links) {
        $headers->header('Link' => $request->links);
    }

    if(my $indexes = $request->indexes) {
        foreach my $index (@{$indexes}) {
            my $field = $index->{field};
            my $values = $index->{values};
            $headers->header(":X-Riak-Index-$field" => $values);
        }
    }

    my $http_request = HTTP::Request->new(
        $request->method => $uri->as_string,
        $headers,
        $request->data
    );

    my $http_response = $self->user_agent->request($http_request);

    my $response = Data::Riak::HTTP::Response->new({
        http_response => $http_response
    });

    return $response;
}

with 'Data::Riak::Transport::HTTP';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::HTTP - An interface to a Riak server, using its HTTP (REST) interface

=head1 VERSION

version 2.0

=head1 ATTRIBUTES

=head2 host

The host the Riak server is on. Can be set via the environment variable
DATA_RIAK_HTTP_HOST, and defaults to 127.0.0.1.

=head2 port

The port of the host that the riak server is on. Can be set via the environment
variable DATA_RIAK_HTTP_PORT, and defaults to 8098.

=head2 timeout

The maximum value (in seconds) that a request can go before timing out. Can be set
via the environment variable DATA_RIAK_HTTP_TIMEOUT, and defaults to 15.

=head2 user_agent

This is the instance of L<LWP::UserAgent> we use to talk to Riak.

=head2 base_uri

The base URI for the Riak server.

=head1 METHODS

=head2 send ($request)

Send a Data::Riak::HTTP::Request to the server.

=head1 ACKNOWLEDGEMENTS

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
