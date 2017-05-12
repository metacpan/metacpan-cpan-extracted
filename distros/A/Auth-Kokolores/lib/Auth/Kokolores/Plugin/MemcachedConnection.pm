package Auth::Kokolores::Plugin::MemcachedConnection;

use Moose;
use Cache::Memcached;

# ABSTRACT: kokolores plugin to configure a memcached connection
our $VERSION = '1.01'; # VERSION

extends 'Auth::Kokolores::Plugin';

use Auth::Kokolores::ConnectionPool;


has 'servers' => ( is => 'ro', isa => 'Str', default => '127.0.0.1:11211');
has 'namespace' => ( is => 'ro', isa => 'Str', default => 'auth-');
has 'handle' => ( is => 'rw', isa => 'Str', default => 'memcached' );

has _servers => (
  is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
  default => sub {
    return [ split( /\s*,\s*/, shift->servers ) ]; 
  },
);

has 'memcached' => (
  is => 'ro', isa => 'Cache::Memcached',
  lazy => 1,
  default => sub {
    my $self = shift;
    $self->log(3, 'creating memcached connection to '.join(', ', @{$self->_servers}).'...');
    return Cache::Memcached->new( {
      'servers' => $self->_servers,
      'debug' => 0,
      'namespace' => $self->namespace,
    } );
  },
);

sub child_init {
  my ( $self, $r ) = @_;
  
  $self->log(3, 'registring memcached connection \''.$self->handle.'\'...');
  Auth::Kokolores::ConnectionPool->add_handle(
    $self->handle => $self->memcached,
  );

  return;
}

sub shutdown {
  my ( $self, $r ) = @_;
  
  $self->log(3, 'unregistring memcached connection \''.$self->handle.'\'...');
  Auth::Kokolores::ConnectionPool->clear_handle( $self->handle );

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Auth::Kokolores::Plugin::MemcachedConnection - kokolores plugin to configure a memcached connection

=head1 VERSION

version 1.01

=head1 DESCRIPTION

This plugin creates a connection to an memcached server for use
by further plugins.

=head1 EXAMPLE

  <Plugin memcache>
    module = "MemcachedConnection"
    servers = "127.0.0.1:11211"
    namespace = "auth-"
  </Plugin>

=head1 MODULE PARAMETERS

=head2 servers (default: '127.0.0.1:112211')

A comma seperated list of servers.

=head2 namespace (default: 'auth-')

A prefix to use for keys.

=head2 handle (default: 'memcached')

This string is used to register the memcached connection
within the kokolores connection pool.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
