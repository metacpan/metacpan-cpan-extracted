use strict;
use warnings;
use lib 't/lib';
use Test::More;
use Test::Fatal;
use My::Schema;

unless (eval { require DBD::SQLite; 1 }) {
    plan skip_all => 'Unable to load DBD::SQLite';
}

my $schema = My::Schema->connect('dbi:SQLite:dbname=:memory:');

$schema->deploy;

my $people = $schema->resultset('Person');

my $bob = $people->create({
    name => 'Bob Testuser',
});

$bob->create_related(assigned_tasks => {
    summary => 'Task A',
    urgency => 10,
});
$bob->create_related(assigned_tasks => {
    summary => 'Task B',
    urgency => 20,
});
$bob->create_related(assigned_tasks => {
    summary => 'Task C',
    urgency => 30,
});

subtest 'has_many' => sub {

    my $join_with_min = sub {
        return shift->with_parameterized_join(
            urgent_assigned_tasks => { urgency_threshold => $_[0] },
        );
    };

    my $join_with_range = sub {
        return shift->with_parameterized_join(
            tasks_in_urgency_range => {
                min => $_[0],
                max => $_[1],
            },
        );
    };

    my $search_count = sub {
        return scalar shift->search(
            { 'me.name' => { -like => 'Bob%' } },
            {
                '+select' => [{
                    count => \[shift],
                }],
                '+as' => ['task_count'],
            },
        );
    };
    my $search = sub { $search_count->(shift, 'urgent_assigned_tasks.id') };

    my $fetch_count = sub {
        return shift->next->get_column('task_count');
    };

    subtest 'simple filter' => sub {
        is $people->$join_with_min(19)->$search->$fetch_count,
            2, 'filter min 19';
        is $people->$join_with_min(29)->$search->$fetch_count,
            1, 'filter min 29';
        is $people->$join_with_min(39)->$search->$fetch_count,
            0, 'filter min 39';
    };

    subtest 'multiple filters' => sub {
        my $rs1 = $people->$join_with_min(19)->$search;
        my $rs2 = $people->$join_with_min(29)->$search;
        is $rs1->$fetch_count, 2, 'first';
        is $rs2->$fetch_count, 1, 'second';
    };

    subtest 'overrides' => sub {
        like exception {
            $people
                ->$join_with_min(19)
                ->$join_with_min(29)
                ->$search
                ->$fetch_count;
        }, qr{once.+per.+relation}i, 'throws error';
    };

    subtest 'multi parameter' => sub {
        my $search = sub {
            $search_count->(shift, 'tasks_in_urgency_range.id');
        };
        is $people->$join_with_range(10, 30)->$search->$fetch_count,
            3, 'full range';
    };

    subtest 'multi join' => sub {
        is $people
            ->$join_with_min(19)
            ->$join_with_range(10, 30)
            ->$search
            ->$fetch_count,
            2*3, 'full count';
    };

    subtest 'unconstrained' => sub {
        is $people
            ->with_parameterized_join(unconstrained_tasks => {})
            ->$search_count('unconstrained_tasks.id')
            ->$fetch_count,
            3, 'unconstrained count';
    };

    subtest 'errors' => sub {
        like exception {
            $people->with_parameterized_join(urgent_assigned_tasks => {})
                ->$search
                ->$fetch_count;
        }, qr{urgent_assigned_tasks.+urgency_threshold}, 'missing parameter';
        like exception {
            $people->with_parameterized_join(__invalid__ => {})
                ->$search
                ->$fetch_count;
        }, qr{__invalid__}, 'unknown relation';
        like exception {
            $people->with_parameterized_join(undef, {});
        }, qr{relation.+name}i, 'missing relation name';
        like exception {
            $people->with_parameterized_join(foo => []);
        }, qr{parameters.+hash.+not.+ARRAY}i, 'invalid parameters';
        like exception {
            $people->with_parameterized_join(foo => 23);
        }, qr{parameters.+hash.+not.+non-reference}i, 'non ref parameters';
    };

    subtest 'declaration errors' => sub {
        my $errors = \%My::Schema::Result::Person::ERROR;
        like delete $errors->{no_args}, qr{Missing.+relation.+name}i,
            'no arguments';
        like delete $errors->{no_source}, qr{Missing.+foreign.+source}i,
            'no foreign source';
        like delete $errors->{no_cond}, qr{Condition.+non-ref.+value}i,
            'no condition';
        like delete $errors->{invalid_cond}, qr{Condition.+SCALAR}i,
            'invalid condition';
        like delete $errors->{undef_args}, qr{Arguments.+array.+non-ref}i,
            'undef args';
        like delete $errors->{invalid_args}, qr{Arguments.+array.+SCALAR}i,
            'invalid args';
        like delete $errors->{undef_builder}, qr{builder.+code.+non-ref}i,
            'undef builder';
        like delete $errors->{invalid_builder}, qr{builder.+code.+ARRAY}i,
            'invalid builder';
        is_deeply $errors, {}, 'no more errors';
    };
};

done_testing;
