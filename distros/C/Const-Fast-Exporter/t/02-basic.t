#! perl

use 5.010;
use strict;
use warnings;

use Test::More 0.88;

use lib 't/lib';
use TestConstants;

#-----------------------------------------------------------------------
# Tests on immutable scalar
#-----------------------------------------------------------------------

ok($SCALAR == 42, "\$SCALAR should be imported, and have value 42");

eval {
    $SCALAR = "forty-two";
};
ok($@, "trying to change immutable scalar should throw exception");

#-----------------------------------------------------------------------
# Tests on immutable array
#-----------------------------------------------------------------------

ok(int(@ARRAY) == 5 && "@ARRAY" eq "there can be only one",
   "\$SCALAR should be imported, and have value 42");

eval {
    push(@ARRAY, "or", "two");
};
ok($@, "trying to change immutable array should throw exception");

#-----------------------------------------------------------------------
# Tests on immutable hash
#-----------------------------------------------------------------------

ok(int(keys %HASH) == 2 && $HASH{x} == 12 && $HASH{y} == 67,
   "check immutable hash has expected keys and values, and nothing else");

eval {
    $HASH{z} = 13;
};
ok($@, "trying to add new key to immutable hash should throw exception");

eval {
    $HASH{x} = 10;
};
ok($@, "trying to change existing entry in immutable hash should throw exception");

#-----------------------------------------------------------------------
# Mutable package variable should not have been imported
#-----------------------------------------------------------------------
{
    no strict 'vars';
    no warnings 'once';
    ok(!defined($MUTABLE),
       "mutable package variable should not have been imported");
}

done_testing;

