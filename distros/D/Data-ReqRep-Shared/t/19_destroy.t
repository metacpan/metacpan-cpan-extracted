use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use POSIX ();
use Time::HiRes qw(sleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

my $S = 6;
sub fresh { my $s = Data::ReqRep::Shared->new_memfd('d', 16, $S, 64); ($s, $s->memfd) }
sub free_slots {
    my $c = Data::ReqRep::Shared::Client->new_from_fd($_[0]);
    my @id;
    while (defined(my $id = $c->send('probe'))) { push @id, $id }
    $c->cancel($_) for @id;
    scalar @id;
}

{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my @id = map { $c->send("r$_") } 1 .. 5;
    for (1 .. 3) { my ($r, $i) = $s->recv; $s->reply($i, $r) }
    $c->get($id[0]);
    $c->get($id[1]);
    undef $c;
    is free_slots($fd), $S, 'some replies read, some unread, some queued: all back after destroy';
}
{
    my ($s, $fd) = fresh();
    my $a = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my $b = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my $ida = $a->send('a');
    my ($r, $i) = $s->recv;
    $s->reply($i, $r);
    $b->send('b');
    ok defined $b->get($ida), 'one handle takes another handle\'s reply';
    undef $b;
    undef $a;
    is free_slots($fd), $S, '  and destroying both leaves nothing held';
}
{
    my ($s, $fd) = fresh();
    my $a = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my $b = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my $ida = $a->send('a');
    $b->send('b');
    undef $b;
    my ($r, $i) = $s->recv;
    ok $s->reply($i, $r), 'destroying one handle leaves another handle\'s request in flight';
    is $a->get($ida), 'a', '  for it to read';
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    for (1 .. 20) { my $id = $c->send('x'); my ($r, $i) = $s->recv; $s->reply($i, $r); $c->get($id) }
    $c->cancel($c->send('y'));
    undef $c;
    is free_slots($fd), $S, 'every request read or cancelled';
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    $c->send('q') for 1 .. 3;
    $s->clear;
    $c->send('z') for 1 .. 2;
    undef $c;
    is free_slots($fd), $S, 'requests sent after a clear are given back';
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) { close $r; $c->send('k') for 1 .. 2; undef $c; syswrite $w, 'x'; sleep 10; POSIX::_exit(0) }
    close $w;
    sysread($r, my $destroyed, 1) == 1 or die "the child died before destroying its handle";
    is free_slots($fd), $S, 'a forked child gives back what it sent when it destroys its copy';
    kill KILL => $pid;
    waitpid $pid, 0;
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) { syswrite $w, pack 'Q', $c->send('k'); POSIX::_exit(0) }
    sysread $r, my $buf, 8;
    waitpid $pid, 0;
    my ($m, $i) = $s->recv;
    $s->reply($i, $m);
    $c->send('p');
    ok defined $c->get(unpack 'Q', $buf), 'a parent takes the reply to what its child sent';
    undef $c;
    is free_slots($fd), $S, '  and destroying its handle gives back its own request';
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my $pid = fork // die $!;
    if (!$pid) { my $k = Data::ReqRep::Shared::Client->new_from_fd($fd); $k->send('d') for 1 .. $S; POSIX::_exit(0) }
    waitpid $pid, 0;
    ok defined $c->send('p'), 'a send takes a slot a dead process held';
    cmp_ok $s->stats->{recoveries}, '>=', 1, '  and counts it in recoveries';
    undef $c;
    is free_slots($fd), $S, '  and destroying the handle gives it back';
}
{
    my ($s, $fd) = fresh();
    my $c = Data::ReqRep::Shared::Client->new_from_fd($fd);
    my @id = map { $c->send("r$_") } 1 .. 2;
    $c->cancel($id[0]) for 1 .. 2;
    undef $c;
    is free_slots($fd), $S, 'a request cancelled twice: the other still given back on destroy';
}
{
    my ($s, $fd) = fresh();
    my $pid = fork // die $!;
    if (!$pid) { my $k = Data::ReqRep::Shared::Client->new_from_fd($fd); $k->send('d') for 1 .. $S; POSIX::_exit(0) }
    waitpid $pid, 0;
    $s->recv for 1 .. $S;
    is free_slots($fd), $S, 'slots of a dead client come back while a live server holds its requests';
}

done_testing;
