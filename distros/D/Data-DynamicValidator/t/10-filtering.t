use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;

my $data = {
    a => [
        { b => 4},
        undef,
    ],
    c => "bbb",
    c2 => 5,
    "dc/1" => [],
    d => undef,
    e => [ qw/e1 e2 z/ ],
};

subtest 'filter-in-hashrefs' => sub {
    my ($r, $values);

    ($r, $values) = validator($data)->_apply('/*[key eq "d"]' => sub { 1 });
    ok $r;
    is @{ $values->{routes} }, 1 , "1 route selected (/d)";
    is $values->{routes}->[0]->to_string, '/d', "it is /d";
    is $values->{values}->[0], undef, "/d value is undef";

    ($r, $values) = validator($data)->_apply('/`*[key =~ /d/]`' => sub { 1 });
    ok $r;
    is @{ $values->{routes} }, 2 , "1 route selected (/d and /dc/1)";
    is $values->{routes}->[0]->to_string, '/`dc/1`', "it is /d/dc/1";
    is $values->{routes}->[1]->to_string, '/d', "it is /d";
    is_deeply $values->{values}->[0] , [], "/dc/1 refers to empty array";
    is $values->{values}->[1], undef, "/d value is undef";

    ($r, $values) = validator($data)->_apply('/*[value eq "bbb"]' => sub { 1 });
    ok $r;
    is @{ $values->{routes} }, 1 , "1 route selected (/c)";
    is $values->{routes}->[0]->to_string, '/c', "it is /c";
    is $values->{values}->[0], "bbb", "/c value is 'bbb'";
};


subtest 'filter-in-arrays' => sub {
    my ($r, $values);

    ($r, $values) = validator($data)->_apply('/e/`*[value =~ /^e/]`' => sub { 1 });
    ok $r;
    is @{ $values->{routes} }, 2 , "2 route selected (/e/{e1,e2})";
    is $values->{values}->[0], "e1";
    is $values->{values}->[1], "e2";

    ($r, $values) = validator($data)->_apply('/e/`*[index > 0]`' => sub { 1 });
    ok $r;
    is @{ $values->{routes} }, 2 , "2 route selected (/e/{e2,z})";
    is $values->{values}->[0], "e2";
    is $values->{values}->[1], "z";

    ($r, $values) = validator($data)->_apply('/`*[size == 2]`' => sub { 1 });
    ok $r;
    is_deeply $values->{values}->[0], [ {b => 4}, undef, ];
};

subtest 'double-filter' => sub {
    my ($r, $values);

    ($r, $values) = validator($data)->_apply('/`*[size == 2]`/*/*[key eq "b"]' => sub { 1 });
    ok $r;
    is $values->{values}->[0], 4;
};

done_testing;
