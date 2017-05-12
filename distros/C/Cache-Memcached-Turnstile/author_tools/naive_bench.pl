#!perl
use strict;
use warnings;
use lib 'lib';
use Cache::Memcached::Turnstile qw(:all);

use Cache::Memcached::Fast;
use Sereal::Encoder;
use Sereal::Decoder;
use Data::Dumper;
use Benchmark::Dumb qw(cmpthese);

my $enc = Sereal::Encoder->new({snappy_incr => 1});
my $dec = Sereal::Decoder->new();

my $memd = Cache::Memcached::Fast->new({
  servers             => [ { address => 'localhost:11211', weight => 1.0 } ],
  ketama_points       => 150,
  nowait              => 0,
  compress_threshold  => 1e99,
  serialize_methods   => [ sub {$enc->encode($_[0])}, sub {$dec->decode($_[0])} ],
});

# Something small but not tiny
my $value = [[1..5]];

my $key_direct = "foo";
my $key_turnstile = "bar";
$memd->set($key_direct, $value, 0); # do not expire
$memd->set($key_turnstile, [0, time()+1e9, $value], 0); # do not expire

#use Benchmark qw(:hireswallclock timethese);

cmpthese(10000.90, {
#timethese(50000, {
  direct => sub {
    $memd->get($key_direct);
  },
  turnstile => sub {
    cache_get_or_compute(
      $memd,
      key          => $key_turnstile,
      expiration   => 0,
      compute_cb   => sub { $value },
    );
  },
});

#my $nkeys = 20;
my $nkeys = 1;
my @k_direct = map {"foo$_"} 1..$nkeys;
my @k_turnstile = map {["bar$_", 999999]} 1..$nkeys;

my @set_args = (
  (map [$_->[0], [0, 0, $value], $_->[1]], @k_turnstile),
  map [$_, $value, 0], @k_direct
);
$memd->set_multi(@set_args);

cmpthese(10000.90, {
#timethese(10000, {
  turnstile => sub {
    multi_cache_get_or_compute(
      $memd,
      keys         => \@k_turnstile,
      expiration   => 0,
      compute_cb   => sub { return [($value) x scalar(@{$_[2]}) ] },
      wait => sub{return undef},
    );
  },
  direct => sub {
    $memd->get_multi(@k_direct);
  },
});
