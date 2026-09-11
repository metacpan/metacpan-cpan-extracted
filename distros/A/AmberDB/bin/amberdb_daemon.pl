#!/usr/bin/perl

# bin/amberdb_daemon.pl - Unified AmberDB Background Sync Engine & Service Supervisor
# Handles runtime lifecycle (start, stop, restart, status, flush) and self-healing cron watchdog.

use 5.016;
use strict;
use warnings;
use Getopt::Long qw(:config pass_through);
use Fcntl qw(:flock);
use File::Spec;
use File::Basename qw(dirname);
use Cwd qw(abs_path getcwd);

BEGIN {
    use File::Basename qw(dirname);
    use Cwd qw(abs_path);
    my $bin_dir = dirname(abs_path(__FILE__));
    my $lib_dir = abs_path("$bin_dir/../lib");
    unshift @INC, $lib_dir if -d $lib_dir;
}

use AmberDB;

# Resolve project paths
my $script_path = abs_path(__FILE__);
my $script_dir  = dirname($script_path);
my $project_dir = abs_path( File::Spec->catdir( $script_dir, ".." ) );
my $lib_dir     = File::Spec->catdir( $project_dir, "lib" );

my $opt_interval = 1;
my $opt_dbase    = '';
my $opt_ramdisk  = '';
my $opt_table    = undef;
my $opt_verbose  = 0;
my $opt_once     = 0;
my $opt_help     = 0;

GetOptions(
    'interval=i'    => \$opt_interval,
    'dbase_dir=s'   => \$opt_dbase,
    'ramdisk_dir=s' => \$opt_ramdisk,
    'table=s'       => \$opt_table,
    'verbose|v'     => \$opt_verbose,
    'once'          => \$opt_once,
    'help|h'        => \$opt_help,
);

my $command = shift(@ARGV) // '';

# Determine dbase directory
my $dbase_dir = $opt_dbase;
if ( !defined $dbase_dir || $dbase_dir eq '' ) {
    my $cwd = abs_path(getcwd());
    if ( -d File::Spec->catdir( $cwd, "dbstore" ) ) {
        $dbase_dir = File::Spec->catdir( $cwd, "dbstore" );
    }
    elsif ( -d File::Spec->catdir( $cwd, "dbase" ) ) {
        $dbase_dir = File::Spec->catdir( $cwd, "dbase" );
    }
    elsif ( -d File::Spec->catdir( $cwd, "tables" ) ) {
        $dbase_dir = $cwd;
    }
    elsif ( -d File::Spec->catdir( $project_dir, "dbstore" ) ) {
        $dbase_dir = File::Spec->catdir( $project_dir, "dbstore" );
    }
    elsif ( -d File::Spec->catdir( $project_dir, "dbase" ) ) {
        $dbase_dir = File::Spec->catdir( $project_dir, "dbase" );
    }
    else {
        $dbase_dir = $project_dir;
    }
}
$dbase_dir = abs_path($dbase_dir);

# Alias --once to flush command
if ($opt_once) {
    $command = 'flush';
}

if ( $opt_help || $command eq 'usage' || $command eq 'help' || $command eq '' ) {
    show_usage();
    exit 0;
}

# Initialize AmberDB
my %adb_paths = ( dbase_dir => $dbase_dir );
$adb_paths{ramdisk_dir} = abs_path($opt_ramdisk) if defined $opt_ramdisk && length $opt_ramdisk;

my $adb = AmberDB->new( path => \%adb_paths );

my $lock_file = File::Spec->catfile( $dbase_dir, "amberdb_sync_daemon.lock" );
my $pid_file  = File::Spec->catfile( $dbase_dir, "amberdb_daemon.pid" );

# Dispatch command
if ( $command eq 'start' ) {
    cmd_start();
}
elsif ( $command eq 'stop' ) {
    cmd_stop();
}
elsif ( $command eq 'restart' ) {
    cmd_stop();
    sleep 1;
    cmd_start();
}
elsif ( $command eq 'status' ) {
    cmd_status();
}
elsif ( $command eq 'flush' ) {
    cmd_flush();
}
elsif ( $command eq 'watchdog' || $command eq 'check' ) {
    cmd_watchdog();
}
elsif ( $command eq 'run' ) {
    cmd_run();
}
else {
    print STDERR "Unknown command '$command'. Use 'perl $0 usage' for help.\n";
    exit 1;
}

# ============================================================================
# COMMAND IMPLEMENTATIONS
# ============================================================================

sub is_daemon_running {
    return 0 unless -e $lock_file;

    open my $fh, '<', $lock_file or return 0;
    if ( flock( $fh, LOCK_EX | LOCK_NB ) ) {
        # Lock acquired: daemon is NOT running
        flock( $fh, LOCK_UN );
        close $fh;
        return 0;
    }
    close $fh;

    # Lock held by running daemon
    return 1;
}

sub get_daemon_pid {
    if ( -e $pid_file && open my $pfh, '<', $pid_file ) {
        my $p = <$pfh>;
        close $pfh;
        chomp $p if $p;
        return $p if $p && $p =~ /^\d+$/;
    }
    if ( -e $lock_file && open my $lfh, '<', $lock_file ) {
        my $p = <$lfh>;
        close $lfh;
        chomp $p if $p;
        return $p if $p && $p =~ /^\d+$/;
    }
    return undef;
}

sub cmd_start {
    if ( is_daemon_running() ) {
        my $pid = get_daemon_pid() // 'unknown';
        print "[amberdb_daemon] Daemon is already running (PID: $pid).\n";
        return;
    }

    # Ensure RAM-disk is mounted
    unless ( $adb->ramdisk_is_mounted() ) {
        print "[amberdb_daemon] RAM-disk is not mounted. Attempting mount via setup tool...\n" if $opt_verbose;
        my $setup_pl = File::Spec->catfile( $script_dir, "amberdb_setup.pl" );
        if ( -e $setup_pl ) {
            system( qq{"$^X" -Ilib "$setup_pl" --action=ramdisk --start} );
        }
    }

    # Launch background worker process
    my $perl_bin = $^X;
    my @cmd_args = (
        qq{"$perl_bin"},
        qq{-I"$lib_dir"},
        qq{"$script_path"},
        "run",
        qq{--dbase_dir="$dbase_dir"},
        qq{--interval=$opt_interval},
    );
    push @cmd_args, qq{--ramdisk_dir="$opt_ramdisk"} if $opt_ramdisk;
    push @cmd_args, qq{--verbose} if $opt_verbose;

    my $spawn_cmd = join( " ", @cmd_args );

    if ( $^O eq 'MSWin32' || $^O eq 'msys' || $^O eq 'cygwin' ) {
        # Detached spawn on Windows
        system(qq{powershell -NoProfile -Command "Start-Process -FilePath '$perl_bin' -ArgumentList '-I\\"$lib_dir\\" \\"$script_path\\" run --dbase_dir \\"$dbase_dir\\" --interval $opt_interval' -WindowStyle Hidden"});
    }
    else {
        # Detached spawn on Linux / macOS
        system(qq{nohup $spawn_cmd > /dev/null 2>&1 &});
    }

    # Verify startup
    sleep 1;
    if ( is_daemon_running() ) {
        my $pid = get_daemon_pid() // 'active';
        print "[amberdb_daemon] Started successfully in background (PID: $pid).\n";
    }
    else {
        print STDERR "[amberdb_daemon] Failed to start background daemon. Check logs or permissions.\n";
        exit 1;
    }
}

sub cmd_stop {
    unless ( is_daemon_running() ) {
        print "[amberdb_daemon] Daemon is not running.\n";
        unlink $pid_file if -e $pid_file;
        return;
    }

    my $pid = get_daemon_pid();
    if ($pid) {
        print "[amberdb_daemon] Stopping daemon (PID: $pid)...\n";
        if ( $^O eq 'MSWin32' ) {
            system("taskkill /PID $pid /F >nul 2>&1");
        }
        else {
            kill( 'TERM', $pid );
        }

        # Wait up to 5s for clean shutdown
        my $wait = 5;
        while ( is_daemon_running() && $wait > 0 ) {
            sleep 1;
            $wait--;
        }
    }

    unlink $pid_file if -e $pid_file;

    # Flush remaining events upon stop
    print "[amberdb_daemon] Flushing pending dirty events to disk...\n" if $opt_verbose;
    my $flushed = $adb->ramdisk_sync_all();
    print "[amberdb_daemon] Stopped. (Flushed $flushed events on exit)\n";
}

sub cmd_status {
    print "=================================================================\n";
    print " AmberDB Daemon & Sync Subsystem Status                         \n";
    print "=================================================================\n";
    print "Database Root    : $dbase_dir\n";

    my $running = is_daemon_running();
    my $pid     = get_daemon_pid() // '-';
    print "Daemon Status    : " . ( $running ? "RUNNING (PID: $pid)" : "STOPPED" ) . "\n";
    print "Sync Interval    : ${opt_interval}s\n";

    # RAM-disk status
    my $setup_info = eval { $adb->ramdisk_setup() } // {};
    my $is_mounted = $setup_info->{is_mounted} || $adb->config('ramdisk_mounted') || 0;
    print "RAM-Disk Status  : " . ( $is_mounted ? "MOUNTED (" . ($setup_info->{mount_desc} // 'active') . ")" : "UNMOUNTED" ) . "\n";
    print "RAM-Disk Path    : " . ( $setup_info->{ramdisk_dir} // '-' ) . "\n";

    # Journal status
    my $jdir = eval { $adb->journal_dir() };
    if ( $jdir && -d $jdir ) {
        my $sync_file = $adb->journal_slot('sync_ramdisk');
        my $active_lines = 0;
        if ( -e $sync_file && open my $sfh, '<', $sync_file ) {
            while (<$sfh>) { $active_lines++; }
            close $sfh;
        }
        my @rotated = eval { $adb->journal_scan('sync_ramdisk_') };
        print "Journal Queue    : $active_lines active event(s) in live queue\n";
        print "Rotated Batches  : " . scalar(@rotated) . " rotated file(s) awaiting flush\n";
    }
    print "=================================================================\n";
}

sub cmd_flush {
    print "[amberdb_daemon] Running synchronous journal flush to persistent disk...\n" if $opt_verbose;
    my $synced = 0;
    if ( defined $opt_table && length $opt_table ) {
        $synced = $adb->ramdisk_sync($opt_table);
    }
    else {
        $synced = $adb->ramdisk_sync_all();
    }
    print "[amberdb_daemon] Flushed $synced dirty event(s) to persistent disk.\n";
}

sub cmd_watchdog {
    if ( is_daemon_running() ) {
        # Daemon is healthy, exit silently in 1ms
        exit 0;
    }

    # Daemon has died or was never started: resurrect it!
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    my $stamp = sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
    print "[$stamp] [WATCHDOG] AmberDB sync daemon is not running for $dbase_dir. Starting...\n";

    cmd_start();
}

sub cmd_run {
    # Acquire exclusive single-writer daemon lock
    open my $lock_fh, '>', $lock_file or die "[amberdb_daemon] Could not create lock file '$lock_file': $!\n";
    unless ( flock( $lock_fh, LOCK_EX | LOCK_NB ) ) {
        die "[amberdb_daemon] Another instance of the sync daemon is already running for '$dbase_dir'. Exiting.\n";
    }

    print $lock_fh "$$\n";
    $lock_fh->flush();

    # Write PID file
    if ( open my $pfh, '>', $pid_file ) {
        print $pfh "$$\n";
        close $pfh;
    }

    # Setup graceful shutdown handlers
    my $running = 1;
    my $sig_handler = sub {
        my ($sig) = @_;
        print "\n[amberdb_daemon] Received SIG$sig, shutting down cleanly...\n" if $opt_verbose;
        $running = 0;
    };
    $SIG{INT}  = $sig_handler;
    $SIG{TERM} = $sig_handler;

    print "[amberdb_daemon] Started worker process (PID: $$, interval: ${opt_interval}s, dbase: $dbase_dir)\n" if $opt_verbose;

    while ($running) {
        my $synced = 0;
        eval {
            if ( defined $opt_table && length $opt_table ) {
                $synced = $adb->ramdisk_sync($opt_table);
            }
            else {
                $synced = $adb->ramdisk_sync_all();
            }
        };
        if ($@) {
            warn "[amberdb_daemon] Error during sync: $@\n";
        }
        elsif ( $synced > 0 || $opt_verbose ) {
            my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
            my $stamp = sprintf( "%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );
            print "[$stamp] [amberdb_daemon] Flushed $synced dirty event(s) to persistent disk.\n";
        }

        # Sleep responsive to shutdown
        my $sleep_left = $opt_interval;
        while ( $running && $sleep_left > 0 ) {
            sleep 1;
            $sleep_left--;
        }
    }

    # Clean up lock and PID
    flock( $lock_fh, LOCK_UN );
    close $lock_fh;
    unlink $lock_file if -e $lock_file;
    unlink $pid_file if -e $pid_file;

    print "[amberdb_daemon] Worker process exited cleanly.\n" if $opt_verbose;
    exit 0;
}

sub show_usage {
    print <<"USAGE";
=================================================================
 AmberDB Service Daemon & Runtime Controller
=================================================================

Usage:
  perl bin/amberdb_daemon.pl <command> [options]

Commands:
  start          Check RAM-disk and start sync daemon in background
  stop           Gracefully stop running daemon and flush queue
  restart        Restart daemon process
  status         Display daemon status, RAM-disk state, and journal queue
  flush          Execute a single synchronous sync pass and exit
  watchdog       Check health; exit immediately if alive, restart if stopped
  run            Run daemon worker in foreground (internal loop)
  usage, help    Show this help message

Options:
  --interval N       Sync flush interval in seconds (default: 1)
  --dbase_dir PATH   AmberDB dbase root directory (default: auto-detected)
  --ramdisk_dir PATH AmberDB RAM-disk directory (default: dbase_dir/ramdisk)
  --table NAME       Limit sync operations to a specific table
  --verbose, -v      Print verbose operational logs

Examples:
  perl bin/amberdb_daemon.pl start
  perl bin/amberdb_daemon.pl status
  perl bin/amberdb_daemon.pl flush
  perl bin/amberdb_daemon.pl watchdog
=================================================================
USAGE
}

1;
