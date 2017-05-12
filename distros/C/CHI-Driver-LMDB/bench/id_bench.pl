#!/usr/bin/env perl
# FILENAME: bench.pl
# CREATED: 09/13/14 01:28:57 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Benchmark CHI Methods

use strict;
use warnings;
use utf8;

use Path::Tiny;
use Data::Serializer::Sereal;
use LMDB_File qw( :envflags );
use Math::Random::ISAAC;
use CHI;
use Time::HiRes qw( gettimeofday tv_interval );

my $modes = {
  fresh => {
    root => sub { Path::Tiny->tempdir }
  },
  reuse => {
    root => sub {
      return Path::Tiny->tempdir->parent->child('chi_bench');
    },
  },
};

my $mode = 'fresh';
if ( $ENV{REUSE} ) {
  $mode = 'reuse';
}

my $root = $modes->{$mode}->{root}->();

my $s = Data::Serializer::Sereal->new();

my %common = (
  expires_in     => '5h',
  key_serializer => $s,
  serializer     => $s,
  root_dir       => $root . q[],
  cache_size     => '5m',
);

my @configs;
my @sync_modes;
my @txn_modes;

push @configs, {
  %common,

  label  => 'FastMmap',
  driver => 'FastMmap',
};

push @sync_modes, { label => 'SYNC',                mode => {} };
push @sync_modes, { label => 'NOSYNC',              mode => { flags => MDB_NOSYNC } };
push @sync_modes, { label => 'NOMETASYNC',          mode => { flags => MDB_NOMETASYNC } };
push @sync_modes, { label => 'NOSYNC | NOMETASYNC', mode => { flags => MDB_NOSYNC | MDB_NOMETASYNC } };
push @txn_modes,  { label => 'MTX',                 mode => {} };
push @txn_modes,  { label => 'SINGLE',              mode => { single_txn => 1 } };

for my $txn_mode (@txn_modes) {
  for my $sync_mode (@sync_modes) {
    push @configs, {
      %common,

      label  => ( sprintf q[LMDB %s %s], $txn_mode->{label}, $sync_mode->{label} ),
      driver => 'LMDB',
      %{ $txn_mode->{mode} },
      %{ $sync_mode->{mode} },
    };
  }
}

my $key_size   = 1024;
my $value_size = 32768;
my $test_max   = 10;

if ( $ENV{KEY_SIZE} ) {
  $key_size = $ENV{KEY_SIZE};
}
if ( $ENV{VALUE_SIZE} ) {
  $value_size = $ENV{VALUE_SIZE};
}
if ( $ENV{TEST_MAX} ) {
  $test_max = $ENV{TEST_MAX};
}

sub mk_key {
  my ($key_id) = shift;
  my $key_seq = Math::Random::ISAAC->new( unpack 'L*', "This is a benchmark" );
  my $value;
  for ( 0 .. $key_id - 1 ) {
    for ( 0 .. $key_size / 32 ) {
      $key_seq->irand;
    }
  }
  $value = '';
  for ( 0 .. $key_size / 32 ) {
    $value .= pack 'L', $key_seq->irand;
  }
  return $value;
}

sub mk_value {
  my ($key_value) = shift;
  my $value_seq = Math::Random::ISAAC->new( unpack 'L*', "This is a benchmark value $key_value" );
  my $value = '';
  for ( 0 .. $value_size / 32 ) {
    $value .= pack 'L', $value_seq->irand;
  }
  return $value;
}

sub run_test {
  my ($id)  = shift;
  my $test  = { %{ $configs[$id] } };
  my $label = delete $test->{label};

  my ( $write_time, $read_time );
  {
    my $cache = CHI->new( %{$test} );
  }
  {
    my $start = [gettimeofday];
    my $cache = CHI->new( %{$test} );
    for ( 0 .. $test_max ) {
      my $key = mk_key($_);
      $cache->compute(
        $key, undef,
        sub {
          return mk_value($key);
        }
      );
    }
    undef $cache;
    $write_time = tv_interval( $start, [gettimeofday] );
  }
  {
    my $start = [gettimeofday];
    my $cache = CHI->new( %{$test} );
    for ( 0 .. $test_max ) {
      my $key = mk_key($_);
      $cache->compute(
        $key, undef,
        sub {
          return mk_value($key);
        }
      );
    }
    undef $cache;
    $read_time = tv_interval( $start, [gettimeofday] );
  }
  printf "%s,%s,%s\n", $label, $write_time, $read_time;

}
run_test( $ENV{TEST_ID} );
