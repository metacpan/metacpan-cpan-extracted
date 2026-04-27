use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

BEGIN {
    eval { require AnyEvent; 1 } or plan skip_all => "AnyEvent required";
    AnyEvent->import;
}

use Data::Sync::Shared;

# AnyEvent with whatever backend is available — verifies the fd is
# genuinely epoll/poll-compatible across event loop backends.

my $sem = Data::Sync::Shared::Semaphore->new(undef, 1);
$sem->acquire;
my $efd = $sem->eventfd;

my $pid = fork // die;
if ($pid == 0) {
    select undef, undef, undef, 0.1;
    $sem->release;
    $sem->notify;
    _exit(0);
}

my $cv = AnyEvent->condvar;
my $saw = 0;
my $w = AnyEvent->io(fh => $efd, poll => 'r', cb => sub {
    $sem->eventfd_consume;
    $saw++;
    $cv->send;
});
my $timer = AnyEvent->timer(after => 3, cb => sub { $cv->send });

$cv->recv;
undef $w;
undef $timer;

waitpid $pid, 0;

is $saw, 1, 'AnyEvent reactor woke on child notify';
diag "AnyEvent backend: " . (AnyEvent::detect());

done_testing;
