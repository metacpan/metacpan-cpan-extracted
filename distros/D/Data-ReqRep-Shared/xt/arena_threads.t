use strict;
use warnings;
use Config;
BEGIN {
    unless ($Config{useithreads}) { require Test::More; Test::More::plan(skip_all => 'needs a perl with ithreads') }
}
use threads;
use threads::shared;
use Test::More;
use POSIX ();
use File::Temp qw(tempdir);
use Time::HiRes qw(time sleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $q = tempdir(CLEANUP => 1) . '/threads.shm';
my @g = ($q, 64, 64, 16, 4096);
my $s = Data::ReqRep::Shared->new(@g);
my $stop = time + 15;
my $d = fork // die $!;
if (!$d) {
    my $r = Data::ReqRep::Shared->new(@g);
    while (time < $stop) { $r->recv_wait(0.1); sleep 0.02 }
    POSIX::_exit(0);
}
my $done :shared = 0;
my @t = map {
    threads->create(sub {
        my $sc = Data::ReqRep::Shared::Client->new($q);
        while (!$done && time < $stop) { my $id = $sc->send_wait('s' x 100, 1); $sc->cancel($id) if defined $id }
        return;
    })
} 1 .. 4;
sleep 0.5;
my $bc = Data::ReqRep::Shared::Client->new($q);
my $t0 = time;
my $id = $bc->send_wait('B' x 3000, 8);
my $took = time - $t0;
$done = 1;
$_->join for @t;
ok defined $id, sprintf 'a request needing most of the arena gets in while sibling threads send small ones (%.1f s)', $took;
kill KILL => $d;
waitpid $d, 0;

done_testing;
