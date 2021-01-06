package # private package
    t::api::Test;

use Moo;

with 'DNS::Hetzner::API';

our $VERSION = 0.02;

has token    => ( is => 'ro', default => sub { 'abscdjask' } );
has host     => ( is => 'ro', default => sub { 'https://dns.hetzner.com' } );
has base_uri => ( is => 'ro', default => sub { 'api/v1' } );
has client   => ( is => 'ro', default => sub { 'Test' } );

__PACKAGE__->load_namespace;

1;
