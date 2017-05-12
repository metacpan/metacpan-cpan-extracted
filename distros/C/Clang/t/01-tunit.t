#!perl -T

use Test::More;

use Clang;

my $index = Clang::Index -> new(0);
my $tunit = $index -> parse('t/fragments/test.c');

is($tunit -> spelling, 't/fragments/test.c');

done_testing;
