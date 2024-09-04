#!/bin/perl

use strict;
use warnings;
use Test::More;
use Tie::Array;
use Tie::Hash;
use Tie::Scalar;

use Arcus::Client;

use FindBin;
use lib "$FindBin::Bin";
use ArcusTestCommon;

if (not ArcusTestCommon->is_zk_port_opened()) {
  plan skip_all => "zk is not running...";
}

open(STDERR, '>', '/dev/null');

tie my $scalar, 'Tie::StdScalar';
tie my @array,  'Tie::StdArray';
tie my %hash,   'Tie::StdHash';

my $cache = ArcusTestCommon->create_client();
unless (ok($cache, "Check Arcus Client Is Created Appropriately")) {
  plan skip_all => "arcus client is not created appropriately...";
};

my $key = "Кириллица.в.UTF-8";
$scalar = $key;
ok $cache->set( $scalar, $scalar );
ok exists $cache->get_multi($scalar)->{$scalar};
is $cache->get($scalar), $key;
is $cache->get($key),    $scalar;

@MyScalar::ISA = 'Tie::StdScalar';
sub MyScalar::FETCH {'Другой.ключ'}
tie my $scalar2, 'MyScalar';

ok $cache->set( $scalar2 => $scalar2 );
is $cache->get($scalar2), $scalar2;

SKIP: {
  eval { require Readonly };
  skip "Skipping Readonly tests because the module is not present", 3
      if $@;

  # 'require Readonly' as above can be used to test if the module is
  # present, but won't actually work.  So below we 'use Readonly',
  # but in a string eval.
  eval q{
    use Readonly;

    Readonly my $expires => 3;

    Readonly my $key2 => "Третий.ключ";
    ok $cache->set($key2, $key2, $expires);
    ok exists $cache->get_multi($key2)->{$key2};
    sleep 4;
    ok !exists $cache->get_multi($key2)->{$key2};
  };
}

done_testing;
