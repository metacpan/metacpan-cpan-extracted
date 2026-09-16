use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(usleep);
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

# A request whose deadline expires while the server is replying used to leave
# its slot held: the reply was mid-copy (RESP_WRITING), where neither cancel
# nor the drain could see it, and a stale reply's transient WRITING also made
# an unused slot's release give up. Each strands a slot under a live owner,
# which death-based recovery never reclaims -- enough of them and every send
# fails with "no slots". pending() must be back to 0 after every req_wait.

my $dir = tempdir(CLEANUP => 1);

sub server_loop {
    my ($srv, $reply) = @_;
    my $pid = fork // die "fork: $!";
    return $pid if $pid;
    $SIG{TERM} = sub { exit 0 };
    while (1) {
        my ($v, $id) = $srv->recv;
        $srv->reply($id, $reply->($v)) if defined $id;
    }
}

{
    my $path = "$dir/int.shm";
    my $srv  = Data::ReqRep::Shared::Int->new($path, 64, 8);
    my $pid  = server_loop($srv, sub { $_[0] + 1 });
    my $cli  = Data::ReqRep::Shared::Int::Client->new($path);
    $cli->req_wait($_, 1e-9) for 1 .. 20_000;
    is $cli->pending, 0, 'Int: no slot left held after 20000 deadline-expired req_wait';
    kill TERM => $pid; waitpid $pid, 0;
}

{
    my $path = "$dir/str.shm";
    my $srv  = Data::ReqRep::Shared->new($path, 64, 16, 1 << 20);
    my $big  = 'r' x (1 << 20);
    my $pid  = server_loop($srv, sub { $big });
    my $cli  = Data::ReqRep::Shared::Client->new($path);
    my $noslot = 0;
    for (1 .. 1500) {
        # Expires while the 1 MiB reply is being copied into the slot.
        my $r = $cli->req_wait('x', (10 + rand 300) / 1e6);
        $noslot++ if !defined $r && $cli->pending >= 16;
    }
    is $cli->pending, 0, 'Str: no slot left held when deadlines expire mid-copy';
    is $noslot, 0, 'Str: the slots never ran out';
    kill TERM => $pid; waitpid $pid, 0;
}

done_testing;
