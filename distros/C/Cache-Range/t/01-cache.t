use strict;
use warnings;

use Cache::Memory;
use Test::More;

plan tests => 19;
use_ok 'Cache::Range';

my @entries;

my $cache  = Cache::Memory->new(default_expires => $Cache::EXPIRES_NEVER);
my $rcache = Cache::Range->new($cache);
$rcache->set('foobar', 0, [ 0..9 ]);
$rcache->set('foobar', 20, [ 20..29 ]);

@entries = $rcache->get('foobar', 0, 9);
is_deeply([ 0, [ 0..9 ] ], \@entries);

@entries = $rcache->get('foobar', 0, 5);
is_deeply([ 0, [ 0..5 ] ], \@entries);

@entries = $rcache->get('foobar', 3, 7);
is_deeply([ 3, [ 3..7 ] ], \@entries);

@entries = $rcache->get('foobar', 6, 9);
is_deeply([ 6, [ 6..9 ] ], \@entries);

@entries = $rcache->get('foobar', -3, 9);
is_deeply([ 0, [ 0..9 ] ], \@entries);

@entries = $rcache->get('foobar', -3, 3);
is_deeply([ 0, [ 0..3 ] ], \@entries);

@entries = $rcache->get('foobar', 6, 12);
is_deeply([ 6, [ 6..9 ] ], \@entries);

@entries = $rcache->get('foobar', -10, -1);
is_deeply([], \@entries);

@entries = $rcache->get('foobar', 15, 19);
is_deeply([], \@entries);

@entries = $rcache->get('foobar', 0, 29);
is_deeply([ 0, [ 0..9 ], 20, [ 20..29 ] ], \@entries);

@entries = $rcache->get('foobar', 5, 29);
is_deeply([ 5, [ 5..9 ], 20, [ 20..29 ] ], \@entries);

@entries = $rcache->get('foobar', 0, 24);
is_deeply([ 0, [ 0..9 ], 20, [ 20..24 ] ], \@entries);

@entries = $rcache->get('foobar', 5, 24);
is_deeply([ 5, [ 5..9 ], 20, [ 20..24 ] ], \@entries);

@entries = $rcache->get('foobar', -30, 50);
is_deeply([ 0, [ 0..9 ], 20, [ 20..29 ] ], \@entries);

$rcache->set('foobar', 10, [ 10..19 ]);

@entries = $rcache->get('foobar', -30, 50);
is_deeply([ 0, [ 0..9 ], 10, [ 10..19 ], 20, [ 20..29 ] ], \@entries);

@entries = $rcache->get('barfoo', 0, 9);
is_deeply([], \@entries);

$rcache->set('barfoo', 0, [ 0..4 ], '2 seconds');
$rcache->set('barfoo', 5, [ 5..9 ], '10 seconds');
@entries = $rcache->get('barfoo', 0, 9);
is_deeply([ 0, [ 0..4 ], 5, [ 5..9] ], \@entries);

sleep 5;

@entries = $rcache->get('barfoo', 0, 9);
is_deeply([ 5, [ 5..9] ], \@entries);
