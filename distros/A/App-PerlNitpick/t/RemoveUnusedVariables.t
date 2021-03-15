#!perl
use strict;
use Test2::V0;

use PPI::Document;
use App::PerlNitpick::Rule::RemoveUnusedVariables;

my @tests = (
    [q{my $x;print 42;}, q{print 42;}],
);

for my $t (@tests) {
    my ($code_before, $code_after) = @$t;

    my $doc = PPI::Document->new(\$code_before);
    my $o = App::PerlNitpick::Rule::RemoveUnusedVariables->new();
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";
    is $code2, $code_after, $code_before;
}

done_testing;
