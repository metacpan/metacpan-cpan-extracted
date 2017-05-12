use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::DynamicValidator qw/validator/;

subtest 'simple-labels' => sub {
    my $data = {
        a => [
            { b => 5, },
            { c => 7, }
        ],
    };
    my $v = validator($data);
    my @variables;
    my @values;
    $v->(
        on      => '/hash1:*/array:*/hash2:*',
        should  => sub { @_ > 0 },
        because => '...ignored...',
        each    => sub {
            my ($hash1, $array, $hash2);
            push @variables, join('/', '', $hash1, $array, $hash2);
            push @values, {
                hash1 => $hash1->(),
                hash2 => $hash2->(),
                array => $array->(),
                _     => $_->(),
            }
        },
    );
    ok $v->is_valid;
    is_deeply \@variables, ['/a/0/b', '/a/1/c'],
        "labels extraction/substitution works well";

    subtest 'values for 1st expanded route' => sub {
        is_deeply $values[0]->{hash1}, [{ b => 5}, { c => 7}];
        is_deeply $values[0]->{array}, { b => 5};
        is_deeply $values[0]->{hash2}, 5;
        is_deeply $values[0]->{_}, 5;
    };

    subtest 'values for 2nd expanded route' => sub {
        is_deeply $values[1]->{hash1}, [{ b => 5}, { c => 7}];
        is_deeply $values[1]->{array}, { c => 7};
        is_deeply $values[1]->{hash2}, 7;
        is_deeply $values[1]->{_}, 7;
    };
};

subtest 'simple-labels-in-path' => sub {
    my $data = {
        a => [
            { b => 5, },
            { c => 7, }
        ],
    };
    my $v = validator($data);
    my @examined_values;
    $v->(
        on      => '/hash1:*/array:*/hash2:*',
        should  => sub { @_ > 0 },
        because => '...ignored...',
        each    => sub {
            my ($hash1, $array, $hash2);
            shift->(
                on      => "//$hash1/$array/$hash2", # TODO: '/$hash1/$array/$hash2'
                should  => sub {
                    push @examined_values, $_[0];
                    return $_[0] > 0;
                },
                because => '...ignored...',
            );
        },
    );
    ok $v->is_valid;
    is_deeply \@examined_values, [5, 7],
        "examined values, retrieved via lables are correct";
};


done_testing;
