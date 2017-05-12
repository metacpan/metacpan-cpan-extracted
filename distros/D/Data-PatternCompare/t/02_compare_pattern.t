use strict;
use warnings;

use Test::More;

use Data::PatternCompare;

my $m = Data::PatternCompare->new;

subtest 'simple patterns' => sub {
    equal(42, 42, 'simple ints');
    equal(42, "string", 'int and string');

    less(42, $Data::PatternCompare::any, 'simple type less than any');
    greater($Data::PatternCompare::any, "hello", 'ref greater than simple type');
    less(42, [], 'simple type less than reference');

    equal($Data::PatternCompare::any, $Data::PatternCompare::any, 'any equal to any');
    equal({}, [], 'different types are equal');
};

subtest 'array pattern' => sub {
    less([1, 2], [1], 'array less if it has more values');
    equal([1, 2], [3, 4], 'equal array patterns');
    equal([], [], 'zero size arrays - equal patterns');

    equal([@Data::PatternCompare::empty], [@Data::PatternCompare::empty], 'empty arrays - equal patterns');
    less([@Data::PatternCompare::empty], [], 'empty array is less than zero size array');
    greater([42], [@Data::PatternCompare::empty], 'any array greater than empty array');

    greater([42, $Data::PatternCompare::any], [1, 2], 'array with any greater than array with simple types');
};

subtest 'hash pattern' => sub {
    less({ data => 42, a => 'b'}, {data => 42}, 'bigger hashes are more strict than less in pattern comparison');
    equal({data => 42}, {data => 'a'}, 'equal hash patterns');
    equal({}, {}, 'zero size hashes - equal patterns');
    equal({qw|a b c d|}, {qw|a b e f|}, 'hash size equal, key intersection are equal');

    equal({@Data::PatternCompare::empty}, {@Data::PatternCompare::empty}, 'empty hashes - equal patterns');
    less({@Data::PatternCompare::empty}, {}, 'empty hash is less than zero size hash');
    greater({data => 42}, {@Data::PatternCompare::empty}, 'any hash greater than empty hash');

    greater({data => $Data::PatternCompare::any}, {data => 42}, 'hash pattern with any greater than with simple type')
};

done_testing;

sub less {
    my ($pat1, $pat2, $message) = @_;

    ok($m->compare_pattern($pat1, $pat2) < 0, $message);
}

sub equal {
    my ($pat1, $pat2, $message) = @_;

    ok($m->compare_pattern($pat1, $pat2) == 0, $message);
}

sub greater {
    my ($pat1, $pat2, $message) = @_;

    ok($m->compare_pattern($pat1, $pat2) > 0, $message);
}
