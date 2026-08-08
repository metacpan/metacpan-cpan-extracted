package DBIx::QuickDB::Util;
use strict;
use warnings;

our $VERSION = '0.000063';

use Errno qw/EEXIST/;
use File::Path qw/remove_tree/;
use IPC::Cmd qw/can_run/;
use Carp qw/confess/;
use Time::HiRes qw/sleep/;

use Importer Importer => 'import';

our @EXPORT_OK = qw/clone_dir strip_hash_defaults env_timeout remove_tree_robust remove_tree_or_quarantine disconnect_dbi_handles/;

my @DEFERRED_REMOVE;

# A quarantine can outlive the immediate cleanup attempt while Windows releases
# a delete-pending file. Retry earlier quarantines during later cleanups and once
# more after normal END blocks have released application/test resources. This is
# best-effort and must not alter the exit status or turn successful teardown into
# a global-destruction exception.
sub _retry_deferred_remove {
    @DEFERRED_REMOVE = grep {
        -d $_ && !remove_tree_robust($_)
    } @DEFERRED_REMOVE;
    return;
}

END {
    local $?;
    _retry_deferred_remove();
}

# Return true when a DBI handle Name contains a database directory. DBI drivers
# preserve the spelling used in their DSN, while File::Temp/File::Spec can hand
# the driver object a differently-spelled version of the same Windows path
# (backslashes vs forward slashes, and different case). A raw index() therefore
# misses the live SQLite handle precisely on the platform where that handle
# prevents unlinking the database file.
#
# $win32 is private test plumbing. Production callers omit it and use $^O.
sub _dbi_name_matches_dir {
    my ($name, $dir, $win32) = @_;
    return 0 unless defined($name) && length($name);
    return 0 unless defined($dir)  && length($dir);

    $win32 = $^O eq 'MSWin32' unless defined $win32;
    if ($win32) {
        tr{\\}{/} for $name, $dir;
        $name = lc $name;
        $dir  = lc $dir;
    }

    # Avoid treating a sibling such as C:\db-old as a child of C:\db. In a
    # DBI Name the directory is either the whole value, follows a DSN separator,
    # and is followed by a path/DSN separator or the end of the string.
    $dir =~ s{/$}{} unless $dir =~ m{^[a-z]:/$}i;
    my $at = -1;
    while (($at = index($name, $dir, $at + 1)) >= 0) {
        my $before = $at ? substr($name, $at - 1, 1) : '';
        my $after_at = $at + length($dir);
        my $after = $after_at < length($name) ? substr($name, $after_at, 1) : '';
        next unless !$at || $before =~ /[=;\s]/;
        return 1 if $after eq '' || $after =~ m{[/;?\s]};
    }

    return 0;
}

# Disconnect all DBI database handles in this process whose DSN points into the
# supplied directory. Collect first and disconnect second: mutating DBI's child
# handle tree from inside visit_handles() can otherwise skip a sibling handle.
# DBI is optional and may not have been loaded, so this remains a no-op in that
# case and during global destruction when DBI's own handle tree is going away.
sub disconnect_dbi_handles {
    my ($dir) = @_;

    return 0 unless $INC{'DBI.pm'};
    return 0 if defined(${^GLOBAL_PHASE}) && ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my @handles;
    DBI->visit_handles(
        sub {
            my ($handle) = @_;
            push @handles => $handle
                if $handle->{Type} && $handle->{Type} eq 'db' && $handle->{Active}
                && _dbi_name_matches_dir($handle->{Name}, $dir);
            return 1;
        }
    );

    $_->disconnect for @handles;
    return scalar @handles;
}

# Best-effort recursive removal that also copes with Windows. On MSWin32 a plain
# remove_tree can leave the directory non-empty -- the OS releases file handles
# asynchronously (delete-pending state; an antivirus/indexer may briefly re-open
# a just-closed file such as a SQLite data file), so an immediate rmdir of the
# enclosing directory gets ENOTEMPTY. Retry a few times with a short sleep to let
# the lock clear. On Unix a single pass is enough, so it behaves exactly like a
# plain remove_tree there (no added latency).
#
# Removal is treated as idempotent best-effort: errors are collected (never
# thrown per-file) and File::Path's own hard-die -- "cannot chdir to .. from DIR
# ... aborting", which happens when the tree mutates underneath us because the
# watcher daemon is deleting the same directory concurrently -- is swallowed by
# an eval. Whoever wins the race, the directory ends up gone. Returns true if the
# directory is gone afterward, false if it stubbornly survived every attempt.
#
# $opts is an optional File::Path::remove_tree options hashref (defaults to
# {safe => 1}); an 'error' key is always supplied internally and overrides any
# caller-provided one.
sub remove_tree_robust {
    my ($dir, $opts) = @_;
    $opts ||= {safe => 1};

    return 1 unless -d $dir;

    my $tries = $^O eq 'MSWin32' ? 5 : 1;

    for my $try (1 .. $tries) {
        my $err = [];
        eval { remove_tree($dir, {%$opts, error => \$err}); 1 };
        return 1 unless -d $dir;
        last if $try == $tries;
        sleep 0.2;
    }

    return 0;
}

# Keep filesystem operations and retry pauses behind private functions so the
# transient-failure sequence can be exercised deterministically in tests.
sub _rename_tree {
    return rename($_[0], $_[1]);
}

sub _quarantine_retry_pause {
    sleep 0.2 if $^O eq 'MSWin32';
    return;
}

# Remove a disposable tree. If deletion still fails after the platform-aware
# retries above, move it away from its canonical name so callers never rebuild
# or continue using a partially deleted database. The quarantine remains on the
# same volume and is retried by later cleanups and the END block above; Pool
# sweeps may reclaim it sooner. Returns an empty string for direct removal, the
# quarantine path after a successful rename, and undef only when neither
# operation cleared the original path.
sub remove_tree_or_quarantine {
    my ($dir, $opts) = @_;

    _retry_deferred_remove() if @DEFERRED_REMOVE;

    return '' unless -d $dir;
    return '' if remove_tree_robust($dir, $opts);

    my $error;
    my $max_attempts = 10;
    for my $attempt (1 .. $max_attempts) {
        return '' unless -d $dir; # A concurrent watcher won the cleanup race.

        my $stale = join '-' => "$dir.STALE", $$, CORE::time(), $attempt;
        next if -e $stale;

        if (_rename_tree($dir, $stale)) {
            push @DEFERRED_REMOVE => $stale;
            return $stale;
        }

        $error = $!;
        _quarantine_retry_pause() if $attempt < $max_attempts;
    }

    return '' unless -d $dir;

    $error = EEXIST unless defined $error;
    $! = $error;
    return undef;
}

# Read a positive-integer timeout (in seconds) from an environment variable,
# falling back to $default when it is unset or not a positive integer. Used to
# make the server start/stop timeouts generous-but-tunable so slow hosts (e.g.
# CPAN smoke boxes) do not spuriously time out.
sub env_timeout {
    my ($name, $default) = @_;
    my $val = $ENV{$name};
    return $val if defined($val) && $val =~ /^\d+$/ && $val > 0;
    return $default;
}

my ($RSYNC, $CP);

BEGIN {
    local $@;
    $RSYNC = can_run('rsync');
    $CP    = can_run('cp');
}

# clone_dir($src, $dest, %params) -- copy a data dir, dying on failure with the
# decoded exit status, both paths and the tool's stderr. %params: checksum,
# verbose. The rsync backend retries a partial transfer and warns when it does.
sub clone_dir {
    return _clone_dir_rsync(@_) if $RSYNC;
    return _clone_dir_cp(@_)    if $CP;
    return _clone_dir_fcr(@_);
}

# Decode a wait status into an actionable message. $bang is passed in because
# the filehandle ops between system() and this call would have clobbered $!.
sub _copy_error {
    my ($cmd, $status, $src, $dest, $stderr, $bang) = @_;

    my $msg = "$cmd failed copying '$src' -> '$dest': ";

    if ($status == -1) {
        $msg .= "could not execute (" . (defined($bang) ? $bang : $!) . ")";
    }
    elsif (my $sig = $status & 127) {
        $msg .= "terminated by signal $sig" . (($status & 128) ? " (core dumped)" : "");
    }
    else {
        $msg .= "exited " . ($status >> 8);
    }

    $msg .= "\n=== $cmd stderr ===\n$stderr" if defined($stderr) && length($stderr);

    return $msg;
}

# Run $cmd with its stderr captured to a scratch file, returning ($status,
# $stderr, $errno). Only stderr is redirected: rsync writes -vP progress to
# STDOUT, so verbose runs still stream live exactly as before.
sub _run_captured {
    my (@cmd) = @_;

    require File::Temp;

    # QDB_TMPDIR because File::Spec->tmpdir falls back to the CURRENT DIRECTORY
    # when /tmp is unwritable. UNLINK is only a backstop -- File::Temp keeps the
    # handle registered, so a leak here would hold the fd until process exit;
    # every path below unlinks explicitly.
    my ($fh, $file) = File::Temp::tempfile(
        "qdb-copy-err-$$-XXXXXXXX",
        $ENV{QDB_TMPDIR} ? (DIR => $ENV{QDB_TMPDIR}) : (TMPDIR => 1),
        UNLINK => 1,
    );

    # Best effort: a caller that closed STDERR (a daemonizer, say) makes this
    # dup fail, and it could copy fine before capturing existed. Run uncaptured
    # rather than failing the copy over diagnostics.
    my $save;
    unless (open($save, '>&', \*STDERR)) {
        close($fh);
        unlink($file);

        system(@cmd);
        my ($st, $bg) = ($?, $!);

        return ($st, '', $bg);
    }

    # Restore STDERR on every path: reopening it closes it first, so bailing out
    # mid-way would leave the process with no STDERR and free fd 2 for the next
    # open(). Redirect through File::Temp's handle rather than reopening the
    # path by name, which is the symlink race File::Temp exists to avoid.
    my ($status, $bang);
    my $ok = eval {
        open(STDERR, '>&', $fh) or die "Could not redirect STDERR: $!";

        system(@cmd);
        ($status, $bang) = ($?, $!);    # before anything can clobber them

        1;
    };
    my $err = $@;

    open(STDERR, '>&', $save) or warn "Could not restore STDERR: $!";
    close($save);

    # Drain and clean up before any rethrow: an escaping exception would leave
    # $fh registered with File::Temp, holding the fd until process exit. Rewind
    # first, since the dup shared its offset with the child's writes.
    my $stderr = '';
    if (seek($fh, 0, 0)) {
        local $/;
        $stderr = <$fh> // '';
    }
    close($fh);
    unlink($file);

    die $err unless $ok;

    return ($status, $stderr, $bang);
}

# Attempts for rsync exit 23, "partial transfer due to error". Exit 24
# ("vanished source files") is not retried -- the source is gone.
my $RSYNC_RETRIES = 3;

sub _clone_dir_rsync {
    my ($src, $dest, %params) = @_;

    my @cmd = (
        $RSYNC, '-a', '--delete', '--exclude' => '.nfs*',
        $params{checksum} ? ('-c') : (),
        $params{verbose}  ? ('-vP') : (),
        "$src/", $dest,
    );

    for my $try (1 .. $RSYNC_RETRIES) {
        my ($status, $stderr, $bang) = _run_captured(@cmd);

        unless ($status) {
            print STDERR $stderr if length $stderr;
            return;
        }

        my $code = ($status == -1 || ($status & 127)) ? undef : ($status >> 8);

        die _copy_error($RSYNC, $status, $src, $dest, $stderr, $bang)
            if !defined($code) || $code != 23 || $try == $RSYNC_RETRIES;

        # A retry that succeeds leaves this warning as the only record that a
        # partial transfer happened at all.
        my $msg = "$RSYNC exited 23 (partial transfer) copying '$src' -> '$dest'"
            . " on attempt $try of $RSYNC_RETRIES, retrying";
        $msg .= "\n=== $RSYNC stderr ===\n$stderr" if length $stderr;
        warn "$msg\n";

        sleep(0.25 * $try);
    }

    return;
}

sub _clone_dir_cp {
    my ($src, $dest, %params) = @_;
    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;

    my ($status, $stderr, $bang) = _run_captured($CP, '-a', $params{verbose} ? ('-v') : (), "$src/.", $dest);
    die _copy_error($CP, $status, $src, $dest, $stderr, $bang) if $status;
    print STDERR $stderr if length $stderr;

    return;
}

sub _clone_dir_fcr {
    my ($src, $dest, %params) = @_;
    require File::Copy::Recursive;

    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;
    File::Copy::Recursive::dircopy($src, $dest)
        or die "File::Copy::Recursive::dircopy failed copying '$src' -> '$dest': $!";
}

sub strip_hash_defaults {
    my ($hash, $defaults) = @_;

    my $out = {%$hash};

    for my $key (keys %$defaults) {
        my $refout = ref($out->{$key});
        my $refdef = ref($defaults->{$key});

        if ($refout eq $refdef && $refdef eq 'HASH') {
            $out->{$key} = strip_hash_defaults($out->{$key}, $defaults->{$key});
            next;
        }

        if ($refout ne $refdef) {
            delete $out->{$key};
            next;
        }

        no warnings 'numeric';
        delete $out->{$key} if $out->{$key} && $out->{$key} eq $defaults->{$key};
    }

    return $out;
}

1;
