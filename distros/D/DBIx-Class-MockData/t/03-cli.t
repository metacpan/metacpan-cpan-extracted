#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';

use Test::More;
use Test::Exception;

use JSON;
use File::Spec;
use Symbol qw(gensym);
use IPC::Open3 qw(open3);
use File::Temp qw(tempfile);

#
#
# Helpers

my $PERL       = $^X;
my $SCRIPT     = File::Spec->catfile('script', 'dbic-mockdata');
my $SCHEMA_DIR = 't/lib';
my $NAMESPACE  = 'TestSchema';

# Run the CLI script, return (stdout, stderr, exit_code).
sub run_cli {
    my (@args) = @_;

    my ($out, $err) = ('', '');
    my $err_fh = gensym;

    my $pid = open3(my $in, my $out_fh, $err_fh,
        $PERL, '-Ilib', '-Iblib/lib', $SCRIPT, @args);

    close $in;
    $out .= $_ while <$out_fh>;
    $err .= $_ while <$err_fh>;
    waitpid($pid, 0);

    my $exit = $? >> 8;
    return ($out, $err, $exit);
}

# Return a fresh temp SQLite file (auto-deleted at process exit).
sub temp_db {
    my (undef, $path) = tempfile(SUFFIX => '.db', UNLINK => 1);
    return $path;
}

# Common args used by most subtests -- must be an array, not a scalar.
my @base_args = (
    '--schema-dir', $SCHEMA_DIR,
    '--namespace',  $NAMESPACE,
);

subtest 'missing --schema-dir exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli('--namespace', $NAMESPACE, '--dry-run');
    isnt $exit, 0, 'exits with non-zero status';
    like $err, qr/schema-dir.*required/i, 'error mentions --schema-dir';
};

subtest 'missing --namespace exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli('--schema-dir', $SCHEMA_DIR, '--dry-run');
    isnt $exit, 0, 'exits with non-zero status';
    like $err, qr/namespace.*required/i, 'error mentions --namespace';
};

subtest 'missing --dsn (without --dry-run) exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(@base_args);
    isnt $exit, 0, 'exits with non-zero status';
    like $err, qr/dsn.*required/i, 'error mentions --dsn';
};

subtest '--dry-run prints output without a DSN' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--rows', 2,
    );
    is   $exit, 0,                    'exits zero';
    like $out,  qr/DRY RUN/,         'stdout contains DRY RUN';
    like $out,  qr/Author|Book/i,     'stdout mentions a result source';
};

subtest '--dry-run shows expected number of rows' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--rows', 3,
    );
    is $exit, 0, 'exits zero';
    my @row_lines = ($out =~ /Row \d+:/g);
    # 3 sources x 3 rows = 9 Row lines
    is scalar(@row_lines), 9, '9 Row lines (3 sources x 3 rows)';
};

subtest '--deploy creates tables and inserts rows' => sub {
    my $db   = temp_db();
    my $dsn  = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--seed',   42,
    );
    is   $exit, 0,          'exits zero';
    like $out,  qr/\[INFO\]/, 'stdout has INFO lines';

    # Verify rows in DB directly
    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    for my $table (qw(author book review)) {
        my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM $table");
        is $count, 2, "2 rows in $table";
    }
    $dbh->disconnect;
};

subtest '--wipe resets then inserts' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    # First pass: deploy + 3 rows
    run_cli(@base_args, '--dsn', $dsn, '--deploy', '--rows', 3, '--seed', 1);

    # Second pass: wipe + 2 rows
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',  $dsn,
        '--wipe',
        '--rows', 2,
        '--seed', 2,
    );
    is $exit, 0, 'exits zero after wipe';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    is $count, 2, 'exactly 2 authors after wipe (old 3 rows gone)';
    $dbh->disconnect;
};

subtest '--seed produces reproducible rows' => sub {
    my $db1 = temp_db();
    my $db2 = temp_db();

    for my $db ($db1, $db2) {
        run_cli(@base_args, '--dsn', "dbi:SQLite:dbname=$db",
                '--deploy', '--rows', 3, '--seed', 99);
    }

    require DBI;
    my $emails1 = DBI->connect("dbi:SQLite:dbname=$db1", '', '', {RaiseError=>1})
                     ->selectcol_arrayref('SELECT email FROM author ORDER BY email');
    my $emails2 = DBI->connect("dbi:SQLite:dbname=$db2", '', '', {RaiseError=>1})
                     ->selectcol_arrayref('SELECT email FROM author ORDER BY email');

    is_deeply $emails1, $emails2, 'same seed yields identical author emails';
};

subtest '--help exits zero and prints usage' => sub {
    my ($out, $err, $exit) = run_cli('--help');
    is   $exit, 0,           'exits zero';
    like $out,  qr/SYNOPSIS|OPTIONS|dbic-mockdata/i, 'usage text in stdout';
};

subtest 'unknown DBI driver exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn', 'dbi:NoSuchDriver:dbname=test',
        '--deploy',
    );
    isnt $exit, 0, 'exits non-zero for unknown DBI driver';
};

subtest '--only populates only listed tables' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--only',   'Author',
        '--rows',   2,
    );
    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 2, '2 authors inserted';
    is $books,   0, 'no books inserted';
    is $reviews, 0, 'no reviews inserted';
    $dbh->disconnect;
};

subtest '--only with multiple tables (comma-separated)' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(@base_args, '--dsn', $dsn, '--deploy', '--only', 'Author,Book', '--rows', 2);

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 2, '2 authors inserted';
    is $books,   2, '2 books inserted';
    is $reviews, 0, 'no reviews inserted';
    $dbh->disconnect;
};

subtest '--only with unknown table exits non-zero' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--only',   'NoSuchTable',
    );
    isnt $exit, 0, 'exits non-zero for unknown table in --only';
    like $err, qr/Unknown source|NoSuchTable/i, 'error mentions unknown source';
};

subtest '--exclude skips listed table' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(@base_args, '--dsn', $dsn, '--deploy', '--exclude', 'Review', '--rows', 2);

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 2, '2 authors inserted';
    is $books,   2, '2 books inserted';
    is $reviews, 0, 'review skipped';
    $dbh->disconnect;
};

subtest '--exclude with multiple tables (comma-separated)' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(@base_args, '--dsn', $dsn, '--deploy', '--exclude', 'Book,Review', '--rows', 2);

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 2, '2 authors inserted';
    is $books,   0, 'book skipped';
    is $reviews, 0, 'review skipped';
    $dbh->disconnect;
};

subtest '--exclude with unknown table exits non-zero' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',     $dsn,
        '--deploy',
        '--exclude', 'GhostTable',
    );
    isnt $exit, 0, 'exits non-zero for unknown table in --exclude';
    like $err, qr/Unknown source|GhostTable/i, 'error mentions unknown source';
};

subtest '--only and --exclude together exit non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--only',    'Author',
        '--exclude', 'Review',
    );
    isnt $exit, 0, 'exits non-zero when both --only and --exclude supplied';
    like $err, qr/only.*exclude|exclude.*only/i, 'error mentions the conflict';
};

subtest '--rows-per-table with JSON overrides' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--rows-per-table', '{"Author":5}',
    );
    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 5, '5 authors inserted (override)';
    is $books,   2, '2 books inserted (global default)';
    is $reviews, 2, '2 reviews inserted (global default)';
    $dbh->disconnect;
};

subtest '--rows-per-table with multiple overrides' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--rows-per-table', '{"Author":10,"Book":3}',
    );

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($authors) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my ($books)   = $dbh->selectrow_array('SELECT COUNT(*) FROM book');
    my ($reviews) = $dbh->selectrow_array('SELECT COUNT(*) FROM review');
    is $authors, 10, '10 authors inserted';
    is $books,   3,  '3 books inserted';
    is $reviews, 2,  '2 reviews inserted (global default)';
    $dbh->disconnect;
};

subtest '--rows-per-table with invalid JSON exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--rows-per-table', '{Author:10}',
    );
    isnt $exit, 0, 'exits non-zero for invalid JSON';
    like $err, qr/Invalid JSON/i, 'error mentions JSON parsing failure';
};

subtest '--generators with static values (unique-aware)' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--generators', '{"email":"static{row}@example.com"}',
    );

    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

    my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM author");
    is $count, 2, '2 authors inserted';

    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY id');

    like $emails->[0], qr/static\d+\@example\.com/, 'email format correct';
    isnt $emails->[0], $emails->[1], 'emails are unique';

    $dbh->disconnect;
};

subtest '--generators with {row} interpolation' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   3,
        '--generators', '{"email":"user{row}@example.com"}',
    );

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY email');

    like $emails->[0], qr/user\d+\@example\.com/, 'email format correct';

    # Verify they're different per row
    isnt $emails->[0], $emails->[1], 'different emails for different rows';
    $dbh->disconnect;
};

subtest '--generators with simple Perl code' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my $generators_json = '{"email":"sub { return \"user\" . $_[2] . \"\\\@example.com\"; }"}';

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--generators', $generators_json,
    );

    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY id');

    like $emails->[0], qr/user\d+\@example\.com/, 'email format correct';

    $dbh->disconnect;
};

subtest '--generators with template approach (recommended)' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    # For simple cases, use the {row} template instead of Perl code
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--generators', '{"email":"user{row}@example.com"}',
    );

    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY id');

    like $emails->[0], qr/user\d+\@example\.com/, 'email format correct';
    is $emails->[0], 'user1@example.com', 'first email uses row 1';
    is $emails->[1], 'user2@example.com', 'second email uses row 2';

    $dbh->disconnect;
};

subtest '--generators with non-unique static values should warn but continue' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--generators', '{"email":"static@example.com"}',
    );

    # The script warns but exits 0 (continues with other tables)
    is $exit, 0, 'exits zero (warns but continues)';
    like $err, qr/UNIQUE constraint failed/, 'error mentions unique constraint';
    like $err, qr/\[WARN\] Bulk insert failed/, 'warning is issued';

    # Verify that other tables were still inserted successfully
    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

    # Author table should have 0 rows (all inserts failed due to unique constraint)
    my ($author_count) = $dbh->selectrow_array("SELECT COUNT(*) FROM author");
    is $author_count, 0, 'author table has 0 rows (all inserts failed)';

    # Book table should have 2 rows (successful)
    my ($book_count) = $dbh->selectrow_array("SELECT COUNT(*) FROM book");
    is $book_count, 2, 'books still inserted successfully';

    # Review table should have 2 rows (successful)
    my ($review_count) = $dbh->selectrow_array("SELECT COUNT(*) FROM review");
    is $review_count, 2, 'reviews still inserted successfully';

    $dbh->disconnect;
};

subtest '--generators with explicit uniqueness' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    my $generators_json = '{"email":"sub { my ($col,$info,$n,$mock)=@_; return \"user$n\\\@example.com\"; }"}';

    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   3,
        '--generators', $generators_json,
    );

    is $exit, 0, 'exits zero';

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });

    my ($count) = $dbh->selectrow_array("SELECT COUNT(*) FROM author");
    is $count, 3, '3 authors inserted';

    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY id');

    like $emails->[0], qr/user\d+\@example\.com/, 'email format correct';
    is $emails->[0], 'user1@example.com', 'first email uses row 1';
    is $emails->[1], 'user2@example.com', 'second email uses row 2';
    is $emails->[2], 'user3@example.com', 'third email uses row 3';

    $dbh->disconnect;
};

subtest '--generators with invalid JSON exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--generators', '{email:user@example.com}',
    );
    isnt $exit, 0, 'exits non-zero for invalid JSON';
    like $err, qr/Invalid JSON/i, 'error mentions JSON parsing failure';
};

subtest '--generators with invalid Perl code exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dry-run',
        '--generators', '{"email":"sub { syntax error here }"}',
    );
    isnt $exit, 0, 'exits non-zero for invalid Perl code';
    like $err, qr/Invalid Perl code/i, 'error mentions Perl code failure';
};

subtest '--rows-per-table with --generators works together' => sub {
    my $db  = temp_db();
    my $dsn = "dbi:SQLite:dbname=$db";

    run_cli(
        @base_args,
        '--dsn',    $dsn,
        '--deploy',
        '--rows',   2,
        '--rows-per-table', '{"Author":3}',
        '--generators', '{"email":"custom{row}@test.com"}',
    );

    require DBI;
    my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
    my ($author_count) = $dbh->selectrow_array('SELECT COUNT(*) FROM author');
    my $emails = $dbh->selectcol_arrayref('SELECT email FROM author ORDER BY email');

    is $author_count, 3, '3 authors inserted (override)';
    like $emails->[0], qr/custom\d+\@test\.com/, 'email generator applied';
    $dbh->disconnect;
};

done_testing;
