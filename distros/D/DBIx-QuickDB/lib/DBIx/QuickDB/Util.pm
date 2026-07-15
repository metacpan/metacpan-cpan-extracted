package DBIx::QuickDB::Util;
use strict;
use warnings;

our $VERSION = '0.000055';

use File::Path qw/remove_tree/;
use IPC::Cmd qw/can_run/;
use Carp qw/confess/;
use Time::HiRes qw/sleep/;

use Importer Importer => 'import';

our @EXPORT_OK = qw/clone_dir strip_hash_defaults env_timeout remove_tree_robust/;

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

sub clone_dir {
    return _clone_dir_rsync(@_) if $RSYNC;
    return _clone_dir_cp(@_)    if $CP;
    return _clone_dir_fcr(@_);
}

sub _clone_dir_rsync {
    my ($src, $dest, %params) = @_;
    system($RSYNC, '-a', '--delete', '--exclude' => '.nfs*', $params{checksum} ? ('-c') : (), $params{verbose} ? ( '-vP' ) : (), "$src/", $dest) and die "$RSYNC returned $?";
}

sub _clone_dir_cp {
    my ($src, $dest, %params) = @_;
    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;
    system($CP, '-a', $params{verbose} ? ( '-v' ) : (), "$src/.", $dest) and die "$CP returned $?";
}

sub _clone_dir_fcr {
    my ($src, $dest, %params) = @_;
    require File::Copy::Recursive;

    my $err;
    remove_tree($dest, {safe => 1, keep_root => 1, error => \$err}) if -d $dest;
    File::Copy::Recursive::dircopy($src, $dest) or die "$!";
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
