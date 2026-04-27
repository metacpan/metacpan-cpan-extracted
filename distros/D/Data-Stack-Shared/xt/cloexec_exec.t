use strict;
use warnings;
no warnings 'exec';
use Test::More;
use POSIX qw(_exit);
use Data::Stack::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires /proc/self/fd' unless -d "/proc/self/fd";

# memfd_create(..., MFD_CLOEXEC) should mean the fd doesn't appear in
# a post-exec() child. Verify by forking + execing a perl that lists
# its own /proc/self/fd and asserting the memfd isn't there.

my $q = Data::Stack::Shared::Int->new_memfd("cloexec_test", 64);
my $memfd = $q->memfd;
ok $memfd >= 0, 'got memfd';

# Record the inode of our memfd so the child can identify it
my $st_parent = (stat "/proc/self/fd/$memfd")[1];

my $pid = fork // die;
if ($pid == 0) {
    # Child: exec a perl that lists its open fds and exits with 0 if
    # none of them shares the inode of the parent's memfd.
    my $parent_inode = $st_parent;
    exec $^X, '-e', q{
        my $pinode = $ARGV[0];
        my @fds = glob("/proc/self/fd/*");
        for my $fd (@fds) {
            my $inode = (stat $fd)[1];
            next unless defined $inode;
            if ($inode == $pinode) {
                # Leaked! Exit non-zero.
                exit 1;
            }
        }
        exit 0;
    }, $parent_inode;
    _exit(127);
}
waitpid($pid, 0);
is $? >> 8, 0, 'memfd (CLOEXEC) not inherited across exec';

done_testing;
