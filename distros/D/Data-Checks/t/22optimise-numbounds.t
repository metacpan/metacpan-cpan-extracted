#!/usr/bin/perl

use v5.22;
use warnings;

use Test2::V0;

use Data::Checks qw( NumGT NumGE NumLE NumLT NumRange Isa All );

*stringify = \&Data::Checks::Debug::stringify_constraint;

# All() of two same single-sided bounds should always pick the tighter
is( stringify( All(NumGT(10), NumGT(20)) ), "NumGT(20)",
   'All(NumGT(10), NumGT(20))' );
is( stringify( All(NumGE(10), NumGE(20)) ), "NumGE(20)",
   'All(NumGE(10), NumGE(20))' );
is( stringify( All(NumLE(10), NumLE(20)) ), "NumLE(10)",
   'All(NumLE(10), NumLE(20))' );
is( stringify( All(NumLT(10), NumLT(20)) ), "NumLT(10)",
   'All(NumLT(10), NumLT(20))' );

# Inclusive followed by exclusive of same bound loses the flag
is( stringify( All(NumGE(30), NumGT(30)) ), "NumGT(30)",
   'All(NumGE(30), NumGT(30))' );
is( stringify( All(NumLE(40), NumLT(40)) ), "NumLT(40)",
   'All(NumLE(40), NumLT(40))' );

# All() of NumGE and NumLT stringifies as NumRange()
is( stringify( All(NumGE(50), NumLT(60)) ), "NumRange(50, 60)",
   'All(NumGE(50), NumLT(60))' );
# others stringify as All() combos
is( stringify( All(NumGT(50), NumLT(60)) ), "All(NumGT(50), NumLT(60))",
   'All(NumGT(50), NumLT(60))' );
is( stringify( All(NumGT(50), NumLE(60)) ), "All(NumGT(50), NumLE(60))",
   'All(NumGT(50), NumLE(60))' );
is( stringify( All(NumGE(50), NumLE(60)) ), "All(NumGE(50), NumLE(60))",
   'All(NumGE(50), NumLE(60))' );

# NumRange() combines with others
is( stringify( All(NumRange(10, 30), NumGT(20)) ), "All(NumGT(20), NumLT(30))",
   'All(NumRange(10, 30), NumGT(20))' );
is( stringify( All(NumRange(10, 30), NumGE(20)) ), "NumRange(20, 30)",
   'All(NumRange(10, 30), NumGE(20))' );
is( stringify( All(NumRange(10, 30), NumLE(20)) ), "All(NumGE(10), NumLE(20))",
   'All(NumRange(10, 30), NumLE(20))' );
is( stringify( All(NumRange(10, 30), NumLT(20)) ), "NumRange(10, 20)",
   'All(NumRange(10, 30), NumLT(20))' );

# Other constraints are still preserved
is( stringify( All(NumGE(10), NumLT(30), Isa("SomeClass")) ), "All(NumRange(10, 30), Isa(\"SomeClass\"))",
   'All(NumGE(10), NumLT(30), Isa("SomeClass"))' );

done_testing;
