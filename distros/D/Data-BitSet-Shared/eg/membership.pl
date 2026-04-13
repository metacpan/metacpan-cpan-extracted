#!/usr/bin/env perl
# Membership tracking: track which user IDs are online across processes
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::BitSet::Shared;
$| = 1;

my $max_users = 1024;
my $online = Data::BitSet::Shared->new(undef, $max_users);

# simulate workers logging users in/out
my @pids;
for my $w (1..4) {
    my $pid = fork // die;
    if ($pid == 0) {
        srand($$ + $w);
        for (1..50) {
            my $uid = int(rand($max_users));
            $online->set($uid);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;

printf "online users: %d / %d\n", $online->count, $max_users;
printf "first online: uid %d\n", $online->first_set // "none";

# log out specific users
for my $uid (0, 10, 20) {
    if ($online->test($uid)) {
        $online->clear($uid);
        printf "logged out uid %d\n", $uid;
    }
}
printf "online after logout: %d\n", $online->count;
