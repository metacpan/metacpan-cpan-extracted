# t/06-truncate.t
use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);

use TestSchema;
use DBIx::Class::MockData;

my $SCHEMA_DIR = 't/lib';

# Helper to create a fresh database with data
sub setup_test_db {
    my ($rows) = @_;
    $rows //= 3;

    my (undef, $db_file) = tempfile(SUFFIX => '.db', UNLINK => 1);
    my $schema = TestSchema->connect("dbi:SQLite:dbname=$db_file");

    my $mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => $rows,
        seed       => 42,
    );

    $mock->deploy->generate;

    return ($schema, $db_file, $mock);
}

# Test truncate basic functionality
subtest 'truncate empties tables but preserves structure' => sub {
    my ($schema, $db_file, $mock) = setup_test_db(5);

    # Verify data exists
    is $schema->resultset('Author')->count, 5, '5 authors before truncate';
    is $schema->resultset('Book')->count,   5, '5 books before truncate';
    is $schema->resultset('Review')->count, 5, '5 reviews before truncate';

    # Truncate
    lives_ok { $mock->truncate } 'truncate lives';

    # Verify data is gone
    is $schema->resultset('Author')->count, 0, '0 authors after truncate';
    is $schema->resultset('Book')->count,   0, '0 books after truncate';
    is $schema->resultset('Review')->count, 0, '0 reviews after truncate';

    # Verify we can still insert new data
    # Note: We need a fresh mock for generate because the old one might have
    # cached state that expects the old salt pattern
    my $new_mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => 5,
        seed       => 42,
    );

    lives_ok { $new_mock->generate } 'generate after truncate lives';
    is $schema->resultset('Author')->count, 5, '5 authors after regenerate';
};

# Test truncate with only/exclude filters
subtest 'truncate respects only/exclude filters' => sub {
    my ($schema, $db_file, $mock) = setup_test_db(3);

    # Create a new mock with only filter
    my $mock_only = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        only       => ['Author'],
    );

    # Truncate only Author table
    lives_ok { $mock_only->truncate } 'truncate with only filter lives';

    # Verify only Author was truncated
    is $schema->resultset('Author')->count, 0, 'authors truncated';
    is $schema->resultset('Book')->count,   3, 'books preserved';
    is $schema->resultset('Review')->count, 3, 'reviews preserved';

    # Create a new mock with exclude filter
    my $mock_exclude = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        exclude    => ['Book'],
    );

    # First, clear all data to start fresh
    $mock->truncate;  # Use the original mock to truncate everything

    # Now insert fresh data using a mock with a different seed
    my $fresh_mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => 3,
        seed       => 44,  # Different seed to get fresh data
    );
    $fresh_mock->generate;

    # Verify we have exactly 3 rows in each table
    is $schema->resultset('Author')->count, 3, '3 authors before exclude truncate';
    is $schema->resultset('Book')->count,   3, '3 books before exclude truncate';
    is $schema->resultset('Review')->count, 3, '3 reviews before exclude truncate';

    # Truncate excluding Book
    lives_ok { $mock_exclude->truncate } 'truncate with exclude filter lives';

    # Verify Book was preserved, others truncated
    is $schema->resultset('Author')->count, 0, 'authors truncated';
    is $schema->resultset('Book')->count,   3, 'books preserved';
    is $schema->resultset('Review')->count, 0, 'reviews truncated';
};

# Test truncate handles SQLite sequence reset gracefully
subtest 'truncate handles SQLite sequences' => sub {
    my ($schema, $db_file, $mock) = setup_test_db(2);

    # Force creation of sqlite_sequence by doing an insert that uses autoinc
    my $dbh = $schema->storage->dbh;
    $dbh->do("INSERT INTO author (first_name, last_name, email) VALUES (?, ?, ?)",
        {}, 'Test', 'User', 'test@example.com');

    # Now truncate should handle the sequence table
    lives_ok { $mock->truncate } 'truncate handles existing sqlite_sequence';

    # Verify we can insert again
    my $new_mock = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        rows       => 1,
        seed       => 44,
    );

    lives_ok { $new_mock->generate } 'can insert after truncate with sequence';
    is $schema->resultset('Author')->count, 1, 'one author inserted';
};

# Test truncate vs wipe warning
subtest 'wipe warns but truncate does not' => sub {
    my ($schema, $db_file, $mock) = setup_test_db(1);

    # Test wipe warning
    my $warning = '';
    local $SIG{__WARN__} = sub { $warning = $_[0] };

    $mock->wipe;
    like $warning, qr/wipe\(\) is destructive/, 'wipe issues warning';

    # Test truncate silence
    $warning = '';
    $mock->truncate;
    is $warning, '', 'truncate issues no warning';

    # Test wipe with quiet flag
    my $mock_quiet = DBIx::Class::MockData->new(
        schema     => $schema,
        schema_dir => $SCHEMA_DIR,
        quiet      => 1,
    );

    $warning = '';
    $mock_quiet->wipe;
    is $warning, '', 'wipe with quiet flag suppresses warning';
};

done_testing;
