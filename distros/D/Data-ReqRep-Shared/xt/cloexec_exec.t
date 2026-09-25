use strict;
use warnings;
no warnings 'exec';
use Test::More;
use POSIX qw(_exit);
use Data::ReqRep::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};
plan skip_all => 'requires /proc/self/fd' unless -d "/proc/self/fd";

my $q = Data::ReqRep::Shared->new_memfd("cloexec_test", 64, 32, 64);
my $memfd = $q->memfd;
ok $memfd >= 0, 'got memfd';

my $st_parent = (stat "/proc/self/fd/$memfd")[1];

my $pid = fork // die;
if ($pid == 0) {
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
