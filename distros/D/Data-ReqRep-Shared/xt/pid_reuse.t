use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Temp qw(tempdir);

# A pid a dead channel user had, taken again by a live process, forced through ns_last_pid as
# pid 1 of a private user and pid namespace.

plan skip_all => 'Linux only' unless $^O eq 'linux';
system(q{unshare -Urpf --mount-proc sh -c 'echo 1999 > /proc/sys/kernel/ns_last_pid' >/dev/null 2>&1}) == 0
    or plan skip_all => 'needs unshare -Urpf --mount-proc and a writable ns_last_pid';

my $root = dirname(dirname(abs_path(__FILE__)));
my $dir  = tempdir(CLEANUP => 1);
open my $fh, '>', "$dir/child.pl" or die $!;
print {$fh} <<'P';
use strict; use warnings; use POSIX ();
use Data::ReqRep::Shared; use Data::ReqRep::Shared::Client;
$| = 1;
my ($mode, $p) = @ARGV;
sub fork_at {
    my ($pid, $code) = @_;
    open my $f, '>', '/proc/sys/kernel/ns_last_pid' or die $!;
    print {$f} $pid - 1;
    close $f;
    my $k = fork // die $!;
    if (!$k) { $code->(); POSIX::_exit(0) }
    die "got pid $k, wanted $pid\n" if $k != $pid;
    return $k;
}
my $srv = Data::ReqRep::Shared->new($p, 16, $mode eq 'emfile' ? 2 : 8, 64);
if ($mode eq 'emfile') {
    # A channel user that died left its record; the process that gets its pid registers first
    # with its descriptor table full, so it cannot read its own start time.
    waitpid fork_at(3000, sub { Data::ReqRep::Shared::Client->new($p)->pending }), 0;
    select undef, undef, undef, 0.1;
    my $cli = Data::ReqRep::Shared::Client->new($p);
    pipe my $r, my $w or die $!;
    my $b = fork_at(3000, sub {
        close $r;
        my @fill;
        while (defined(my $fd = POSIX::dup(0))) { push @fill, $fd }
        my $id = $cli->send('b');
        POSIX::close($_) for @fill;
        syswrite $w, 'x';
        my $resp = $cli->get_wait($id, 4);
        print 'b=', $resp // 'undef', "\n";
    });
    close $w;
    sysread $r, my $go, 1;
    my $c = Data::ReqRep::Shared::Client->new($p);
    $c->send('c');
    print 'steal=', defined $c->send('c2') ? 1 : 0, "\n";
    while (my ($m, $id) = $srv->recv) { $srv->reply($id, "re:$m") }
    waitpid $b, 0;
}
elsif ($mode eq 'throttle') {
    # A client registers first with its descriptor table full, sends the moment descriptors free
    # up, and dies holding its only slot. It must be on record by then, or the process that gets
    # its pid keeps that slot.
    my $m = Data::ReqRep::Shared->new_memfd('throttle', 16, 1, 64);
    pipe my $r, my $w or die $!;
    my $k = fork // die $!;
    if (!$k) {
        close $r;
        my @fill;
        while (defined(my $fd = POSIX::dup(0))) { push @fill, $fd }
        POSIX::close(pop @fill) for 1 .. 2;   # one for the handle, one for /proc but not its stat
        my $c = Data::ReqRep::Shared::Client->new_from_fd($m->memfd);
        POSIX::close($_) for @fill;
        defined $c->send('k') or POSIX::_exit(1);
        syswrite $w, 'x';
        POSIX::_exit(0);
    }
    close $w;
    sysread $r, my $sent, 1;
    waitpid $k, 0;
    select undef, undef, undef, 0.05;          # start times count in clock ticks: give q another
    my $q = fork_at($k, sub { sleep 5 });
    my $ok = defined Data::ReqRep::Shared::Client->new_from_fd($m->memfd)->send('p');
    print 'sent=', $sent // '', ' next_send=', $ok ? 1 : 0, "\n";
    kill 'KILL', $q;
    waitpid $q, 0;
}
elsif ($mode eq 'name') {
    # A client with a notification socket dies, leaving a forked child that still holds the socket.
    my $a = fork_at(4000, sub {
        my $c = Data::ReqRep::Shared::Client->new($p);
        $c->ready_fd;
        fork // die $! or do { sleep 3; POSIX::_exit(0) };
    });
    waitpid $a, 0;
    waitpid fork_at(4000, sub {
        my $fd = eval { Data::ReqRep::Shared::Client->new($p)->ready_fd };
        print 'ready_fd=', defined $fd ? 'ok' : "croaked: $@", "\n";
    }), 0;
}
P
close $fh;

# A small descriptor limit keeps filling and freeing the table quick.
sub in_namespace {
    my ($mode) = @_;
    return scalar qx{unshare -Urpf --mount-proc sh -c 'ulimit -n 64 && exec "\$@"' sh $^X -I$root/blib/lib -I$root/blib/arch $dir/child.pl $mode $dir/$mode.shm 2>&1};
}

my $out = in_namespace('emfile');
like $out, qr/^b=re:b$/m, 'a live process that reused a dead one\'s pid, registering with no descriptor left, gets its reply'
    or diag $out;
like $out, qr/^steal=0$/m, '  and keeps its slot' or diag $out;

$out = in_namespace('throttle');
like $out, qr/^sent=x next_send=1$/m, 'a client that registered short of descriptors is on record before its first send'
    or diag $out;

$out = in_namespace('name');
like $out, qr/^ready_fd=ok$/m, 'a reused pid binds its notification socket beside a dead client\'s still held by a child'
    or diag $out;

done_testing;
