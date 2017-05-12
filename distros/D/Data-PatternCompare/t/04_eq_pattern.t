use strict;
use warnings;

use Test::More;

use Data::PatternCompare;

my $m = Data::PatternCompare->new;

subtest 'simple match' => sub {
    eq_p(42, 42, 'int value match');
    ne_p(42, 41, 'int value does not match');

    eq_p("hello", "hello", 'string value match');
    ne_p("hello", "world", 'string value does not match');

    eq_p(undef, undef, 'undef value match');
    ne_p(42, undef, 'value does not match undef');
    ne_p(undef, 42, 'undef does not match value');

    eq_p(0.1 + 0.2 + 0.3, 0.6, 'float match');
    ne_p(0.6, 1, 'float to int match');

    ne_p(42, $Data::PatternCompare::any, 'compare int to any');
    eq_p($Data::PatternCompare::any, $Data::PatternCompare::any, 'compare any to any');
    ne_p("hello", $Data::PatternCompare::any, 'compare string to any');
    ne_p({}, $Data::PatternCompare::any, 'compare hash to any');
    ne_p([], $Data::PatternCompare::any, 'compare array to any');
    ne_p(undef, $Data::PatternCompare::any, 'compare undef to any');

    ne_p([], {}, 'different types does not eq');

    done_testing;
};

subtest 'array match' => sub {
    eq_p([42], [42], 'equal arrays');
    ne_p([42], [41], 'not equal arrays');

    ne_p([1, 2, 3], [1, 42, 3], 'arrays should be exact');

    ne_p([42, 1], [42], 'different size of arrays');
    ne_p([], [ $Data::PatternCompare::any ], 'any is not an empty array');

    eq_p([ ], [ ], 'zero size arrays are equal');
    eq_p([ @Data::PatternCompare::empty ], [ @Data::PatternCompare::empty ], 'equal empty arrays');
    ne_p([ ], [ @Data::PatternCompare::empty ], 'empty array are not equal to zero size array');
};

subtest 'hash match' => sub {
    eq_p({data => 42}, {data => 42}, 'equal hashes');
    ne_p({data => 42}, {data => 41}, 'not equal hashes');

    ne_p({data => 42, a => 'b'}, {data => 42}, 'hash sizes are not equal');
    ne_p({a => 'b'}, { data => $Data::PatternCompare::any }, 'different hashes with any');

    eq_p({ }, { }, 'zero size hashes are equal');
    eq_p({ @Data::PatternCompare::empty }, { @Data::PatternCompare::empty }, 'equal empty hashes');
    ne_p({ }, { @Data::PatternCompare::empty }, 'empty hash are not equal to zero size hash');
};

done_testing;

sub ne_p {
    my ($data, $pattern, $message) = @_;

    ok(!$m->eq_pattern($data, $pattern), $message);
}

sub eq_p {
    my ($data, $pattern, $message) = @_;

    ok($m->eq_pattern($data, $pattern), $message);
}
