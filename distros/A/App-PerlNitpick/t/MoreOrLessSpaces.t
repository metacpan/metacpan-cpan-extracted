#!perl
use strict;
use Test2::V0;

use PPI::Document;
use App::PerlNitpick::Rule::MoreOrLessSpaces;

my @tests = (
    [q{my ($x,$y,$z) = something($a,$b,$c);},
     q{my ($x, $y, $z) = something($a, $b, $c);}],
    [q{
$a=1;


$b=1;
},
     q{
$a=1;

$b=1;
}],
    [q{
$a=1;

    
$b=1;
},
     q{
$a=1;

$b=1;
}],
);

for my $t (@tests) {
    my ($code_before, $code_after) = @$t;

    my $doc = PPI::Document->new(\$code_before);
    my $o = App::PerlNitpick::Rule::MoreOrLessSpaces->new();
    my $doc2 = $o->rewrite($doc);
    my $code2 = "$doc2";
    is $code2, $code_after, $code_before;
}

done_testing;
