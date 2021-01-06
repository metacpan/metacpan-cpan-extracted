package DNS::Hetzner::APIBase;

# ABSTRACT: Base class for all entity classes

use v5.24;

use Carp;
use Data::Printer;
use Moo;
use Mojo::UserAgent;
use Mojo::Util qw(url_escape);
use Types::Mojo qw(:all);

use DNS::Hetzner::Schema;

use Mojo::Base -strict, -signatures;

our $VERSION = '0.02';

has token    => ( is => 'ro', isa => Str, required => 1 );
has host     => ( is => 'ro', isa => MojoURL["https?"], default => sub { 'https://dns.hetzner.com' }, coerce => 1 );
has base_uri => ( is => 'ro', isa => Str, default => sub { 'api/v1' } );

has client   => (
    is      => 'ro',
    lazy    => 1,
    isa     => MojoUserAgent,
    default => sub {
        Mojo::UserAgent->new,
    }
);

sub _do ( $self, $op, $params, $path, $opts ) {
    my ($req_params, @errors) = DNS::Hetzner::Schema->validate( $op, $params );

    croak 'invalid parameters' if @errors;

    $self->request( $path, $req_params, $opts );
}

sub request ( $self, $partial_uri, $params = {}, $opts = {} ) {

    my $method = delete $opts->{type} // 'get';
    my $sub    = $self->client->can(lc $method);

    croak sprintf 'Invalid request method %s', $method if !$sub;

    $params->{path} //= {};
    my %path_params = $params->{path}->%*;

    $partial_uri =~ s{
        :(?<mandatory>\w+)\b
    }{
        $path_params{$+{mandatory}}
    }xmsge;

    my %request_opts;
    $params->{body} //= {};
    if ( $params->{body}->%* ) {
        %request_opts = ( json => $params->{body} );
    }

    $params->{query} //= {};
    my $query = '';
    if ( $params->{query}->%* ) {
        my $query_params = delete $params->{query};

        $query = join '&', map{
            $_ . '=' . url_escape($query_params->{$_})
        }sort keys $query_params->%*;
    }

    my $uri = join '/',
        $self->host,
        $self->base_uri,
        $self->endpoint,
        $partial_uri;

    $uri =~ s{/\z}{};

    $uri .= '?' . $query if $query;

    my $tx = $self->client->$method(
        $uri,
        {
            'Auth-API-Token' => $self->token,
        },
        %request_opts,
    );

    my $response = $tx->res;

    if ( $tx->error ) {
        carp np $tx->error;
        return;
    }

    return $response->json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner::APIBase - Base class for all entity classes

=head1 VERSION

version 0.02

=head1 ATTRIBUTES

=over 4

=item * base_uri

I<(optional)> Default: C<api/v1>

=item * client 

I<(optional)> A C<Mojo::UserAgent> compatible user agent. By default a new object of C<Mojo::UserAgent>
is created.

=item * host

I<(optional)> This is the URL to Hetzner's Cloud-API. Defaults to C<https://dns.hetzner.com>

=item * token

B<I<(required)>> Your API token.

=back

=head1 METHODS

=head2 request

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
