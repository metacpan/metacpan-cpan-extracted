
use strict;
use Test;

my @tests = (
    [ 7654321 => '638W1Z1e4m35s' ],
);

plan tests => 1+@tests;

eval { use Time::DeltaString qw/delta_string/ }; ok( $@, '' );

@Time::DeltaString::conversions = (
    [ W => 11987 ], # prime number time units...
    [ Z => 5003 ],  # prime number time units...
    [ h => 60*60 ],
    [ e => 1337 ], # elite time
    [ m => 60 ],
    [ s => 1 ],
);

for my $i (@tests) {
    ok("$i->[0] -> " . delta_string($i->[0]), "$i->[0] -> $i->[1]");
}
