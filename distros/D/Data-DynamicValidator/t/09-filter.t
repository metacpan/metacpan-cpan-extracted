use strict;
use warnings;

use Test::More;
use Test::Warnings;

use aliased qw/Data::DynamicValidator::Filter/;
use Data::DynamicValidator;

subtest 'filter-by-size(array)' => sub {
    my $filter = Filter->new('size == 5');
    ok $filter->([1..5]), " size equality works well (positive test)";
    ok !$filter->([1..2]), " size equality works well (negative test)";
    ok !$filter->([1..20]), " size equality works well (negative test)";
    ok !$filter->('abc'), " size equality works well (negative test)";
};

subtest 'filter-by-size(hash)' => sub {
    my $filter = Filter->new('size == 2');
    ok $filter->({a => 2, b => 3}), " size equality works well (positive test)";
    ok !$filter->({a => 2}), " size equality works well (negative test)";
    ok !$filter->({a => 2, b => 3, c => 4}), " size equality works well (negative test)";
    ok !$filter->('abc'), " size equality works well (negative test)";
};

subtest 'filter-by-value' => sub {
    my $filter = Filter->new('value == 2');
    ok $filter->(2), "positive test";
    ok $filter->("2"), "positive test";
    ok !$filter->(3), "negative test";
    ok !$filter->(undef), "negative test";
    ok !$filter->([]), "negative test";
    ok !$filter->({}), "negative test";
    ok !$filter->(sub {}), "negative test";
};

subtest 'filter-by-index' => sub {
    my $filter = Filter->new('index == 2');
    ok $filter->([], {index => 2}), "positive test";
    ok $filter->([], {index => "2"}), "positive test";
    ok !$filter->([], {index => "1"}), "negative test";
    ok !$filter->([], {index => undef}), "negative test";
    ok !$filter->([]), "negative test";
};

subtest 'filter-by-key' => sub {
    my $filter = Filter->new('key =~ /ab/');
    ok $filter->([], {key => 'abc'}), "positive test";
    ok $filter->([], {key => "1abc1"}), "positive test";
    ok $filter->([], {key => "ab"}), "positive test";
    ok !$filter->([], {key => "1"}), "negative test";
    ok !$filter->([], {key => undef}), "negative test";
    ok !$filter->([]), "negative test";
};

done_testing;
