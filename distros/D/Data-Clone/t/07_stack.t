#!perl -w

use strict;
use warnings FATAL => 'all';

use Test::More;

use Data::Clone;

{
    package Bar;
    sub clone {
        () = (1)x100000; # extend the stack
        return []
    }
}

my $before = bless [], Bar::;
my $after  = clone($before);
isn't $after, $before, 'stack reallocation during callback';

done_testing;
