package Ambassador::API::V2;

use Moo;
use v5.10;

with 'Ambassador::API::V2::Role::HasJSON';
use HTTP::Tiny;
use URI;
use Ambassador::API::V2::Error;
use Ambassador::API::V2::Result;

our $VERSION = '0.001';

has username => (
    is       => 'ro',
    required => 1
);

has key => (
    is       => 'ro',
    required => 1
);

has url => (
    is     => 'ro',
    coerce => sub {
        return URI->new($_[0]);
    },
    default => sub { 'https://getambassador.com/api/v2/' }
);

# Configure and cache the HTTP::Tiny object
has http => (
    is      => 'ro',
    default => sub {
        return HTTP::Tiny->new(
            agent           => "Ambassador-API-V2/$VERSION",
            default_headers => {'Content-Type' => 'application/json'}
        );
    }
);

sub _make_url {
    my $self   = shift;
    my $method = shift;

    my $url = $self->url->clone;

    # Ambassador is very sensitive to double slashes.
    my $path = $url->path . join '/', $self->username, $self->key, 'json', $method;
    $path =~ s{/{2,}}{/}g;

    $url->path($path);

    return $url;
}

sub _handle_response {
    my $self = shift;
    my ($response) = @_;

    die Ambassador::API::V2::Error->new_from_response($response) if !$response->{success};

    return Ambassador::API::V2::Result->new_from_response($response);
}

sub _request {
    my $self = shift;
    my ($type, $method, $args) = @_;

    my $url = $self->_make_url($method);

    my $opts = {};
    $opts->{content} = $self->json->encode($args) if $args;
    my $response = $self->http->request(uc $type, $url, $opts);

    return $self->_handle_response($response);
}

sub post {
    my $self = shift;
    return $self->_request('POST', @_);
}

sub get {
    my $self = shift;
    return $self->_request('GET', @_);
}

1;

__END__

=head1 NAME

Ambassador::API::V2 - Speak with the getambassador.com API v2

=head1 SYNOPSIS

    use Ambassador::API::V2;

    my $api = Ambassador::API::V2->new(
        username => $app_username,
        key      => $app_key
    );

    my $result = $api->post(
        '/event/record/' => {
            email        => 'fake@fakeity.fake',
            campaign_uid => 1234
        }
    );

    my $result = $api->get(
        '/shortcode/get/' => {
            short_code => $mbsy,
        }
    );

=head1 DESCRIPTION

Speak with the L<getambassador.com> API version 2. See
L<https://docs.getambassador.com>.


=head1 CONSTRUCTOR

    my $api = Ambassador::API::V2->new(
        username => $app_username,
        key      => $app_key
    );

=over 4

=item key

The key for your app. C<YOUR_APP_KEY> in the API docs.

=item username

The username for your app. C<YOUR_APP_USERNAME> in the API docs.

=item url

The URL to call.

Defaults to L<https://getambassador.com/api/v2/>

=back

=head1 METHODS

=over 4

=item $api->post($method, \%args);

=item $api->get($method, \%args);

    my $response = $api->post($method, \%args);
    my $response = $api->get($method, \%args);

Call an Ambassador API C<$method> with the given C<%args>.

If successful, it returns an L<Ambassdor::API::V2::Response>.
If it fails, it will throw an L<Ambassador::API::V2::Error>.

See the L<Ambassador API docs|https://docs.getambassador.com/docs/>
for what $methods are available, what C<%args> they take, and which
should be called with C<get> or C<post>.

=back

=head1 SOURCE

The source code repository for Ambassador-API-V2 can be found at
F<https://github.com/dreamhost/Ambassador-API-V2>.

=head1 COPYRIGHT

Copyright 2016 Dreamhost E<lt>dev-notify@hq.newdream.netE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
