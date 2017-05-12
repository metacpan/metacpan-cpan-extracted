package Data::Riak::Async::HTTP;
{
  $Data::Riak::Async::HTTP::VERSION = '2.0';
}

use Moose;
use AnyEvent::HTTP;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Response;
use Data::Riak::HTTP::Request;
use Data::Riak::HTTP::Response;
use Data::Riak::HTTP::ExceptionHandler::Default;
use namespace::autoclean;

has host => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has port => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);

has timeout => (
    is      => 'ro',
    isa     => 'Int',
    default => 15,
);

has request_arguments => (
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { +{} },
    handles => {
        request_arguments => 'elements',
    },
);

sub send {
    my ($self, $request, $cb, $error_cb) = @_;

    my $http_request = $self->create_request($request);

    $self->_send($http_request, sub {
        my ($http_response) = @_;

        my $e = $self->exception_handler->try_build_exception(
            $request, $http_request, $http_response,
        );
        return $error_cb->($e) if $e;

        $cb->($http_response);
    }, $error_cb);

    return;
}

sub _send {
    my ($self, $request, $cb, $error_cb) = @_;

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
        $request->data,
    );

    $self->_send_via_anyevent_http($http_request, $cb, $error_cb);
}

sub _send_via_anyevent_http {
    my ($self, $http_request, $cb, $error_cb) = @_;

    my %plain_headers = (
        (map {
            (my $normalised = $_) =~ s/^://;
            # In scalar context ->header will join multiple values for a field
            # together with a comma and do the appropriate escaping.
            ($normalised => scalar $http_request->headers->header($_));
        } $http_request->headers->header_field_names),
        Referer => undef,
    );

    http_request $http_request->method, $http_request->uri,
        $self->request_arguments,
        timeout => $self->timeout,
        headers => \%plain_headers,
        body    => $http_request->content,
        sub {
            my ($body, $hdr) = @_;

            my $http_response = HTTP::Response->new(
                delete $hdr->{Status}, delete $hdr->{Reason},
                HTTP::Headers->new(%{ $hdr }), $body,
            );
            $http_response->request($http_request);

            my $response = Data::Riak::HTTP::Response->new({
                http_response => $http_response
            });

            $cb->($response);
        };

    return;
}

with 'Data::Riak::Transport::HTTP';

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Async::HTTP

=head1 VERSION

version 2.0

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
