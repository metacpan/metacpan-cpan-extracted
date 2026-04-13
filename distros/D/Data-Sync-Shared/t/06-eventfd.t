use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Data::Sync::Shared;

# Test eventfd on all 5 primitive types

for my $spec (
    ['Data::Sync::Shared::Semaphore', sub { $_[0]->new(undef, 5) }],
    ['Data::Sync::Shared::Barrier',   sub { $_[0]->new(undef, 2) }],
    ['Data::Sync::Shared::RWLock',    sub { $_[0]->new(undef) }],
    ['Data::Sync::Shared::Condvar',   sub { $_[0]->new(undef) }],
    ['Data::Sync::Shared::Once',      sub { $_[0]->new(undef) }],
) {
    my ($class, $ctor) = @$spec;
    (my $short = $class) =~ s/.*:://;

    my $obj = $ctor->($class);
    ok $obj, "$short: created";

    # fileno before eventfd
    is $obj->fileno, -1, "$short: fileno -1 before eventfd";

    # Create eventfd
    my $fd = $obj->eventfd;
    ok $fd >= 0, "$short: eventfd returns valid fd";
    is $obj->fileno, $fd, "$short: fileno matches";

    # Notify + consume
    ok $obj->notify, "$short: notify";
    ok $obj->notify, "$short: notify again";
    my $v = $obj->eventfd_consume;
    is $v, 2, "$short: consume returns accumulated count";

    # Consume on empty returns undef (non-blocking)
    is $obj->eventfd_consume, undef, "$short: consume on empty returns undef";

    # eventfd_set with external fd (from a different object)
    my $obj2 = $ctor->($class);
    my $fd2 = $obj2->eventfd;
    ok $fd2 >= 0, "$short: external eventfd";
    $obj->eventfd_set($fd2);
    is $obj->fileno, $fd2, "$short: eventfd_set updates fileno";
}

# Cross-process eventfd via fork (Semaphore)
{
    my $sem = Data::Sync::Shared::Semaphore->new(undef, 3);
    my $fd = $sem->eventfd;

    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        # Child inherits both the mmap and the eventfd
        $sem->try_acquire;
        $sem->notify;
        _exit(0);
    }
    waitpid($pid, 0);

    is $sem->value, 2, 'cross-process: child acquired one permit';
    my $v = $sem->eventfd_consume;
    ok defined $v && $v >= 1, 'cross-process: child notify received by parent';
}

done_testing;
