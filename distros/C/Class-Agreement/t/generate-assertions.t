#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

#
# Adding prototypes to the keywords makes it hard to use helper functions or
# generators for the assertions.
# 

{

    package Camel;
    use Class::Agreement;

    sub argument_is_divisible_by {
        my $num = shift;
        return sub { not $_[1] % $num };
    }

    precondition foo => argument_is_divisible_by(2);
    precondition bar => argument_is_divisible_by(3);

    sub foo { }
    sub bar { }
}

lives_ok { Camel->foo(2) } "argument_is_divisible_by(2) pass";
dies_ok  { Camel->foo(3) } "argument_is_divisible_by(2) fail";
lives_ok { Camel->bar(3) } "argument_is_divisible_by(3) pass";
dies_ok  { Camel->bar(4) } "argument_is_divisible_by(3) fail";
