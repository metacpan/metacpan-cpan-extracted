use strict;
use warnings;
use Test::More;
use Fcntl qw(F_GETFD FD_CLOEXEC);

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("cloe", 4);
my $fd = $p->memfd;

# FD_CLOEXEC flag via fcntl on a duped filehandle
open(my $fh, '<&=', $fd) or die "fdopen: $!";
my $flags = fcntl($fh, F_GETFD, 0);
ok defined $flags, "F_GETFD returned";
ok $flags & FD_CLOEXEC, "FD_CLOEXEC set on memfd";

# Exec-behavior proof: the fd should not survive exec in a subprocess
my $pid = fork // die "fork: $!";
if (!$pid) {
    exec("sh", "-c", "test -e /proc/self/fd/$fd && exit 10; exit 0") or exit 127;
}
waitpid $pid, 0;
my $exit = $? >> 8;
is $exit, 0, "fd $fd absent from exec'd child (exit=$exit)";

done_testing;
