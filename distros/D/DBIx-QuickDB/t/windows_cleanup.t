use strict;
use warnings;

use Test2::V0;
use Errno qw/EACCES/;
use File::Path qw/make_path/;
use File::Temp qw/tempdir/;

use DBIx::QuickDB::Util qw/disconnect_dbi_handles/;

{
    package Local::SQLiteLoadHandle;

    sub new { bless {disconnects => $_[1], fail => $_[2]}, $_[0] }
    sub do { die "SQL FAILED\n" if $_[0]->{fail}; return 1 }
    sub disconnect { ${$_[0]->{disconnects}}++; return 1 }
    sub errstr { 'fake DBI error' }
}

subtest windows_path_matching => sub {
    ok(
        DBIx::QuickDB::Util::_dbi_name_matches_dir(
            'dbname=C:\\Users\\Smoker\\AppData\\Local\\Temp\\QuickDB\\quickdb',
            'c:/users/smoker/appdata/local/temp/quickdb',
            1,
        ),
        'Windows DBI names match the same directory across slash direction and case',
    );

    ok(
        !DBIx::QuickDB::Util::_dbi_name_matches_dir(
            'dbname=C:\\Users\\Smoker\\AppData\\Local\\Temp\\quickdb-old\\quickdb',
            'c:/users/smoker/appdata/local/temp/quickdb',
            1,
        ),
        'a similarly-named sibling Windows directory does not match',
    );
};

my $has_sqlite = eval { require DBI; require DBD::SQLite; 1 };

subtest multiple_retained_handles => sub {
    plan(skip_all => 'DBI and DBD::SQLite are required for handle cleanup tests')
        unless $has_sqlite;

    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my @dbh = map {
        DBI->connect("dbi:SQLite:dbname=$dir/db$_", '', '', {RaiseError => 1})
    } 1 .. 3;

    ok($_->{Active}, 'retained SQLite handle starts active') for @dbh;

    is(
        disconnect_dbi_handles($dir),
        3,
        'all matching handles were collected and disconnected',
    );
    ok(!$_->{Active}, 'retained SQLite handle was disconnected') for @dbh;
};

subtest sqlite_load_sql_disconnects_explicitly => sub {
    require DBIx::QuickDB::Driver::SQLite;

    my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $db = DBIx::QuickDB::Driver::SQLite->new(dir => $dir);

    no warnings qw/redefine once/;
    my $disconnects = 0;
    local *DBIx::QuickDB::Driver::SQLite::connect = sub {
        return Local::SQLiteLoadHandle->new(\$disconnects, 0);
    };

    is($db->load_sql(quickdb => 't/schema/sqlite.sql'), 1,
        'SQLite load_sql returns the statement result');
    is($disconnects, 1, 'SQLite load_sql explicitly disconnects its bootstrap handle');

    local *DBIx::QuickDB::Driver::SQLite::connect = sub {
        return Local::SQLiteLoadHandle->new(\$disconnects, 1);
    };
    like(
        dies { $db->load_sql(quickdb => 't/schema/sqlite.sql') },
        qr/SQL FAILED/,
        'SQLite load_sql preserves a statement failure',
    );
    is($disconnects, 2, 'SQLite load_sql also disconnects after a statement failure');
};

subtest driver_quarantines_a_tree_that_survives_removal => sub {
    require DBIx::QuickDB::Driver::SQLite;

    my $base = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $dir = "$base/database";
    make_path($dir);
    open(my $fh, '>', "$dir/sqlite-file") or die "Could not create cleanup marker: $!";
    print {$fh} "data\n";
    close($fh);

    my $db = DBIx::QuickDB::Driver::SQLite->new(dir => $dir, cleanup => 1);
    my $real_remove = \&DBIx::QuickDB::Util::remove_tree_robust;

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Util::remove_tree_robust = sub {
        my ($path) = @_;
        return 0 if $path eq $dir;
        return $real_remove->(@_);
    };

    $db->cleanup;
    my $cleanup_error_number = 0 + $!;
    my $cleanup_error = "$!";

    my $dir_gone = !-d $dir;
    opendir(my $dh, $base) or die "Could not inspect cleanup directory: $!";
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir($dh);
    my @quarantine = map { "$base/$_" }
        grep { /^database\.STALE-/ } @entries;

    unless ($dir_gone && @quarantine == 1) {
        diag("cleanup OS error $cleanup_error_number: $cleanup_error");
        diag('cleanup parent contains: ' . join(', ' => sort @entries));
    }

    ok($dir_gone, 'driver cleanup clears the canonical database path after deletion fails');
    is(scalar(@quarantine), 1, 'driver cleanup creates exactly one quarantine');
    if (@quarantine) {
        ok(-e "$quarantine[0]/sqlite-file", 'quarantine contains the undeleted database file');
        $real_remove->($quarantine[0]);
    }
    else {
        fail('quarantine contains the undeleted database file');
    }
};

subtest transient_quarantine_rename_is_retried => sub {
    my $base = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $dir = "$base/database";
    make_path($dir);

    my $real_remove = \&DBIx::QuickDB::Util::remove_tree_robust;
    my $renames = 0;
    my $pauses = 0;

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Util::remove_tree_robust = sub {
        return 0 if $_[0] eq $dir;
        return $real_remove->(@_);
    };
    local *DBIx::QuickDB::Util::_rename_tree = sub {
        $renames++;
        if ($renames <= 2) {
            $! = EACCES;
            return 0;
        }
        return CORE::rename($_[0], $_[1]);
    };
    local *DBIx::QuickDB::Util::_quarantine_retry_pause = sub {
        $pauses++;
        return;
    };

    my $stale = DBIx::QuickDB::Util::remove_tree_or_quarantine($dir);
    ok(defined($stale) && length($stale), 'transient rename failures eventually quarantine the tree');
    is($renames, 3, 'rename was retried until it succeeded');
    is($pauses, 2, 'each transient failure paused before retrying');
    ok(!-d $dir && -d $stale, 'successful retry clears the canonical path');

    $real_remove->($stale);
};

subtest driver_reports_terminal_cleanup_failure => sub {
    require DBIx::QuickDB::Driver::SQLite;

    my $base = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $dir = "$base/database";
    make_path($dir);
    my $db = DBIx::QuickDB::Driver::SQLite->new(dir => $dir, cleanup => 1);

    my $real_remove = \&DBIx::QuickDB::Util::remove_tree_robust;
    my $warnings = '';

    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Util::remove_tree_robust = sub {
        $! = EACCES;
        return 0;
    };
    local *DBIx::QuickDB::Util::_rename_tree = sub {
        $! = EACCES;
        return 0;
    };
    local *DBIx::QuickDB::Util::_quarantine_retry_pause = sub { return };
    local $SIG{__WARN__} = sub { $warnings .= join '' => @_ };

    $db->cleanup;

    like(
        $warnings,
        qr/Could not remove or quarantine database directory '\Q$dir\E' \(OS error @{[0 + EACCES]}:/,
        'driver reports the directory and OS error when cleanup cannot clear the canonical path',
    );
    ok(-d $dir, 'terminal cleanup failure leaves the canonical path for diagnostics');

    $real_remove->($dir);
    $db = undef;
};

subtest later_cleanup_retries_a_quarantine => sub {
    my $base = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $first = "$base/first";
    my $second = "$base/second";
    make_path($first, $second);

    my $real_remove = \&DBIx::QuickDB::Util::remove_tree_robust;
    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Util::remove_tree_robust = sub {
        return 0 if $_[0] eq $first;
        return $real_remove->(@_);
    };

    my $stale = DBIx::QuickDB::Util::remove_tree_or_quarantine($first);
    ok(defined($stale) && length($stale), 'failed removal created a quarantine');
    ok(-d $stale, 'quarantine initially remains on disk');

    is(DBIx::QuickDB::Util::remove_tree_or_quarantine($second), '',
        'a later cleanup removed its own tree normally');
    ok(!-d $stale, 'the later cleanup also retried the earlier quarantine');
};

subtest pool_never_rebuilds_in_stale_tree => sub {
    require DBIx::QuickDB::Pool;

    my $base  = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $cache = "$base/cache with space";
    make_path($cache);
    my $dir   = "$cache/database-checksum";
    make_path($dir);
    open(my $fh, '>', "$dir/old-schema") or die "Could not create stale marker: $!";
    print {$fh} "stale\n";
    close($fh);

    my $pool = DBIx::QuickDB::Pool->new(cache_dir => $cache);
    my $spec = {};

    my $real_remove = \&DBIx::QuickDB::Util::remove_tree_robust;
    my $calls = 0;
    no warnings qw/redefine once/;
    local *DBIx::QuickDB::Util::remove_tree_robust = sub {
        my ($path) = @_;
        return 0 if $path eq $dir && !$calls++;
        return $real_remove->(@_);
    };

    # Stop after directory preparation; this unit test does not need a driver.
    local *DBIx::QuickDB::Pool::build_via_driver = sub { die "PREPARED\n" };
    my $ok = eval { $pool->build_db($dir, $spec); 1 };
    my $err = $@;

    ok(!$ok, 'test hook stopped the build after directory preparation');
    like($err, qr/^PREPARED/, 'reached the builder with a prepared directory');
    ok(-d $dir, 'fresh canonical build directory was created');
    ok(!-e "$dir/old-schema", 'stale content was not left in the build directory');

    my $quarantines = sub {
        opendir(my $dh, $cache) or die "Could not open cache directory: $!";
        my @paths = map { "$cache/$_" }
            grep { /^database-checksum\.STALE-/ && -d "$cache/$_" }
            readdir($dh);
        closedir($dh);
        return @paths;
    };

    my @quarantine = $quarantines->();
    is(scalar(@quarantine), 1, 'failed deletion quarantined exactly one stale tree');
    ok(-e "$quarantine[0]/old-schema", 'quarantine contains the stale content');

    $pool->clear_old_cache(0);
    is([$quarantines->()], [], 'a later cache sweep reclaims the quarantine from a path with spaces');
};

subtest locale_formatted_clone_timestamp => sub {
    require DBIx::QuickDB::Pool;

    my $base = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
    my $cache = "$base/cache";
    my $dir = "$cache/database-checksum";
    my $empty = "$cache/empty-checksum";
    make_path($dir);
    make_path($empty);
    open(my $fh, '>', "$dir/cloned") or die "Could not create clone stamp: $!";
    print {$fh} "1234567890,125\n";
    close($fh);
    open(my $empty_fh, '>', "$empty/cloned") or die "Could not create empty clone stamp: $!";
    close($empty_fh);

    my $pool = DBIx::QuickDB::Pool->new(cache_dir => $cache);
    my $warnings = '';
    {
        local $SIG{__WARN__} = sub { $warnings .= join '' => @_ };
        $pool->clear_old_cache(0);
    }

    is($warnings, '', 'decimal-comma and empty clone timestamps emit no warnings');
    ok(!-d $dir, 'decimal-comma clone timestamp expires normally');
    ok(!-d $empty, 'empty clone timestamp is reclaimed instead of being pinned');
};

done_testing;
