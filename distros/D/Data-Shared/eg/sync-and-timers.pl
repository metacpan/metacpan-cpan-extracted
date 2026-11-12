#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Shared qw(shared_call);

my $root = Data::Shared->new;
sub mount_or_skip {
    my ($name, @spec) = @_;
    my $h = eval { $root->mount($name, @spec) };
    return $h if $h;
    die $@ unless $@ =~ /is not available; install the/;
    print "skip $name: $@";
    return;
}

if (mount_or_skip('sem', 'sync:semaphore', undef, 2)) {
    print "sem try_acquire: ", shared_call($root, '/sem', 'try_acquire'), "\n";
    shared_call($root, '/sem', 'release');
    print "sem released\n";
}
if (mount_or_skip('once', 'sync:once', undef)) {
    if (shared_call($root, '/once', 'enter')) {
        print "once: running init\n";
        shared_call($root, '/once', 'done');
    }
}
if (mount_or_skip('timers', 'timingwheel', undef, 512, 1000)) {
    shared_call($root, '/timers', 'add', 5, 1001);
    my @due = shared_call($root, '/timers', 'advance', 5);
    print "timers due: @due\n";
}
if (mount_or_skip('htimers', 'hiertimingwheel', undef, 256, 4, 1000)) {
    shared_call($root, '/htimers', 'add', 5, 1002);
    my @due = shared_call($root, '/htimers', 'advance', 5);
    print "hier timers due: @due\n";
}
