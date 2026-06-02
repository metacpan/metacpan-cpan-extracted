package TestHelper;

use strict;
use warnings;

use IPC::Shareable;
use Test::More;

our $TESTING_DIST = 'Async::Event::Interval';

my ($segs_before, $sems_before);
my $parent_pid;
my $installed;
my $skip_all_in_effect;

# Call before `plan skip_all => ...` so the END block knows to suppress its
# segment/semaphore comparison tests (they'd add output after the "1..0 #
# SKIP" plan, corrupting the TAP stream). Test::Builder's internal Skip_All
# field is not reliably set by the time END runs, so we track it ourselves.
sub note_skip_all { $skip_all_in_effect = 1 }

sub import {
    return if $installed;
    $installed = 1;
    $parent_pid = $$;

    IPC::Shareable->testing_set($TESTING_DIST);

    # Safety net: a previous test file killed mid-run may have left this
    # dist's testing-tagged segments around. Sweep them before snapshotting
    # the baseline so cross-file contamination doesn't poison the END
    # comparison.
    eval { IPC::Shareable::clean_up_testing($TESTING_DIST) };

    $segs_before = IPC::Shareable::seg_count();
    $sems_before = IPC::Shareable::sem_count();

    warn "Segs Before: $segs_before\n" if $ENV{PRINT_SEGS};
    warn "Sems Before: $sems_before\n" if $ENV{PRINT_SEGS};
}

# Returns the number of additional SysV semaphore identifier sets the
# current platform can still allocate, or undef if the platform does not
# expose its semmni limit (e.g. Solaris). Tests can use this to skip or
# downscale work on platforms with tight kernel IPC budgets (FreeBSD's
# default semmni=50, OpenBSD's default semmni=10).
#
# Prefers IPC::Shareable::sysv_info()->{semmni} when the installed version
# is recent enough to expose it; otherwise falls back to a direct sysctl /
# /proc read so a stale CPAN IPC::Shareable doesn't prevent the headroom
# check from working.
sub available_sem_headroom {
    my $max  = _semmni();
    return undef unless defined $max;
    my $used = IPC::Shareable::sem_count();
    my $headroom = $max - $used;
    return $headroom < 0 ? 0 : $headroom;
}

sub _semmni {
    my $info = eval { IPC::Shareable->sysv_info };
    if (ref($info) eq 'HASH'
        && defined $info->{semmni}
        && $info->{semmni} =~ /^\d+$/) {
        return $info->{semmni};
    }

    if ($^O eq 'freebsd') {
        chomp(my $out = `sysctl -n kern.ipc.semmni 2>/dev/null`);
        return $out =~ /^(\d+)$/ ? $1 : undef;
    }
    elsif ($^O eq 'darwin') {
        chomp(my $out = `sysctl -n kern.sysv.semmni 2>/dev/null`);
        return $out =~ /^(\d+)$/ ? $1 : undef;
    }
    elsif ($^O eq 'openbsd') {
        chomp(my $out = `sysctl -n kern.seminfo.semmni 2>/dev/null`);
        return $out =~ /^(\d+)$/ ? $1 : undef;
    }
    elsif ($^O eq 'linux') {
        open my $fh, '<', '/proc/sys/kernel/sem' or return undef;
        chomp(my $line = <$fh>);
        close $fh;
        my @vals = split /\s+/, $line;
        return @vals >= 4 && $vals[3] =~ /^\d+$/ ? $vals[3] : undef;
    }
    return undef;
}

END {
    return unless $installed;
    return if $$ != $parent_pid;

    $SIG{CHLD} = 'DEFAULT';
    $? = 0;

    eval { Async::Event::Interval::_end() }
        if Async::Event::Interval->can('_end');
    eval { IPC::Shareable::_end() };

    eval { IPC::Shareable::clean_up_testing($TESTING_DIST) };

    # If the test file declared plan skip_all (e.g. low IPC headroom), the
    # "1..0 # SKIP" plan has already been emitted. Emitting additional
    # ok/not-ok lines and a second plan via done_testing() would corrupt the
    # TAP stream ("Bad plan. You planned 0 tests but ran 2.").
    return if $skip_all_in_effect;

    my $segs_after = IPC::Shareable::seg_count();
    my $sems_after = IPC::Shareable::sem_count();

    warn "Segs After: $segs_after\n" if $ENV{PRINT_SEGS};
    warn "Sems After: $sems_after\n" if $ENV{PRINT_SEGS};

    is $segs_after, $segs_before, "All segs cleaned up ok";
    is $sems_after, $sems_before, "All semaphore sets cleaned up ok";

    done_testing();
}

1;
