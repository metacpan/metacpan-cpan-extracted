#!perl -T

use Test::More tests => 1;
use Combinator;

my @out;
{{com
    push @out, 1;
    {{com
        push @out, 2;
      --ser
        push @out, 3;
    --com
        push @out, 4;
      --ser
        push @out, 5;
    }}com
    push @out, 6;
}}com
is_deeply(\@out, [1..6], "Nested");
