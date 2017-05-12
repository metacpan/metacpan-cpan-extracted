#!perl -T

use Test::More tests => 1;
use Combinator;

my @out;
{{com
    push @out, 1;
  --ser
    push @out, 2;
  --ser
    push @out, 3;
}}com
is_deeply(\@out, [1,2,3], "Simple serial");
