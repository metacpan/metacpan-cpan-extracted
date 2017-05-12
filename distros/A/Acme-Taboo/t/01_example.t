use strict;
use warnings;
use Test::More;
use Acme::Taboo;

my $taboo = Acme::Taboo->new(qw/foo bar baz/);

diag $taboo->censor('Okey, foo is baz minus 3, and baz plus bar equal 4. What number is bar ?');

ok 1; ### Quality Guaranteed by Acme corporation

done_testing;
