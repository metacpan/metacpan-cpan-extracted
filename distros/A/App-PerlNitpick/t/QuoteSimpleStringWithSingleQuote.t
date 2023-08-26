#!perl
use Test2::V0;
use App::PerlNitpick::Rule::QuoteSimpleStringWithSingleQuote;

subtest 'quote simple string with single quote' => sub {
    my @tests = (
        [q{print "riho";}, q{print 'riho';}],

        # Multiline strings. String literal newline characetrs.
        [q{print "riho
";}, q{print "riho
";}],
    );

    for my $t (@tests) {
        my ($code_before, $code_after) = @$t;

        my $doc = PPI::Document->new(\$code_before);
        my $o = App::PerlNitpick::Rule::QuoteSimpleStringWithSingleQuote->new();
        my $doc2 = $o->rewrite($doc);
        my $code2 = "$doc2";
        is $code2, $code_after, $code_before;
    }
};

done_testing;

