#!perl
use Test2::V0;
use PPI::Document;
use App::PerlNitpick::Rule::RewriteWithAssignmentOperators;

subtest 'rewrite with assignment operators' => sub {
    my @tests = (
        ['$x=$x+2;', '$x+=2;'],
        ['$x=$x*2;', '$x*=2;'],
        ['$x=$x*$x;', '$x*=$x;'],
        ['$x=$x//3;', '$x//=3;'],
        ['$x=$x->[3];', '$x=$x->[3];'],
        ['$x = $y . $x;', '$x = $y . $x;'],
        ['$x = $x . $y;', '$x .= $y;'],
        ['$x = $y + $x;', '$x = $y + $x;'],
    );

    for my $t (@tests) {
        my ($code_before, $code_after) = @$t;

        my $doc = PPI::Document->new(\$code_before);
        my $o = App::PerlNitpick::Rule::RewriteWithAssignmentOperators->new();
        my $doc2 = $o->rewrite($doc);
        my $code2 = "$doc2";
        is $code2, $code_after, $code_before;
    }
};

done_testing;
