use strict;
use warnings;
use open IO => ":raw";
use utf8;
use Test::More;
use Config;
use File::Temp qw(tempdir);
use Cwd ();
use POSIX ();
use Data::ReqRep::Shared;
use Data::ReqRep::Shared::Client;
use Data::ReqRep::Shared::Int;
use Data::ReqRep::Shared::Int::Client;

my $dir = tempdir(CLEANUP => 1);

subtest 'a path with a NUL byte is refused, never cut short' => sub {
    my $victim = "$dir/important.db";
    open my $fh, '>', $victim or die $!;
    close $fh;
    ok !eval { Data::ReqRep::Shared->unlink("$victim\0.shm"); 1 }, 'class unlink refuses it';
    ok -e $victim, '  and the file named by the part before the NUL survives';
    ok !eval { Data::ReqRep::Shared::Int->unlink("$victim\0.shm"); 1 }, 'Int class unlink too';
    ok -e $victim, '  and it still survives';

    ok !eval { Data::ReqRep::Shared->new("$dir/a.shm\0x", 4, 2, 64); 1 }, 'new refuses it';
    ok !-e "$dir/a.shm", '  and creates nothing';
    ok !eval { Data::ReqRep::Shared::Int->new("$dir/b.shm\0x", 4, 2); 1 }, 'Int new too';
    Data::ReqRep::Shared->new("$dir/c.shm", 4, 2, 64);
    ok !eval { Data::ReqRep::Shared::Client->new("$dir/c.shm\0x"); 1 }, 'Client new too';
    Data::ReqRep::Shared::Int->new("$dir/d.shm", 4, 2);
    ok !eval { Data::ReqRep::Shared::Int::Client->new("$dir/d.shm\0x"); 1 }, 'Int::Client new too';
};

{ package Сервер; our @ISA = ('Data::ReqRep::Shared') }

subtest 'constructors bless into the class they were called on' => sub {
    my $s = Сервер->new(undef, 4, 2, 64);
    is ref $s, 'Сервер', 'a UTF-8 class name is kept';
    is eval { $s->capacity }, 4, '  and its methods resolve';
    my $m = Data::ReqRep::Shared->new_memfd('m', 4, 2, 64);
    my $again = $m->new_memfd('n', 4, 2, 64);
    is ref $again, 'Data::ReqRep::Shared', 'called on an object, a constructor uses its class';
};

subtest 'file descriptor arguments must be descriptors' => sub {
    my $s  = Data::ReqRep::Shared->new_memfd('fd', 4, 2, 64);
    my $evsrv = Data::ReqRep::Shared->new(undef, 4, 2, 64);
    my $ev    = $evsrv->eventfd;
    for my $bad ([undef, 'undef'], [2**32 + 1, '2**32+1'], [-1, '-1'], ['3x', 'a non-number'], [\*STDOUT, 'a glob ref']) {
        ok !eval { $s->eventfd_set($bad->[0]); 1 }, "eventfd_set refuses $bad->[1]";
    }
    ok !eval { $s->eventfd_set($s->memfd); 1 }, 'eventfd_set refuses a descriptor that is not an eventfd';
    like $@, qr/not an eventfd/, '  and says so';
    ok eval { $s->eventfd_set($ev); 1 }, 'a real eventfd is accepted' or diag $@;
    ok !eval { Data::ReqRep::Shared::Client->new_from_fd($s->memfd + 2**32); 1 },
        'new_from_fd refuses a value that only truncates to an open descriptor';
};

subtest 'drain takes a count wider than 32 bits' => sub {
    my $s = Data::ReqRep::Shared->new_memfd('dr', 8, 8, 64);
    my $c = Data::ReqRep::Shared::Client->new_from_fd($s->memfd);
    $c->send("m$_") for 1 .. 3;
    is scalar(my @got = $s->drain(2**32)), 6, 'drain(2**32) takes all three messages';
};

subtest 'a segment larger than the address space croaks' => sub {
    plan skip_all => 'only a 32-bit address space can be exceeded cheaply' unless $Config{ptrsize} < 8;
    ok !eval { Data::ReqRep::Shared->new(undef, 16, 4097, 1 << 20); 1 }, 'Str';
    like $@, qr/layout overflow/, '  with the reason';
    ok !eval { Data::ReqRep::Shared::Int->new(undef, 16, 67108865); 1 }, 'Int';
    like $@, qr/layout overflow/, '  with the reason';
};

subtest 'every class reports the same stats keys; only Str has an arena' => sub {
    my $s = Data::ReqRep::Shared->new_memfd('st', 4, 2, 64);
    my $i = Data::ReqRep::Shared::Int->new_memfd('it', 4, 2);
    my %keys = map { ref($_) => join ' ', sort keys %{ $_->stats } }
        $s, Data::ReqRep::Shared::Client->new_from_fd($s->memfd),
        $i, Data::ReqRep::Shared::Int::Client->new_from_fd($i->memfd);
    is $keys{'Data::ReqRep::Shared::Client'}, $keys{'Data::ReqRep::Shared'}, 'Str client matches Str server';
    is $keys{'Data::ReqRep::Shared::Int'}, join(' ', grep { !/^arena_/ } split ' ', $keys{'Data::ReqRep::Shared'}),
        'Int server matches Str without arena_*';
    is $keys{'Data::ReqRep::Shared::Int::Client'}, $keys{'Data::ReqRep::Shared::Int'}, 'Int client matches Int server';
};

subtest 'a segment has to fit the 32-bit offsets its header keeps' => sub {
    local $ENV{DATA_REQREP_SHARED_SPARSE} = 1;   # refused before anything is reserved
    ok !eval { Data::ReqRep::Shared->new(undef, 16, 34_000_000, 64); 1 }, 'Str: over 4 GiB is refused';
    like $@, qr/layout overflow/, '  with the reason';
    ok !eval { Data::ReqRep::Shared::Int->new(undef, 16, 70_000_000); 1 }, 'Int too';
    like $@, qr/layout overflow/, '  with the reason';
};

subtest 'resp_slots must fit a signed 32-bit index' => sub {
    ok !eval { Data::ReqRep::Shared->new(undef, 16, 2**31, 1); 1 }, 'Str: 2**31 slots croak before mapping anything';
    like $@, qr/layout overflow/, '  with the reason';
    ok !eval { Data::ReqRep::Shared::Int->new(undef, 16, 2**31); 1 }, 'Int too';
};

for my $v (['Str', 'Data::ReqRep::Shared', 'Data::ReqRep::Shared::Client', [64], 'ping', 'pong'],
           ['Int', 'Data::ReqRep::Shared::Int', 'Data::ReqRep::Shared::Int::Client', [], 41, 42]) {
    my ($name, $sc, $cc, $extra, $q, $a) = @$v;
    subtest "$name: an anonymous channel serves a forked client" => sub {
        my $srv = $sc->new(undef, 4, 2, @$extra);
        cmp_ok $srv->memfd, '>=', 0, 'it has a descriptor to attach by';
        pipe my $r, my $w or die $!;
        my $pid = fork // die $!;
        if (!$pid) {
            close $r;
            my $got = eval { $cc->new_from_fd($srv->memfd)->req_wait($q, 5) };
            syswrite $w, defined $got ? $got : "failed: $@";
            POSIX::_exit(0);
        }
        close $w;
        my ($req, $id) = $srv->recv_wait(5);
        $srv->reply($id, $a) if defined $id;
        waitpid $pid, 0;
        is do { local $/; <$r> }, $a, 'the child gets its reply';
    };
}

subtest "an id's reply is taken by whichever process reads it" => sub {
    my $srv = Data::ReqRep::Shared->new_memfd('fk', 4, 2, 64);
    my $cli = Data::ReqRep::Shared::Client->new_from_fd($srv->memfd);
    my $id = $cli->send('q');
    my (undef, $rid) = $srv->recv;
    $srv->reply($rid, 'r');
    pipe my $r, my $w or die $!;
    my $pid = fork // die $!;
    if (!$pid) { close $r; syswrite $w, $cli->get($id) // 'undef'; POSIX::_exit(0) }
    close $w;
    waitpid $pid, 0;
    is do { local $/; <$r> }, 'r', 'a forked child reading the id gets the reply';
    is $cli->get($id), undef, '  and the parent then gets undef';
    is $cli->pending, 0, '  with the slot freed';
};

subtest 'a generation that wraps skips 0, so no request id is ever 0' => sub {
    for my $v (['Str', 'Data::ReqRep::Shared', 'Data::ReqRep::Shared::Client', [64]],
               ['Int', 'Data::ReqRep::Shared::Int', 'Data::ReqRep::Shared::Int::Client', []]) {
        my ($name, $sc, $cc, $extra) = @$v;
        my $p = "$dir/genwrap$name.shm";
        $sc->new($p, 4, 1, @$extra);
        open my $fh, '+<', $p or die $!;
        binmode $fh;
        seek $fh, 44, 0; read $fh, my $off, 4; $off = unpack 'L', $off;
        seek $fh, $off, 0; print {$fh} pack 'Q', 0xFFFF_FFFF << 32 | 31 << 3;
        close $fh;
        my $id = $cc->new($p)->send($name eq 'Str' ? 'x' : 1);
        ok $id, "$name: the send after generation 2**32-1 gets a non-zero id";
        is $id >> 32, 1, '  with generation 1';
    }
};

{
    package Fetches;
    sub TIESCALAR { bless { v => $_[1], n => 0 }, $_[0] }
    sub FETCH { $_[0]{n}++; $_[0]{v} }
}
subtest 'a tied path or timeout is fetched once' => sub {
    my $fetches = sub { my ($v, $code) = @_; tie my $t, 'Fetches', $v; $code->($t); tied($t)->{n} };
    my $p = "$dir/tied.shm";
    my ($srv, $cli, $int, $icli);
    is $fetches->($p, sub { $srv = Data::ReqRep::Shared->new($_[0], 16, 4, 64) }), 1, 'Str new';
    is $fetches->($p, sub { $cli = Data::ReqRep::Shared::Client->new($_[0]) }), 1, 'Str Client->new';
    is $fetches->(0.01, sub { $srv->recv_wait($_[0]) }), 1, 'recv_wait';
    is $fetches->(0.01, sub { $srv->recv_wait_multi(2, $_[0]) }), 1, 'recv_wait_multi';
    is $fetches->(2, sub { $srv->drain($_[0]) }), 1, 'drain';
    is $fetches->(0.01, sub { $cli->get_wait($cli->send('x'), $_[0]) }), 1, 'get_wait';
    is $fetches->(0.01, sub { $cli->send_wait('x', $_[0]) }), 1, 'send_wait';
    is $fetches->(0.01, sub { $cli->req_wait('x', $_[0]) }), 1, 'req_wait';
    is $fetches->($p, sub { Data::ReqRep::Shared->unlink($_[0]) }), 1, 'class unlink';
    my $ip = "$dir/tied_int.shm";
    is $fetches->($ip, sub { $int = Data::ReqRep::Shared::Int->new($_[0], 16, 4) }), 1, 'Int new';
    is $fetches->($ip, sub { $icli = Data::ReqRep::Shared::Int::Client->new($_[0]) }), 1, 'Int Client->new';
    is $fetches->(0.01, sub { $int->recv_wait($_[0]) }), 1, 'Int recv_wait';
    is $fetches->(0.01, sub { $icli->get_wait($icli->send(7), $_[0]) }), 1, 'Int get_wait';
    is $fetches->(0.01, sub { $icli->send_wait(7, $_[0]) }), 1, 'Int send_wait';
    is $fetches->(0600, sub { Data::ReqRep::Shared::Int->new("$dir/tied_mode.shm", 16, 4, $_[0]) }), 1, 'Int mode';
    is $fetches->(0600, sub { Data::ReqRep::Shared->new("$dir/tied_smode.shm", 16, 4, 64, 0, $_[0]) }), 1, 'Str mode';
    is $fetches->(8192, sub { Data::ReqRep::Shared->new("$dir/tied_arena.shm", 16, 4, 64, $_[0]) }), 1, 'Str arena';
};

{
    package Runs;
    sub TIESCALAR { bless { run => $_[1], v => $_[2] }, $_[0] }
    sub FETCH { $_[0]{run}->(); $_[0]{v} }
}
subtest 'a constructor reads each argument after magic on the others has run' => sub {
    my $cwd = Cwd::getcwd();
    chdir $dir or die $!;
    for my $int (0, 1) {
        my $name = $int ? 'Int' : 'Str';
        # Growing the string moves its buffer: a pointer taken before the magic would dangle.
        my $path = "$dir/" . ('p' x 40) . '.shm';
        tie my $mode, 'Runs', sub { $path = 'Z' x 4096 }, 0600;
        my $h = eval { $int ? Data::ReqRep::Shared::Int->new($path, 16, 4, $mode) : Data::ReqRep::Shared->new($path, 16, 4, 64, undef, $mode) };
        like $@, qr/create Z{64}/, "$name new: the path as the mode's magic left it";
        my $label = 'channel-' . ('n' x 40);
        tie my $cap, 'Runs', sub { $label = 'Z' x 4096 }, 16;
        $h = eval { $int ? Data::ReqRep::Shared::Int->new_memfd($label, $cap, 4) : Data::ReqRep::Shared->new_memfd($label, $cap, 4, 64) };
        like $@, qr/memfd_create/, "$name new_memfd: the name as the capacity's magic left it";
    }
    chdir $cwd or die $!;
    my $fds = sub { opendir my $d, '/proc/self/fd' or die $!; scalar grep /^\d+$/, readdir $d };
    my $before = $fds->();
    for (1 .. 20) {
        my $reads = 0;
        tie my $class, 'Runs', sub { die "unreadable\n" if ++$reads == 2 }, 'Data::ReqRep::Shared';
        eval { $class->new(undef, 4, 4, 64) };
    }
    is $fds->(), $before, 'a class whose reading dies leaks no channel';
};

subtest 'an arena not a multiple of 8 is rounded up, and a request of its full size fits' => sub {
    for my $arena (4096, 4097, 4103, 5000) {
        my $s = Data::ReqRep::Shared->new("$dir/arena_$arena.shm", 16, 4, 64, $arena);
        my $cap = $s->stats->{arena_cap};
        is $cap % 8, 0, "$arena: arena_cap $cap is a multiple of 8";
        cmp_ok $cap, '>=', $arena, '  and not below the value asked for';
        my $c = Data::ReqRep::Shared::Client->new("$dir/arena_$arena.shm");
        ok defined eval { $c->send('x' x $cap) }, "  a request of exactly $cap bytes queues" or diag $@;
    }
    ok !eval { Data::ReqRep::Shared->new(undef, 16, 4, 64, 2**32 - 7); 1 },
        'an arena that would round past 32 bits is refused';
    like $@, qr/layout overflow/, '  as a layout overflow';
};

done_testing;
