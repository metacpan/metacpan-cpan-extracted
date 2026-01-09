#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Future;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required for testing';
}

use lib 'lib';
use lib 't/lib';
use TestSchema;
use DBIx::Class::Async::Schema;

# 1. Setup test database
my $dbfile = 't/test_update_or.db';
unlink $dbfile if -e $dbfile;

# 2. Create and deploy schema
my $schema = TestSchema->connect(
    "dbi:SQLite:dbname=$dbfile", undef, undef, { RaiseError => 1 });
$schema->deploy;

# 3. Create async schema
my $async_schema = DBIx::Class::Async::Schema->connect(
    "dbi:SQLite:dbname=$dbfile",
    undef,
    undef,
    { sqlite_unicode => 1 },
    { workers => 2, schema_class => 'TestSchema' }
);

# 4. Declare $rs so it is available for the subtests
my $rs = $async_schema->resultset('User');

# TEST: update_or_create logic

subtest 'update_or_create logic' => sub {
    $schema->resultset('User')->delete_all;

    # Setup initial user
    $schema->resultset('User')->create({
        name  => "Old Name",
        email => 'upsert@example.com',
    });

    # Execution: Update the name for that specific email
    my $f = $rs->update_or_create(
        {
            email => 'upsert@example.com',
            name  => 'New Improved Name'
        },
        { key => 'user_email' }
    );

    my $user = $f->get;

    is($user->name, 'New Improved Name', 'Record was updated successfully');
    is($schema->resultset('User')->count, 1, 'No new record was created');

    # Test the 'Create' side
    my $f2 = $rs->update_or_create({
        email => 'brandnew@example.com',
        name  => 'Fresh User'
    }, { key => 'user_email' });

    my $new_user = $f2->get;
    is($schema->resultset('User')->count, 2, 'New record created when email not found');
};

done_testing();

END {
    unlink $dbfile if -e $dbfile;
}
