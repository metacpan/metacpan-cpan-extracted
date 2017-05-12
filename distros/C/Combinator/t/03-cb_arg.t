#!perl -T

use Test::More tests => 1;
use Combinator;

my @out;
{{com
    push @out, 1;
    {{com
        push @out, 2;
        {{next}}->(-1);
      --ser
        push @out, 3;
        {{next}}->(@_, -2);
    --com
        push @out, 4;
        {{next}}->(-3);
      --ser
        push @out, 5;
        {{next}}->(@_, -4);
    }}com
  --ser
    push @out, 6;
    push @out, @_;
}}com
is_deeply(\@out, [1..6, -1, -2, -3, -4], "CB Arg");
