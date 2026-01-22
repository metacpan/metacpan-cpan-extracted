use strict;
use warnings;
use Test::More;
use Future;
use DBIx::Class::Async::Row;

# --- Setup Mock Environment ---

{
    package Mock::Async::Broken;
    use base 'DBIx::Class::Async';
    # Simulate a database that is reachable but returning error envelopes
    sub _call_worker {
        return Future->done({ __error => "DATABASE_CRASH: Table 'users' is read-only" });
    }
    # Mock resultset to return a valid source for metadata
    sub resultset {
        my ($self, $name) = @_;
        return bless { name => $name }, 'Mock::RS';
    }
}

{
    package Mock::RS;
    sub result_source { shift }
    sub columns { qw(id name email) }
    sub primary_columns { ('id') }
    sub has_column { 1 }
    sub column_info { {} }
}

my $async = bless { }, 'Mock::Async::Broken';
my $schema = bless { }, 'DBIx::Class::Schema';

# Create a "live" row object that thinks it is in storage
my $mock_source = bless { }, 'Mock::RS';
my $row = DBIx::Class::Async::Row->new(
    schema      => $schema,
    async_db    => $async,
    source_name => 'User',
    _source     => $mock_source,
    row_data    => { id => 1, name => 'John Doe', email => 'john@example.com' },
    in_storage  => 1,
);

# --- Tests ---

subtest 'Row Update Error Handling' => sub {
    my $f = $row->update({ name => 'New Name' });

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "Row update should fail when DB returns error");
    like($err, qr/DATABASE_CRASH/, "Row propagates DB error message");

    # Verify the object didn't clear its dirty state on failure
    is($row->is_column_dirty('name'), 1, "Column remains dirty after failed update");
};

subtest 'Row Delete Error Handling' => sub {
    # Ensure it thinks it's in storage again
    $row->in_storage(1);

    my $f = $row->delete;

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "Row delete should fail when DB returns error");
    like($err, qr/DATABASE_CRASH/, "Row propagates DB error message");
    is($row->in_storage, 1, "Row remains 'in_storage' after failed delete");
};

subtest 'Row Discard Changes Error Handling' => sub {
    $row->set_column('name', 'Temporary Change');

    my $f = $row->discard_changes;

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "discard_changes should fail when DB fetch fails");
    is($row->get_column('name'), 'Temporary Change', "Data was not discarded/overwritten by error hash");
};

done_testing();
