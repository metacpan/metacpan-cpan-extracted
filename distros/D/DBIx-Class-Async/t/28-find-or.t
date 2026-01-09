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
    name  => "ExistingUser",
    email => "existing\@example.com",
    active => 1,
});

my $rs = $async_schema->resultset('User');

# TEST: find_or_new

subtest 'find_or_new logic' => sub {
    my $user_a = $rs->find_or_new({ name => 'ExistingUser' })->get;

    # FIX: Use the class name returned by the system or a more generic check
    isa_ok($user_a, 'DBIx::Class::Async::Row::User');
    is($user_a->email, 'existing@example.com', 'Found existing record data');
    ok($user_a->in_storage, 'Existing record is flagged as in_storage');

    my $user_b = $rs->find_or_new({ name => 'BrandNew', email => 'new@example.com' })->get;
    is($user_b->name, 'BrandNew', 'Instantiated new object');
    ok(!$user_b->in_storage, 'New object is NOT in storage');
};

# TEST: Unique Constraint handling

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

done_testing();

END {
    unlink $dbfile if -e $dbfile;
}
