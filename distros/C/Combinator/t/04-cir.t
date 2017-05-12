#!perl -T

use Test::More tests => 1;
use Combinator;

my @out;
{{com
    my $n = 0;
    {{cir
        push @out, ++$n;
        return if $n==3;
    --cir
        push @out, --$n;
        return if $n==0;
    }}com
  --ser
    push @out, 9;
}}com
is_deeply(\@out, [1,2,3,2,1,0,9], "cir");
