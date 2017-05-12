#!perl -w

use strict;
use feature 'say';
use Acme::Lambda::Expr qw(:all);

my $f = $x * 2 + $y;
say $f->(20, 2); # 20*2 + 2 = 42

my $g = curry $f, $x, 4;
say $g->(19);    # 18*2 + 4 = 42

my $h = curry deparse => $x;
say 'f = ', $f;
say 'g = ', $g;

say 'f = ', $h->($f); # $f->deparse()
say 'g = ', $h->($g); # $g->deparse()

say $g->compile(1)->(19);
