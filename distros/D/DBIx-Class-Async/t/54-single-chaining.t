
use strict;
use warnings;
use Test::More;
use lib 'lib', 't/lib';
use File::Temp qw(tempfile);

use TestSchema;
use DBIx::Class::Async;

# 1. Create a temporary file for the database
my (undef, $db_file) = tempfile(UNLINK => 1);
my $dsn = "dbi:SQLite:dbname=$db_file";

# 2. Setup Bridge
my $async = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => [ $dsn, '', '' ],
);

# 3. Setup Metadata & Deploy (USE THE SAME DSN)
my $schema = $async->{_metadata_schema} = $async->{schema_class}->connect($dsn);
$schema->deploy;

# 4. Create seed data
$schema->resultset('User')->create({ name => 'User A', active => 0, id => 1 });
$schema->resultset('User')->create({ name => 'User B', active => 1, id => 2 });

subtest 'single_future preserves conditions' => sub {
    my $rs = $async->resultset('User');

    # 1. FIX: Use 'active' instead of 'status'
    my $future = $rs->search({ active => 1 })->single_future;

    my $user = $future->get;

    ok($user, "Got a user");
    is($user->name, 'User B', "Correct user returned (filter was respected)");

    # 2. FIX: Use the method that matches your column (likely 'active')
    is($user->active, 1, "Active column matches filter");

    # Negative test: search for something that doesn't exist
    my $none = $rs->search({ name => 'NonExistent' })->single_future->get;
    is($none, undef, "Returns undef when search condition matches nothing");
};

subtest 'single_future with additional criteria' => sub {
    my $rs = $async->resultset('User');

    # Start with all users, but find a specific one via single_future
    # If this works, it proves single_future can handle its own conditions
    my $user = $rs->single_future({ name => 'User B' })->get;

    ok($user, "Found user by name");
    is($user->id, 2, "Got correct ID");
};

subtest 'find method works via single_future' => sub {
    my $rs = $async->resultset('User');

    # Test finding by ID directly
    my $user = $rs->find(2)->get;

    ok($user, "find(2) returned a user");
    is($user->name, 'User B', "Found the correct user by ID");
};

done_testing();
