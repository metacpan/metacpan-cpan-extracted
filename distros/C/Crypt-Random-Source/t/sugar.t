use strict;
use warnings;

use Test::More 0.88;

use ok 'Crypt::Random::Source';

ok( defined &get_weak, "get_weak" );
ok( defined &get_strong, "get_strong" );

is( length(get_weak(10)), "10", "got 10 weak bytes" );

isa_ok( $Crypt::Random::Source::weak, "Crypt::Random::Source::Weak" );

ok( !$Crypt::Random::Source::strong, "no strong source yet" );

done_testing;
# ex: set sw=4 et:
