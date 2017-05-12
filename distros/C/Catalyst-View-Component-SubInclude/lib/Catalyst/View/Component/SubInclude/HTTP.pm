package Catalyst::View::Component::SubInclude::HTTP;

use Moose;
use namespace::clean -except => 'meta';
use Moose::Util::TypeConstraints;
use LWP::UserAgent;
use List::MoreUtils 'firstval';
use URI;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

has http_method => (
    isa => 'Str', is => 'ro', default => 'GET',
);

has ua_timeout => (
    isa => 'Int', is => 'ro', default => 10,
);

has base_url => (
    isa => 'Str', is => 'ro', required => 0,
);

has uri_map => (
    isa => 'HashRef', is => 'ro', required => 0,
);

has user_agent => (
    isa => duck_type([qw/get post/]), is => 'ro',
    lazy => 1, builder => '_build_user_agent',
);

sub _build_user_agent {
    my $self = shift;
    return LWP::UserAgent->new(
        agent => ref($self),
        timeout => $self->ua_timeout,
    );
}

sub generate_subinclude {
    my ($self, $c, $path, $args) = @_;
    my $error_msg_prefix = "SubInclude for $path failed: ";
    my $base_url = $self->base_url || $c->req->base;
    my $uri_map = $self->uri_map || { q{/} => $base_url };
    $base_url = $uri_map->{ firstval { $path =~ s/^$_// } keys %$uri_map };
    $base_url =~ s{/$}{};
    my $uri = URI->new(join(q{/}, $base_url, $path));
    my $req_method = q{_} . lc $self->http_method . '_request';

    my $response;
    if ( $self->can($req_method) ) {
        $response = $self->$req_method($uri, $args);
    }
    else {
        confess $self->http_method . ' not supported';
    }
    if ($response->is_success) {
        return $response->content;
    }
    else {
        $c->log->info($error_msg_prefix . $response->status_line);
        return undef;
    }
}

sub _get_request {
    my ( $self, $uri, $args) = @_;
    $uri->query_form($args);
    return $self->user_agent->get($uri);
}

sub _post_request {
    my ( $self, $uri, $args ) = @_;
    return $self->user_agent->post($uri, $args);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Catalyst::View::Component::SubInclude::HTTP - HTTP plugin for C::V::Component::SubInclude

=head1 SYNOPSIS

In your view class:

    package MyApp::View::TT;
    use Moose;

    extends 'Catalyst::View::TT';
    with 'Catalyst::View::Component::SubInclude';

    __PACKAGE__->config(
        subinclude_plugin => 'HTTP::GET',
        subinclude => {
            'HTTP::GET' => {
                class => 'HTTP',
                http_method => 'GET',
                ua_timeout => '10',
                uri_map => {
                    '/my/' => 'http://localhost:5000/',
                },
            },
            'HTTP::POST' => {
                class => 'HTTP',
                http_method => 'POST',
                ua_timeout => '10',
                uri_map => {
                    '/foo/' => 'http://www.foo.com/',
                },
            },
        },
    );

Then, somewhere in your templates:

    [% subinclude('/my/widget') %]
    ...
    [% subinclude_using('HTTP::POST', '/foo/path', { foo => 1 }) %]

=head1 DESCRIPTION

C<Catalyst::View::Component::SubInclude::HTTP> does HTTP requests (currently
using L<LWP::UserAgent>) and uses the responses to render subinclude contents.

=head1 CONFIGURATION

The configuration is passed in the C<subinclude> key based on your plugin name
which can be arbitrary.

=over

=item class

Required just in case your plugin name differs from C<HTTP>.

=item http_method

Accepts C<GET> and C<POST> as values. The default one is C<GET>.

=item user_agent

This lazily builds a L<LWP::UserAgent> obj, however you can pass a different
user agent obj that implements the required API.

=item ua_timeout

User Agent's timeout config param. Defaults to 10 seconds.

=item uri_map

This expects a HashRef in order to map paths to different URLs.

=item base_url

Used only if C<uri_map> is C<undef> and defaults to C<< $c->request->base >>.

=back

=head1 METHODS

=head2 C<generate_subinclude( $c, $path, $args )>

Note that C<$path> should be the relative path.

=head1 SEE ALSO

L<Catalyst::View::Component::SubInclude|Catalyst::View::Component::SubInclude>

=head1 AUTHOR

Wallace Reis C<< <wreis@cpan.org> >>

=head1 SPONSORSHIP

Development sponsored by Ionzero LLC L<http://www.ionzero.com/>.

=head1 COPYRIGHT & LICENSE

Copyright (c) 2010 Wallace Reis.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
