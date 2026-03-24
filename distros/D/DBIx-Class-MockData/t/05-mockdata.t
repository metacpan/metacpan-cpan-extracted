#!/usr/bin/env perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;
use List::Util 'uniq';

use TestSchema;
use DBIx::Class::MockData;

my $schema = TestSchema->connect('dbi:SQLite::memory:');
my $SCHEMA_DIR = 't/lib';

# Helper to get a clean slate for each subtest
sub fresh_mock {
    my (%args) = @_;
    return DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => 2, # Default low for speed
        quiet      => 1,
        %args,
    )->deploy->wipe; # Use wipe to clear data between subtests
}

subtest 'rows_per_table override' => sub {
    my $mock = fresh_mock(
        rows           => 2,
        rows_per_table => { Author => 10 }
    );

    lives_ok { $mock->generate } 'generate with rows_per_table lives';

    # Author should have 10 rows (override), others should have 2 (default)
    is $schema->resultset('Author')->count, 10, 'Author table respects rows_per_table override';
    is $schema->resultset('Book')->count,   2,  'Book table respects global rows default';
};

subtest 'custom generators' => sub {
    my $fixed_status = 'verified';

    my $mock = fresh_mock(
        rows       => 3,
        generators => {
            # For unique columns like email, we need to ensure uniqueness
            email  => sub {
                my ($col, $info, $n, $mock) = @_;
                # Use the row number to make each email unique
                return "dev${n}\@example.org";
            },
            status => sub { $fixed_status },
        }
    );

    # Wrap generate in eval to catch any errors and continue testing
    lives_ok { $mock->generate } 'generate with custom generators lives';

    # Only run these checks if we have data
    if ($schema->resultset('Author')->count > 0) {
        my $author = $schema->resultset('Author')->first;
        like $author->email, qr/^dev\d+\@example\.org$/,
            'Custom email generator value applied (with uniqueness)';

        # Check status if the column exists in your schema
        if ($author->can('status')) {
            is $author->status, $fixed_status, 'Custom status generator applied';
        } else {
            pass 'Skipping status check - column not in schema';
        }
    } else {
        fail 'No authors were inserted';
    }
};

subtest 'bulk populate efficiency' => sub {
    # This test verifies that the new bulk insert logic still maintains FK
    # integrity after the switch from ->create to ->populate
    my $mock = fresh_mock(rows => 5);

    lives_ok { $mock->generate } 'Bulk generate lives';

    my $book = $schema->resultset('Book')->first;
    ok defined($book->author_id), 'FKs are still correctly mapped after bulk populate';

    my @author_ids = $schema->resultset('Author')->get_column('id')->all;
    ok( (grep { $_ == $book->author_id } @author_ids), 'Book references valid Author ID');
};

subtest 'error handling on bulk insert failure' => sub {
    my $mock = fresh_mock();

    # We need to create a scenario where the bulk insert fails but the
    # method handles it gracefully. Let's create a duplicate unique
    # constraint violation.
    my $warning_caught = 0;
    local $SIG{__WARN__} = sub {
        # Capture the warning but don't print it
        $warning_caught = 1 if $_[0] =~ /Bulk insert failed/;
        # Silence the warning by not printing it
    };

    # First, insert one row normally
    $mock->generate;

    # Now try to insert again with the same data - this should cause a
    # unique constraint violation But we need to bypass the normal generate
    # method and call _insert_rows directly with data that will cause a
    # duplicate

    my $source = $schema->source('Author');
    my @pk_cols = $source->primary_columns;

    # Get the first author's data to create a duplicate
    my $first_author = $schema->resultset('Author')->first;
    my %duplicate_row;
    foreach my $col ($source->columns) {
        # Skip auto-increment primary key if it's the only one
        next if $col eq 'id' && @pk_cols == 1;
        $duplicate_row{$col} = $first_author->get_column($col);
    }

    # Try to insert the duplicate
    lives_ok {
        $mock->_insert_rows($source, 'Author', [\%duplicate_row], \@pk_cols, {})
    } '_insert_rows handles duplicate key failure gracefully without croaking';

    ok $warning_caught, 'Warning "[WARN] Bulk insert failed" was correctly issued';
};

subtest 'salt randomization with seed' => sub {
    # Test 1: Same seed produces identical salts (deterministic)
    {
        my $mock1 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
            seed       => 123,
        );
        my $salt1 = $mock1->{_salt};

        my $mock2 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
            seed       => 123,
        );
        my $salt2 = $mock2->{_salt};

        # With same seed, salts should be identical (deterministic)
        is $salt1, $salt2, 'Same seed produces identical salts (reproducible)';
    }

    # Test 2: Different seeds produce different salts
    {
        my $mock1 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
            seed       => 123,
        );
        my $salt1 = $mock1->{_salt};

        my $mock2 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
            seed       => 456,
        );
        my $salt2 = $mock2->{_salt};

        # Different seeds should produce different salts
        isnt $salt1, $salt2, 'Different seeds produce different salts';
    }

    # Test 3: Without seed, salts are random (different each time)
    {
        my $mock1 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
        );
        my $salt1 = $mock1->{_salt};

        my $mock2 = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
        );
        my $salt2 = $mock2->{_salt};

        # Without seed, salts should be different (random)
        isnt $salt1, $salt2, 'No seed produces random salts';
    }

    # Test 4: Verify that salts are within expected range
    {
        my $mock = DBIx::Class::MockData->new(
            schema     => $schema,
            schema_dir => $SCHEMA_DIR,
            seed       => 123,
        );
        my $salt = $mock->{_salt};

        # Salt should be between 1,000,000 and 10,000,000
        cmp_ok $salt, '>=', 1_000_000, 'Salt is at least 1,000,000';
        cmp_ok $salt, '<=', 9_999_999, 'Salt is at most 9,999,999';
    }
};

done_testing;
