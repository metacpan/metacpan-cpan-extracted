package Auth::Kokolores::Plugin::CacheMemcached;

use Moose;

# ABSTRACT: a memcached based cache for kokolores
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

use Auth::Kokolores::ConnectionPool;


has 'handle' => ( is => 'rw', isa => 'Str', default => 'memcached' );
has 'ttl' => ( is => 'rw', isa => 'Int', default => 300 );

has 'cache_negative' => ( is => 'rw', isa => 'Bool', default => 0 );
has 'ttl_negative' => ( is => 'rw', isa => 'Int', lazy => 1,
  default => sub { shift->ttl; }
);

has 'memcached' => (
  is => 'ro', isa => 'Cache::Memcached',
  lazy => 1,
  default => sub {
    my $self = shift;
    return Auth::Kokolores::ConnectionPool->get_handle(
      $self->handle,
    );
  },
);

sub pre_process {
  my ( $self, $r ) = @_;
  my $cache = $self->memcached->get( $r->fingerprint );
  if( defined $cache ) {
    $r->log(4, 'found cached entry for '.$r->fingerprint);
    return $cache;
  }
  $r->log(4, 'cache miss for '.$r->fingerprint);
  return;
}

sub post_process {
  my ( $self, $r, $response ) = @_;
  if( $response->success || $self->cache_negative ) {
    my $ttl = $response->success ? $self->ttl : $self->ttl_negative;
    $r->log(4, 'adding to cache '.$r->fingerprint.' (ttl '.$ttl.')');
    $self->memcached->set( $r->fingerprint, $response, $ttl );
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::CacheMemcached - a memcached based cache for kokolores

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This plugin caches authentication requests in memcached.

=head1 USAGE

  <Plugin memcache>
    module = "MemcachedConnection"
    servers = "127.0.0.1:11211"
    namespace = "auth-"
  </Plugin>

  <Plugin auth-cache>
    module="CacheMemcached"
    ttl="300"
  </Plugin>

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
