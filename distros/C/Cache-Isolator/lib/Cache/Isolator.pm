package Cache::Isolator;

use strict;
use warnings;
use Carp;
use Try::Tiny;
use Time::HiRes;
use List::Util qw/shuffle/;
use Class::Accessor::Lite (
    ro  => [ qw(cache interval timeout concurrency trial early_expires_ratio expires_before) ],
);

our $VERSION = '0.02';

sub new {
    my $class = shift;
    my %args = (
        interval => 0.01,
        timeout => 10,
        trial => 0,
        concurrency => 1,
        early_expires_ratio => 0,
        expires_before => 10,
        @_
    );

    croak('cache value should be object and appeared add, set and delete methods.')
      unless ( $args{cache}
        && UNIVERSAL::can( $args{cache}, 'get' )
        && UNIVERSAL::can( $args{cache}, 'set' )
        && UNIVERSAL::can( $args{cache}, 'add' )
        && UNIVERSAL::can( $args{cache}, 'delete' ) );

    bless \%args, $class;
}

sub get_or_set {
    my ($self, $key, $cb, $expires ) = @_;

    my $value;
    my $try = 0;

    TRYLOOP: while  ( 1 ) {
        $value = $self->get($key);
        last TRYLOOP if $value;

        $try++;
        my @lockkeys = map { $key .":lock:". $_ } shuffle 1..$self->concurrency;
        foreach my $lockkey ( @lockkeys ) {
            my $locked = $self->cache->add($lockkey, 1, $self->timeout ); #lock
            if ( $locked ) {
                try {
                    $value = $self->get($key);
                    return 1 if $value;
                    $value = $cb->();
                    $self->set( $key, $value, $expires );
                }
                catch {
                    die $_;
                }
                finally {
                    $self->cache->delete( $lockkey ); #lock
                };
                last TRYLOOP;
            }
        }
        die "reached max trial count" if $self->trial > 0 && $try >= $self->trial;
        Time::HiRes::sleep( $self->interval );
    }
    return $value;
}

sub set {
    my ($self, $key, $value, $expires) = @_;
    $self->cache->set($key, $value, $expires);
    if ( $self->early_expires_ratio > 0 ) {
        $expires = $expires - $self->expires_before;
        $expires = 1 if $expires <= 0;
        $self->cache->set($key . ":earlyexp", $value, $expires);
    }
}

sub get {
    my ($self, $key) = @_;
    if ( $self->early_expires_ratio > 0  &&
             int(rand($self->early_expires_ratio)) == 0 ) {
        return $self->cache->get($key.":earlyexp");
    }
    my $result = $self->cache->get($key);
    $result = $self->cache->get($key.":earlyexp") if ! defined $result;
    $result;
}

sub delete {
    my ($self, $key) = @_;
    $self->cache->delete($key.":earlyexp");
    $self->cache->delete($key);
}

1;
__END__

=head1 NAME

Cache::Isolator - transaction and concurrency manager of cache systems.

=head1 SYNOPSIS

  use Cache::Isolator;
  use Cache::Memcached::Fast;

  my $isolator = Cache::Isolator->new(
      cache => Cache::Memcached::Fast->new(...),
      concurrency => 4,
  );

  my $key   = 'query:XXXXXX';
  $isolator->get_or_set(
      $key, 
      sub { # This callback invoked when miss cache
          get_from_db($key);
      },
      3600
  );

=head1 DESCRIPTION

Cache::Isolator is transaction and concurrency manager of cache systems. 
Many cache systems have Thundering Herd problem. If a cache has expired, concentration of access to the database may happen. This will cause a system failure. Cache::Isolator can control the concentration of load.

=head1 METHODS

=head2 new( %args )

Following parameters are recognized.

=over

=item cache

B<Required>. L<Cache::Memcached::Fast> object or similar interface object.

=item concurrency

Optional. Number of get_or_set callback executed in parallel.
If many process need to run callback, they wait until lock becomes released or able to get values.
Defaults to 1. It means no concurrency. 

=item interval

Optional. The seconds for busy loop interval. Defaults to 0.01 seconds.

=item trial

Optional. When the value is being set zero, get_or_set will be waiting until lock becomes released.
When the value is being set positive integer value, get_or_set will die on reached trial count.
Defaults to 0.

=item timeout

Optional. The seconds until lock becomes released. Defaults to 30 seconds.

=item early_expires_ratio

Optional. if early_expires_ratio was set to greater than zero, Cache::Isolator stores to duplicate the cache. One of them is set to expire earlier than normal. Cache::Isolator gets the cache has been set to expire early in the specified percentage. This feature can prevent the cache from disappearing all together. Defaults is "0".

  my $cache = Cache::Isolator->new(
      early_expires_ratio => 10, # This means 1/10 ratio
  );

=item expires_before

Optional. Seconds earlier expiration. Defaults is 10.

=back

=head2 get_or_set( $key, $callback, $expires )

$callback is subroutine reference. That invoked when cache miss occurred.

=head2 get($key)

=head2 set($key, $value, $expires)

=head2 delete($key)

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
