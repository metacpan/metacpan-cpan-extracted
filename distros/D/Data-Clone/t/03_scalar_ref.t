#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Clone;

for(1 .. 2){ # do it twice to test internal data

    my $s = 'foobar';
    my @a = (\substr $s, 1, 2);
    my $c = clone(\@a);

    is ${$c->[0]}, 'oo';
    ${$c->[0]} = 'xx';

    is $s, 'fxxbar', 'ScalarRef is copied in surface';
}

done_testing;
