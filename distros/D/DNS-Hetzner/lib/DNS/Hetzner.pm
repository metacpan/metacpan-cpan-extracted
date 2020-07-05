package DNS::Hetzner;

use v5.20;

# ABSTRACT: Perl library to work with the API for the Hetzner DNS

use Moo;
use Mojo::UserAgent;

use Carp;
use Types::Mojo qw(:all);

use Mojo::Base -strict, -signatures;

with 'DNS::Hetzner::API';

use feature 'postderef';
no warnings 'experimental::postderef';

our $VERSION = 0.01;

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

__PACKAGE__->load_namespace;

sub request ( $self, $partial_uri, $opts, $params = {} ) {

    my $method = delete $opts->{type} // 'get';
    my $sub    = $self->client->can(lc $method);

    if ( !$sub ) {
        croak sprintf 'Invalid request method %s', $method;
    }

    $partial_uri =~ s{:(?<mandatory>\w+)\b}{ delete $params->{$+{mandatory}} }xmsge;

    my %request_opts;
    if ( $params->%* ) {
        %request_opts = ( json => $params );
    }

    $opts->{query} //= {};
    my $query = '';
    if ( $opts->{query}->%* ) {
        my $query_params = delete $opts->{query};

        $query = join '&', map{ 
            $_ . '=' . uri_escape($query_params->{$_}) 
        }sort keys $query_params->%*;
    }

    $partial_uri .= '?' . $query if $query;

    my $uri = join '/', 
        $self->host, 
        $self->base_uri,
        $self->endpoint,
        $partial_uri;

    $uri =~ s{/\z}{};

    my $tx = $self->client->$method(
        $uri,
        {
            'Auth-API-Token' => $self->token,
        },
        %request_opts,
    );

    my $response = $tx->res;

    say STDERR $tx->req->to_string if $ENV{DNS_HETZNER_DEBUG};
    say STDERR $tx->res->to_string if $ENV{DNS_HETZNER_DEBUG};

    return if $response->is_error;
    return $response->json;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner - Perl library to work with the API for the Hetzner DNS

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use DNS::Hetzner;

    my $cloud = DNS::Hetzner->new(
        token => 'ABCDEFG1234567',    # your api token
    );

    my $server_client = $cloud->server;
    my $server_list   = $server_client->list;

=head1 INFO

This is still pretty alpha. The API might change.

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
