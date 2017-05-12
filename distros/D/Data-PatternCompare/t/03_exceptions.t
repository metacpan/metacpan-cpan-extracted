use strict;
use warnings;

use Test::More;

use Data::PatternCompare;

my $m = Data::PatternCompare->new;

subtest 'pattern_match exceptions' => sub {
    my $x = [];
    $x->[0] = $x;

    match([42], $x, 'cycled pattern');
    match(42, \&match, 'CODE are not allowed by default');

    delete($x->[0]);
    done_testing;
};

subtest 'compare_pattern exceptions' => sub {
    my $x = [];
    $x->[0] = $x;

    compare($x, [[42]], 'cycled pattern 1');
    compare([[42]], $x, 'cycled pattern 2');

    compare(\&compare, \&match, 'both: CODE are not allowed by default');

    delete($x->[0]);
    done_testing;
};

subtest 'eq_pattern exceptions' => sub {
    my $x = [42];
    $x->[0] = $x;

    eq_p([[42]], $x, 'cycled pattern 2');

    delete($x->[0]);
    done_testing;
};

done_testing;

sub match {
    my ($data, $pattern, $message) = @_;

    eval {
        $m->pattern_match($data, $pattern);
    };

    ok($@, $message);
}

sub compare {
    my ($pat1, $pat2, $message) = @_;

    eval {
        $m->compare_pattern($pat1, $pat2);
    };

    ok($@, $message);
}

sub eq_p {
    my ($pat1, $pat2, $message) = @_;

    eval {
        $m->eq_pattern($pat1, $pat2);
    };

    ok($@, $message);
}
