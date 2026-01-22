#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use DBIx::Class::Async;

# Setup Mock environment
{
    package Mock::Source;
    sub new { bless {}, shift }
    sub primary_columns { ('id') }
    sub column_info { {} }
    sub has_column { 1 }

    package Mock::Schema;
    sub new { bless {}, shift }
    sub source { Mock::Source->new }

    package Mock::Async::Broken;
    use base 'DBIx::Class::Async';
    sub new { bless { _schema => Mock::Schema->new }, shift }
    sub _schema_instance { shift->{_schema} }

    sub _call_worker {
        my ($self, $op, $rs, $search_args) = @_;
        require Future;

        # Return success ONLY if we explicitly ask for 'John' to test inflation
        if ($op eq 'search' && ref $search_args eq 'HASH' && ($search_args->{name}||'') eq 'John') {
            return Future->done([ { id => 1, name => 'John' } ]);
        }

        # Otherwise keep the error behavior for everything else
        return Future->done({ __error => "DATABASE_CRASH_DURING_$op" });
    }
}

my $async = Mock::Async::Broken->new;

subtest 'Verify find() correctly fails on error' => sub {
    my $f = $async->find('User', 1);

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "find() Future should have failed")
        or diag("find() returned success despite DB error!");

    like($err, qr/DATABASE_CRASH/, "Error message should contain DB error details");
};

subtest 'Verify delete() correctly fails on error' => sub {
    my $f = $async->delete('User', 1);

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "delete() Future should have failed")
        or diag("delete() returned success despite DB error!");

    like($err, qr/DATABASE_CRASH/, "Error message should contain DB error details");
};

subtest 'Verify update_bulk() correctly fails on error' => sub {
    # update_bulk expects ($table, $condition, $data)
    my $f = $async->update_bulk('User', { active => 1 }, { status => 'archived' });

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "update_bulk() Future should have failed")
        or diag("LOOSE END: update_bulk() returned success despite DB error!");

    like($err, qr/DATABASE_CRASH/, "Error message should contain DB error details");
};

subtest 'Verify search() correctly fails on error' => sub {
    # search() expects ($resultset, $search_args, $attrs)
    my $f = $async->search('User', { name => 'TriggerError' });

    my $success = eval { $f->get; 1 };
    my $err = $@;

    # In the current BROKEN code:
    # 1. $success will be 1 (Future->done is called)
    # 2. $f->get will return an ArrayRef containing two "garbage" Row objects
    #    because it maps over the keys/values of the error hash.

    ok(!$success, "search() Future should have failed")
        or diag("LOOSE END: search() returned success despite DB error!");

    like($err, qr/DATABASE_CRASH/, "Error message should contain DB error details");
};

subtest 'Verify search_multi() logic and error handling' => sub {
    # 1. Test Error Propagation
    # We use our Mock::Async::Broken which returns an error for every call.
    my $f_err = $async->search_multi(
        ['User', { id => 1 }],
        ['Post', { id => 2 }]
    );

    my $success = eval { $f_err->get; 1 };
    my $err = $@;

    ok(!$success, "search_multi() should fail when worker returns an error")
        or diag("LOOSE END: search_multi() returned success despite worker error!");

    like($err, qr/DATABASE_CRASH/, "Correctly propagates the DB error message");

    # 2. Test Inflation (Conceptually)
    # Even if we fix the error handling, we need to ensure the results
    # are Row objects, not just raw HashRefs.
    # (Note: In your current code, even a 'successful' mock would return raw hashes)
};

subtest 'Verify search_multi() successfully inflates Row objects' => sub {
    # This query will match our new 'success' condition in the mock
    my $f = $async->search_multi(
        ['User', { name => 'John' }]
    );

    my @results = $f->get;

    is(scalar @results, 1, "Should return exactly 1 result set");

    my $row_set = $results[0]; # This is the ArrayRef of rows
    my $first_row = $row_set->[0];

    # This is the "Inflation" check
    isa_ok($first_row, 'DBIx::Class::Async::Row', "Individual result");
    is($first_row->get_column('name'), 'John', "Row data is preserved via get_column");

    # Verify it has the methods a Row should have
    can_ok($first_row, 'update', 'delete', 'discard_changes');
};

subtest 'Verify count() correctly fails on error' => sub {
    # count() expects ($resultset, $search_args)
    my $f = $async->count('User', { active => 1 });

    my $success = eval {
        my $count = $f->get;
        1;
    };
    my $err = $@;

    # Logic Check:
    # If broken, $success will be 1 because Future->done was called with a HashRef.
    ok(!$success, "count() Future should have failed")
        or diag("LOOSE END: count() returned a success (likely a HashRef) despite DB error!");

    like($err, qr/DATABASE_CRASH/, "Error message should contain DB error details");
};

subtest 'Verify raw_query() correctly fails on error' => sub {
    my $f = $async->raw_query('SELECT * FROM users');

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "raw_query() Future should have failed")
        or diag("LOOSE END: raw_query() returned a HashRef (success) instead of failing!");

    like($err, qr/DATABASE_CRASH/, "Propagates the raw_query error");
};

subtest 'Verify deploy() correctly fails on error' => sub {
    my $f = $async->deploy();

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "deploy() Future should have failed")
        or diag("LOOSE END: deploy() returned success despite worker error!");

    like($err, qr/DATABASE_CRASH/, "Propagates the deploy error");
};

subtest 'Verify txn_batch() correctly fails on error' => sub {
    # Send a dummy operation
    my $f = $async->txn_batch([{ type => 'raw', sql => 'DELETE FROM logs' }]);

    my $success = eval { $f->get; 1 };
    my $err = $@;

    ok(!$success, "txn_batch() Future should have failed")
        or diag("LOOSE END: txn_batch() returned success despite transaction error!");

    like($err, qr/DATABASE_CRASH/, "Propagates the transaction error");
};

done_testing;
