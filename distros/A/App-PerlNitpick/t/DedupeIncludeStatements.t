#!perl
use strict;
use Test2::V0;

use PPI::Document;
use App::PerlNitpick::Rule::DedupeIncludeStatements;

my @tests = (
    [q{use Abc; print "riho";use Abc;}, q{use Abc; print "riho";}],
    [q{use Abc 'foo'; print "riho";use Abc;}, q{use Abc 'foo'; print "riho";use Abc;}],
    [q{use Abc 'foo'; print "riho";use Abc 'foo';}, q{use Abc 'foo'; print "riho";}],
);

for my $t (@tests) {
    my ($code_before, $code_after) = @$t;

    my $doc = PPI::Document->new(\$code_before);
    my $o = App::PerlNitpick::Rule::DedupeIncludeStatements->new();
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";
    is $code2, $code_after, $code_before;
}

done_testing;

