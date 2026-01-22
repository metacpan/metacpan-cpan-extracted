#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBIx::Class::Async::Row;

# Setup Mock

my $mock_source = bless { }, 'Mock::RS';

{
    package Mock::RS;
    sub has_column {
        my ($self, $col) = @_;
        # Only 'name' is a real column
        return $col eq 'name' ? 1 : 0;
    }
    sub column_info {
        my ($self, $col) = @_;
        die "No such column '$col'" unless $col eq 'name';
        return { data_type => 'varchar' };
    }
}

my $row = DBIx::Class::Async::Row->new(
    schema      => bless({}, 'Schema'),
    async_db    => bless({}, 'DB'),
    source_name => 'User',
    _source     => $mock_source,
    row_data    => { id => 1, name => 'John' },
    in_storage  => 1,
);

subtest 'Internal Guard via get_column' => sub {
    # These should return the objects/strings directly without hitting Mock::RS
    lives_ok {
        my $db = $row->get_column('async_db');
        isa_ok($db, 'DB');
    } 'get_column returns internal async_db object';

    lives_ok {
        my $map = $row->get_column('_inflation_map');
        ref_ok($map, 'HASH');
    } 'get_column returns internal _inflation_map';

    # This SHOULD fail because 'secret_key' isn't internal OR in the schema
    throws_ok {
        $row->get_column('secret_key');
    } qr/No such column 'secret_key'/, 'Non-internal invalid column still throws error';
};

subtest 'Protection against Overwriting Plumbing' => sub {
    # Attempt to "hack" the row by overwriting the DB connection
    $row->set_column('async_db', 'MALICIOUS_STRING');

    # If the guard works, 'async_db' remains an object, not the string
    isnt($row->{async_db}, 'MALICIOUS_STRING', "set_column must not overwrite the actual plumbing key");

    # Verify it didn't mark the row as dirty for a database update
    my %dirty = $row->get_dirty_columns;
    ok(!exists $dirty{async_db}, "Internal keys should never be marked as dirty/sent to DB");
};

subtest 'Regex Boundary Check' => sub {
    # Check that it doesn't over-match.
    # A column named 'name_source' (contains 'source') should still be treated as a column
    $row->{_data}{name_source} = 'Direct';
    lives_ok {
        $row->get_column('name_source');
    } 'Regex does not over-match columns containing internal keywords';
};

done_testing;

sub ref_ok {
    my ($val, $type) = @_;
    ok(ref $val eq $type, "Value is a $type reference") or diag("Found: " . ref $val);
}
