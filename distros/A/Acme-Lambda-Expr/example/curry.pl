#!perl -w

use strict;
use feature 'say';
use Time::localtime qw(localtime ctime);
use Acme::Lambda::Expr qw(:all);

my $f = curry(\&ctime, $x);

say '[1]', $f->(time);
say 'stringified = ', $f;
say 'deparsed    = ', $f->deparse;


$f = curry('year', $x) + 1900;

say '[2]', $f->(scalar localtime);
say 'stringified = ', $f->stringify;
say 'deparsed    = ', $f->deparse;
