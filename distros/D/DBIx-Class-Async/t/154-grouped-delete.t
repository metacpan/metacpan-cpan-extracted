#!/usr/bin/env perl

# delete() on a ResultSet that has group_by and/or having attributes must
# not generate a DELETE ... WHERE id IN (SELECT ... HAVING ...) subquery
# with the GROUP BY stripped, which most databases reject.
#
# DBIx::Class::Async fixes this by routing such deletes through delete_all()
# (fetch PKs first via search, then DELETE WHERE pk IN (...)).  The tests
# here verify:
#
#   1. delete() on a grouped RS (group_by + having) completes successfully
#      and only removes the rows that match the HAVING filter.
#   2. delete() on a RS with only group_by (no having) also routes safely.
#   3. delete() on a plain (ungrouped) RS still works, regression guard.
#   4. delete() on a RS with rows (LIMIT) routes safely.
#   5. delete() on a RS with join routes safely.
#
# Note: having without group_by is invalid SQL on SQLite and most databases
# and is not a supported use case, it is intentionally not tested.

use strict;
use warnings;

use File::Temp;
use Test::More;
use Test::Exception;

use lib 't/lib';

use TestSchema;
use IO::Async::Loop;
use DBIx::Class::Async::Schema;

my $loop           = IO::Async::Loop->new;
my ($fh, $db_file) = File::Temp::tempfile(UNLINK => 1);

my $schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$db_file", undef, undef, {},
    {
        workers      => 2,
        schema_class => 'TestSchema',
        async_loop   => $loop,
        cache_ttl    => 0,
    },
);

$schema->await($schema->deploy({ add_drop_table => 1 }));

# Helper: create a fresh, known set of users and return their ids.
#
# We always start from a clean slate so tests don't interfere with each other,

my $seq = 0; # monotonic counter to keep emails unique across subtests

sub _seed_users {
    my (@specs) = @_;

    # Wipe whatever is there
    $schema->await(
        $schema->resultset('User')->search({})->delete_all
    );

    my @rows;
    for my $spec (@specs) {
        $seq++;
        my $row = $schema->await(
            $schema->resultset('User')->create({
                name   => $spec->{name},
                email  => "u${seq}\@test.example",
                active => $spec->{active},
            })
        );
        push @rows, $row;
    }
    return @rows;
}

subtest 'delete() with group_by and having removes only matching rows' => sub {
    _seed_users(
        { name => 'Alice', active => 1 },
        { name => 'Bob',   active => 1 },
        { name => 'Carol', active => 0 },
    );

    # Sanity: confirm the plain search finds the two active users
    my $active = $schema->await(
        $schema->resultset('User')->search({ active => 1 })->all
    );
    is( scalar @$active, 2, 'Sanity: two active users exist before delete' );

    # The delete RS uses group_by + having expressed as literal SQL.
    # SQL::Abstract's hashref HAVING translation is unreliable across
    # DBD drivers, so we use \[] to pass the condition directly.
    # Semantics: delete the active=1 group only when it has >= 2 members
    # (Alice and Bob), leaving Carol (active=0) untouched.
    my $del_rs = $schema->resultset('User')->search(
        { active => 1 },
        {
            group_by => [ 'active' ],
            having   => \[ 'count(id) >= ?', 2 ],
        }
    );

    lives_ok(
        sub { $schema->await($del_rs->delete) },
        'delete() on grouped RS with HAVING does not die (RT#107251)'
    );

    my $remaining = $schema->await(
        $schema->resultset('User')->search({})->all
    );
    is( scalar @$remaining, 1,          'One user remains after grouped delete'  );
    is( $remaining->[0]->name, 'Carol', 'Surviving user is Carol (active=0)'     );
};

subtest 'delete() with only group_by routes safely' => sub {
    _seed_users(
        { name => 'Dave', active => 1 },
        { name => 'Eve',  active => 0 },
    );

    my $del_rs = $schema->resultset('User')->search(
        { active   => 1 },
        { group_by => [ 'active' ] }
    );

    lives_ok(
        sub { $schema->await($del_rs->delete) },
        'delete() with only group_by does not die'
    );

    my $remaining = $schema->await(
        $schema->resultset('User')->search({})->all
    );
    is( scalar @$remaining, 1, 'One user remains after group_by-only delete' );
    is( $remaining->[0]->name, 'Eve', 'Surviving user is Eve (active=0)' );
};

subtest 'delete() without group_by/having still works (regression guard)' => sub {
    _seed_users(
        { name => 'Heidi', active => 1 },
        { name => 'Ivan',  active => 1 },
        { name => 'Judy',  active => 0 },
    );

    lives_ok(
        sub {
            $schema->await(
                $schema->resultset('User')->search({ active => 1 })->delete
            );
        },
        'plain delete() does not die'
    );

    my $remaining = $schema->await(
        $schema->resultset('User')->search({})->all
    );
    is( scalar @$remaining, 1,         'One user remains after plain delete' );
    is( $remaining->[0]->name, 'Judy', 'Surviving user is Judy (active=0)' );
};

subtest 'delete() with rows attribute routes safely' => sub {
    my @rows = _seed_users(
        { name => 'Karl',  active => 1 },
        { name => 'Linda', active => 1 },
        { name => 'Mallory', active => 1 },
    );

    # Only delete the first 2 (ordered by id to make it deterministic)
    my $del_rs = $schema->resultset('User')->search(
        { active   => 1 },
        { order_by => 'id', rows => 2 }
    );

    lives_ok(
        sub { $schema->await($del_rs->delete) },
        'delete() with rows attribute does not die'
    );

    my $remaining = $schema->await(
        $schema->resultset('User')->search({})->all
    );
    is( scalar @$remaining, 1, 'One user remains after limited delete' );
    is( $remaining->[0]->name, 'Mallory', 'The third user (Mallory) survived' );
};

subtest 'delete() with join attribute routes safely' => sub {
    _seed_users(
        { name => 'Niaj',  active => 1 },
        { name => 'Olivia', active => 0 },
    );

    # join without a real condition on the joined table, just verify routing
    my $del_rs = $schema->resultset('User')->search(
        { 'me.active' => 1 },
        { join        => 'orders' }
    );

    lives_ok(
        sub { $schema->await($del_rs->delete) },
        'delete() with join attribute does not die'
    );

    my $remaining = $schema->await(
        $schema->resultset('User')->search({})->all
    );
    is( scalar @$remaining, 1,           'One user remains after join delete' );
    is( $remaining->[0]->name, 'Olivia', 'Olivia (active=0) survived' );
};

$schema->disconnect;

done_testing;
