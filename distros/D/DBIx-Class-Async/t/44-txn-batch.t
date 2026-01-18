use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use lib 'lib', 't/lib';

use TestSchema;
use DBIx::Class::Async;

# 1. Create a temporary file for the database
my (undef, $db_file) = tempfile(UNLINK => 1);
my $dsn = "dbi:SQLite:dbname=$db_file";

# 2. Setup/Deploy the schema
my $schema = TestSchema->connect($dsn);
$schema->deploy();

# 3. Initialize the Async wrapper
my $async_db = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => [ $dsn, '', '' ],
    workers      => 1,
);

# 4. Pre-seed a user
my $seed = $schema->resultset('User')->create({
    name  => 'Original Name',
    email => 'original@test.com'
});
my $user_id = $seed->id;

subtest "Successful txn_batch" => sub {
    my @batch = (
        {
            type      => 'create',
            resultset => 'User',
            data      => { name => 'New Batch User', email => 'batch@test.com' }
        },
        {
            type      => 'update',
            resultset => 'User',
            id        => $user_id,
            data      => { name => 'Updated Name' }
        }
    );

    # Use the internal _call_worker to trigger your txn_batch logic
    my $future = $async_db->_call_worker('txn_batch', \@batch);

    # Block until done (since it's a test)
    my $count = $future->get;

    is($count, 2, "Both operations in batch reported success");

    # Verify via the local schema
    my $updated = $schema->resultset('User')->find($user_id);
    is($updated->name, 'Updated Name', "Update persisted");

    my $new_user = $schema->resultset('User')->find({ email => 'batch@test.com' });
    ok($new_user, "Create persisted");
};

done_testing();
