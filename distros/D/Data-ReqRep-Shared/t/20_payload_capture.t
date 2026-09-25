use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp 'tmpnam';
use POSIX ();
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;

for my $method (qw(send_wait send_wait_notify req req_wait)) {
    my $path = tmpnam();
    my $srv = Data::ReqRep::Shared->new($path, 16, 1, 256);
    pipe my $held_r, my $held_w or die;
    pipe my $ran_r, my $ran_w or die;
    my $holder = fork // die "fork: $!";
    if (!$holder) {
        close $ran_w;
        my $c = Data::ReqRep::Shared::Client->new($path);
        my $id = $c->send("holder") // POSIX::_exit(9);
        syswrite $held_w, "x";
        sysread $ran_r, my $b, 1;
        $c->cancel($id);
        POSIX::_exit(0);
    }
    close $ran_r;
    sysread $held_r, my $b, 1;
    my $server;
    if ($method =~ /^req/) {
        $server = fork // die "fork: $!";
        if (!$server) {
            for (1 .. 2) { my ($d, $id) = $srv->recv_wait(30); last unless defined $d; $srv->reply($id, $d) }
            POSIX::_exit(0);
        }
    }
    my $cli = Data::ReqRep::Shared::Client->new($path);
    local $SIG{USR1} = sub { "k=handler" =~ /=(\w+)/ and my $v = $1; syswrite $ran_w, "x" };
    my $killer = fork // die "fork: $!";
    if (!$killer) {
        my $w = Data::ReqRep::Shared::Client->new($path);
        for (1 .. 6000) { last if $w->stats->{slot_waiters}; select undef, undef, undef, 0.01 }
        kill USR1 => getppid;
        POSIX::_exit(0);
    }
    my $got;
    if ("GET caller" =~ /^GET (\w+)/) {
        $got = $method eq 'send_wait'        ? ($cli->send_wait($1, 30), undef)[1]
             : $method eq 'send_wait_notify' ? ($cli->send_wait_notify($1, 30), undef)[1]
             : $method eq 'req'              ? $cli->req($1)
             :                                 $cli->req_wait($1, 30);
    }
    waitpid $_, 0 for grep defined, $killer, $holder, $server;
    if ($method =~ /^send/) { my @d = map { ($srv->recv)[0] } 1 .. 2; ($got) = grep { defined && $_ ne 'holder' } @d }
    is $got, 'caller', "$method: a \$1 payload is sent as the caller's capture";
    $srv->unlink;
}

done_testing;
