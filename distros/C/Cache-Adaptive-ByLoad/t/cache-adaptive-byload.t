#! /usr/bin/perl

use strict;
use warnings;
use Test::More (tests => 5);

use Cache::MemoryCache;

BEGIN {
    use_ok(q(Cache::Adaptive::ByLoad));
};

my $r;
undef $@;
eval {
    $r = Cache::Adaptive::ByLoad::_load_avg();
};
is($@, '');
ok($r >= 0.001);

undef $@;
undef $r;
eval {
    $r = Cache::Adaptive::ByLoad->new({
        backend => Cache::MemoryCache->new({
            namespace => q (byload),
        }),
    });
};
is($@, '');
is(ref $r, q(Cache::Adaptive::ByLoad));

    
