use strict;
use warnings;

use lib 't/lib';

use Test::More;
use Test::Fatal;
use Test::TempDir::Tiny;
use TestDB;

use App::mimi;
use App::mimi::db;

subtest 'check: prints correct message when not set up' => sub {
    my $migrator = _build_migrator();

    open my $fh, '>', \my $stdout;
    local *STDOUT = $fh;

    $migrator->check;

    like $stdout, qr/Migrations are not installed/;
};

subtest 'check: prints correct message when no migrations' => sub {
    my $migrator = _build_migrator();

    open my $fh, '>', \my $stdout;
    local *STDOUT = $fh;

    $migrator->setup;

    $migrator->check;

    like $stdout, qr/No migrations found/;
};

subtest 'check: prints correct message when last migration' => sub {
    my $dir = tempdir();

    _write_file("$dir/01foo.sql", '');

    my $migrator = _build_migrator(schema => $dir);

    open my $fh, '>', \my $stdout;
    local *STDOUT = $fh;

    $migrator->setup;
    $migrator->migrate;

    $migrator->check;

    like $stdout, qr/Last migration: 1/;
};

subtest 'check: prints correct message when last migration with error' => sub {
    my $dir = tempdir();

    _write_file("$dir/01foo.sql", 'error');

    my $migrator = _build_migrator(schema => $dir);

    open my $fh,  '>', \my $stdout;
    open my $fh2, '>', \my $stderr;
    local *STDOUT = $fh;
    local *STDERR = $fh2;

    $migrator->setup;

    eval { $migrator->migrate; };

    $migrator->check;

    like $stdout, qr/syntax error/;
};

subtest 'throw when already set up' => sub {
    my $migrator = _build_migrator();

    $migrator->setup;

    like exception { $migrator->setup }, qr/migrations table already exists/;
};

subtest 'throw when schema directory does not exist' => sub {
    my $migrator = _build_migrator(schema => 'unlikely-to-exist');

    like exception { $migrator->migrate }, qr/schema directory is required/i;
};

subtest 'throw when no schema files found' => sub {
    my $migrator = _build_migrator(schema => tempdir());

    like exception { $migrator->migrate }, qr/no schema \*\.sql files found/i;
};

subtest 'throw when database not prepared' => sub {
    my $dir = tempdir();

    _write_file("$dir/01foo.sql", '');

    my $migrator = _build_migrator(schema => $dir);

    like exception { $migrator->migrate }, qr/migrations table not found/i;
};

subtest 'create first migration' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    my $dir = tempdir();

    _write_file("$dir/01foo.sql", '');

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);
    $migrator->migrate;

    my $migration = $db->fetch_last_migration;

    ok $migration;
    is $migration->{no}, 1;
};

subtest 'create next migration' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'success');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql", '');

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);
    $migrator->migrate;

    my $migration = $db->fetch_last_migration;

    ok $migration;
    is $migration->{no}, 2;
};

subtest 'runs sql' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'success');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql",
        'CREATE TABLE `foo` (`id` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT)');

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);
    $migrator->migrate;

    ok $dbh->do('SELECT 1 FROM foo LIMIT 1');
};

subtest 'saves status when sql fails' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'success');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql", 'CREAT');

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);

    local $SIG{__WARN__} = sub { };
    ok exception { $migrator->migrate };

    my $migration = $db->fetch_last_migration;

    is $migration->{status},  'error';
    like $migration->{error}, qr/do failed: near "CREAT":/;
};

subtest 'throws if error status' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'error');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql");

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);

    like exception { $migrator->migrate }, qr/migrations are dirty/i;
};

subtest 'creates no migrations when dry-run' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    my $dir = tempdir();

    _write_file("$dir/01foo.sql", '');

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir, dry_run => 1);
    $migrator->migrate;

    my $migration = $db->fetch_last_migration;

    ok !$migration;
};

subtest 'fixes dirty migration' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'error');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql");

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir);

    $migrator->fix;

    ok !exception { $migrator->migrate };

    my $last_migration = $db->fetch_last_migration;
    is $last_migration->{status}, 'success';
};

subtest 'fixes nothing when dry_run' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    $db->create_migration(no => 1, created => time, status => 'error');

    my $dir = tempdir();

    _write_file("$dir/02foo.sql");

    my $migrator = _build_migrator(dbh => $dbh, schema => $dir, dry_run => 1);

    $migrator->fix;

    my $last_migration = $db->fetch_last_migration;

    is $last_migration->{status}, 'error';
};

subtest 'creates last migration manually' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    my $migrator = _build_migrator(dbh => $dbh, migration => 35);

    $migrator->set;

    my $last_migration = $db->fetch_last_migration;

    is $last_migration->{no},     35;
    is $last_migration->{status}, 'success';
};

subtest 'does not set migration when dry_run' => sub {
    my $dbh = TestDB->setup;

    my $db = App::mimi::db->new(dbh => $dbh);
    $db->prepare;

    my $migrator = _build_migrator(dbh => $dbh, migration => 35, dry_run => 1);

    $migrator->set;

    my $last_migration = $db->fetch_last_migration;

    ok !$last_migration;
};

sub _write_file {
    my ($file, $content) = @_;

    open my $fh, '>', $file or die $!;
    print $fh $content if defined $content;
    close $fh;
}

sub _build_migrator {
    my (%params) = @_;

    $params{dbh} ||= TestDB->setup;

    App::mimi->new(%params);
}

done_testing;
