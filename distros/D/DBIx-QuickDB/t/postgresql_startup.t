use strict;
use warnings;

use Test2::V0;
use Test2::API qw/intercept/;
use File::Temp qw/tempdir/;

use DBIx::QuickDB::Driver::PostgreSQL;
use Test2::Tools::QuickDB qw/skipall_on_resource_error/;

{
    package Test::PostgreSQL::StartupWatcher;

    sub new {
        my $class = shift;
        my ($log_file) = @_;
        return bless {log_file => $log_file, stopped => 0, waited => 0}, $class;
    }

    sub log_file { shift->{log_file} }
    sub stop { shift->{stopped}++; return }
    sub wait { shift->{waited}++; return }
}

{
    package Test::PostgreSQL::StartupDBH;

    sub new { bless {disconnected => 0}, shift }
    sub disconnect { shift->{disconnected}++; return 1 }
}

my $dir = tempdir("QDB-TEST-$$-XXXXXX", TMPDIR => 1, CLEANUP => 1);
my $launch_log = "$dir/launch.log";
open(my $launch_fh, '>', $launch_log) or die "Cannot write $launch_log: $!";
print {$launch_fh} <<'LOG';
FATAL:  could not create semaphores: No space left on device
DETAIL:  Failed system call was semget(5432015, 17, 03600).
LOG
close($launch_fh) or die "Cannot close $launch_log: $!";

my $error_log = "$dir/error.log";
open(my $error_fh, '>', $error_log) or die "Cannot write $error_log: $!";
print {$error_fh} "postmaster startup detail\n";
close($error_fh) or die "Cannot close $error_log: $!";

my $watcher = Test::PostgreSQL::StartupWatcher->new($launch_log);
my $db = bless {
    +DBIx::QuickDB::Driver::DIR()     => $dir,
    +DBIx::QuickDB::Driver::PostgreSQL::SOCKET() => "$dir/.s.PGSQL.5432",
    +DBIx::QuickDB::Driver::WATCHER() => $watcher,
}, 'DBIx::QuickDB::Driver::PostgreSQL';

subtest readiness_probe_disconnects => sub {
    my $base_start_calls = 0;
    my $dbh = Test::PostgreSQL::StartupDBH->new;
    my @connect_args;

    no warnings 'redefine';
    local *DBIx::QuickDB::Driver::start = sub { $base_start_calls++; return };
    local *DBIx::QuickDB::Driver::connect = sub {
        shift;
        @connect_args = @_;
        return $dbh;
    };

    $db->start('extra-server-arg');

    is($base_start_calls, 1, 'delegated server launch to the base driver');
    is(
        \@connect_args,
        ['postgres', AutoCommit => 1, RaiseError => 1, PrintError => 0],
        'readiness connection is fatal-on-error without expected DBI warnings',
    );
    is($dbh->{disconnected}, 1, 'confirmed readiness and disconnected the probe handle');
};

subtest failed_probe_preserves_error_and_early_logs => sub {
    no warnings 'redefine';
    local *DBIx::QuickDB::Driver::start = sub { return };
    local *DBIx::QuickDB::Driver::connect = sub {
        die "DBI connect failed: Unix socket disappeared\n";
    };

    my $err;
    eval { $db->start; 1 } or $err = $@;

    like($err, qr/DBI connect failed: Unix socket disappeared/,
        'kept the original non-resource connection error');
    like($err, qr/=== server launch log ===.*could not create semaphores.*semget\(/s,
        'included the early postmaster failure from the watcher launch log');
    like($err, qr/=== error log ===.*postmaster startup detail/s,
        'included the PostgreSQL error log when present');
    is($watcher->{stopped}, 1, 'stopped the watcher after failed readiness');
    is($watcher->{waited}, 1, 'waited for the failed postmaster to be reaped');
    ok(!$db->watcher, 'cleared the failed watcher from the driver');

    my $events = intercept { skipall_on_resource_error($err) };
    my ($plan) = grep {
        $_->isa('Test2::Event::Plan') && $_->facet_data->{plan}->{skip}
    } @$events;
    ok($plan, 'the existing exact resource matcher can classify the enriched error');
    like($plan->facet_data->{plan}->{details}, qr/semaphore/i,
        'the resulting skip identifies semaphore exhaustion');
};

done_testing;
