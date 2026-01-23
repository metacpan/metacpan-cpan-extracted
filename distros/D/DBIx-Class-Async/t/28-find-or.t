#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Future;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use lib 't/lib';
use lib 'lib';
use TestSchema;
use DBIx::Class::Async::Schema;

my $dbfile = 't/test_find_or.db';
unlink $dbfile if -e $dbfile;

my $schema = TestSchema->connect("dbi:SQLite:dbname=$dbfile", undef, undef, { RaiseError => 1 });
$schema->deploy;

my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

$schema->resultset('User')->create({
    name   => "ExistingUser",
    email  => "existing\@example.com",
    active => 1,
});

my $rs = $async_schema->resultset('User');


subtest 'find_or_new logic' => sub {
    my $user_a = $rs->find_or_new({ name => 'ExistingUser' })->get;

    isa_ok($user_a, 'DBIx::Class::Async::Row::User');
    is($user_a->email, 'existing@example.com', 'Found existing record data');
    ok($user_a->in_storage, 'Existing record is flagged as in_storage');

    my $user_b = $rs->find_or_new({ name => 'BrandNew', email => 'new@example.com' })->get;
    is($user_b->name, 'BrandNew', 'Instantiated new object');
    ok(!$user_b->in_storage, 'New object is NOT in storage');
};

subtest 'find_or_new with ResultSet conditions' => sub {
    # If the ResultSet is restricted (e.g. active => 1),
    # find_or_new should include that in the new object.
    my $active_rs = $rs->search({ 'me.active' => 1 });

    my $user = $active_rs->find_or_new({ name => 'ConstrainedUser' })->get;

    is($user->active, 1, 'Correctly merged "me.active" into the new result object');
    ok(!$user->in_storage, 'Object ready for manual insertion');
};

subtest 'Unique Constraint handling' => sub {
    $schema->resultset('User')->delete_all;
    $schema->resultset('User')->create({
        name  => "ExistingUser",
        email => 'existing@example.com',
    });

    my $f = $rs->find_or_create(
        { email => 'existing@example.com', name => 'DuplicateEmail' },
        { key   => 'user_email' }
    );

    my $user = $f->get;
    is($user->name, 'ExistingUser', 'Matched existing record');
    is($schema->resultset('User')->count, 1, 'No duplicate record created');
};

subtest 'find_or_create race condition' => sub {
    my $email = 'race_recovery@example.com';

    # 1. PRE-INSERT the "Winner" via sync schema to create the conflict
    $schema->resultset('User')->create({ name => 'Winner', email => $email });

    # 2. Call find_or_create.
    #    - Its internal 'find' will see nothing (if it's a fresh process/cache)
    #    - Its 'create' will fail due to the sync insert above
    #    - Its 'catch' will recover.
    my $f = $rs->find_or_create(
        { name => 'Loser', email => $email },
        { key  => 'user_email' }
    );

    my $user;
    eval { $user = $f->get; };

    if ($@) {
        fail("find_or_create died: $@");
    } else {
        ok($user, "Got a user object back from recovery");
        is($user->name, 'Winner', 'Correctly ignored "Loser" and recovered "Winner"');
    }
};

done_testing();

END {
    unlink $dbfile if -e $dbfile;
}
