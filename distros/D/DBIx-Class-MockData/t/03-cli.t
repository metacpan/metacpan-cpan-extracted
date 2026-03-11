use strict;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use IPC::Open3 qw(open3);
use File::Temp qw(tempfile);
use File::Spec;
use Symbol qw(gensym);

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

my $PERL       = $^X;
my $SCRIPT     = File::Spec->catfile('script', 'dbic-mockdata');
my $SCHEMA_DIR = 't/lib';
my $NAMESPACE  = 'TestSchema';

# Run the CLI script, return (stdout, stderr, exit_code).
# Pass -Ilib AND -Iblib/lib so the module is found both when running
# directly (perl -Ilib t/03-cli.t) and via make test (blib/lib).
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

# ---------------------------------------------------------------------------
# 1. Missing required args produce errors and non-zero exit
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 2. --dry-run needs no DSN and prints DRY RUN output
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 3. --deploy creates tables and inserts rows
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 4. --wipe drops and recreates tables, then inserts
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 5. --seed makes output reproducible
# ---------------------------------------------------------------------------

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

# ---------------------------------------------------------------------------
# 6. --help exits zero and prints usage
# ---------------------------------------------------------------------------

subtest '--help exits zero and prints usage' => sub {
    my ($out, $err, $exit) = run_cli('--help');
    is   $exit, 0,           'exits zero';
    like $out,  qr/SYNOPSIS|OPTIONS|dbic-mockdata/i, 'usage text in stdout';
};

# ---------------------------------------------------------------------------
# 7. Bad --dsn exits non-zero with a useful error
# ---------------------------------------------------------------------------

subtest 'unknown DBI driver exits non-zero' => sub {
    my ($out, $err, $exit) = run_cli(
        @base_args,
        '--dsn', 'dbi:NoSuchDriver:dbname=test',
        '--deploy',
    );
    isnt $exit, 0, 'exits non-zero for unknown DBI driver';
};

done_testing;
