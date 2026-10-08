use strict;
use warnings;
use open IO => ":raw";
use Test::More;
use File::Temp ();
use File::Spec ();
use Cwd ();
use POSIX ();
use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# The croaks carry strerror in the process's locale; "$!" and the matches are
# English.
$ENV{LC_ALL} = 'C';
POSIX::setlocale(POSIX::LC_ALL(), 'C');

# Error paths no other test reaches.  Croaks are pinned by message, since with a
# guard gone a later check often still croaks in different words; silent ones by
# the object surviving.

my $dir = File::Temp::tempdir(CLEANUP => 1);
sub path { File::Spec->catfile($dir, "$_[0].shm") }

sub poke {
    my ($f, $off, $fmt, $v) = @_;
    open my $h, '+<', $f or die $!;
    sysseek($h, $off, 0);
    syswrite($h, pack($fmt, $v));
    close $h;
}

{
    my $m = Data::HashMap::Shared::II->new(path('full'), 2);
    my $n = 0;
    $n++ while $n < 10_000 && $m->put($n, $n);
    ok $n > 0 && $n < 10_000, "map filled to capacity at $n entries";
    is $m->max(0, 5), 5, 'max on an existing key works at capacity';
    ok !eval { $m->max(999_999, 5); 1 }, 'max on a new key croaks when the map is full';
    like $@, qr/\bmax failed: no room for a new key\b/, '  ...naming the failed operation and why';
    ok !eval { $m->min(888_888, 5); 1 }, 'min on a new key croaks when full';
    like $@, qr/\bmin failed: no room for a new key\b/, '  ...naming the failed operation and why';
    ok !eval { $m->decr(777_777); 1 }, 'decr on a new key croaks when full';
    like $@, qr/\bdecrement failed: no room for a new key\b/, '  ...naming the failed operation and why';
}

{
    ok !eval { Data::HashMap::Shared::II->unlink(); 1 }, 'unlink with no path croaks';
    like $@, qr/^Usage: Data::HashMap::Shared::II->unlink\(\$path\)/, '  ...with a usage message';

    # in a child: without the guard this dereferences the freed handle and
    # segfaults the harness
    my $p = path('u');
    my $st = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $m = Data::HashMap::Shared::II->new($p, 16);
            $m->DESTROY;
            eval { $m->unlink; 1 } and POSIX::_exit(20);
            POSIX::_exit($@ =~ /^Attempted to use a destroyed Data::HashMap::Shared::II object/ ? 0 : 21);
        }
        waitpid $pid, 0; $?;
    };
    is $st, 0, 'unlink on an explicitly destroyed handle croaks, naming the object'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
    ok(Data::HashMap::Shared::II->unlink($p), 'class-form unlink removes the file');
}

{
    my $p = path('gen');
    my $old = Data::HashMap::Shared::II->new($p, 16);
    { my $new = Data::HashMap::Shared::II->new("$p.tmp", 16); $new->put(1, 2) }
    rename "$p.tmp", $p or die "rename: $!";
    ok !$old->unlink, 'unlink leaves a map renamed over its path';
    is(Data::HashMap::Shared::II->new($p, 16)->get(1), 2, '  ...intact');

    my $home = Cwd::getcwd();
    my ($da, $db) = map { my $d = File::Spec->catdir($dir, $_); mkdir $d or die "mkdir $d: $!"; $d } qw(a b);
    chdir $da or die "chdir: $!";
    my $rel = Data::HashMap::Shared::II->new('rel.shm', 16);
    chdir $db or die "chdir: $!";
    open my $fh, '>', 'rel.shm' or die "open: $!";
    close $fh;
    ok !$rel->unlink, 'after a chdir, unlink leaves the file its relative path now names';
    ok -e 'rel.shm', '  ...which stays';
    chdir $da or die "chdir: $!";
    ok $rel->unlink, '  ...and removes its own once the path names it again';
    ok !-e 'rel.shm', '  ...which is gone';
    chdir $home or die "chdir: $!";
}

# DESTROY on a foreign invocant (t/45 covers put/get/size only).  Without the
# class check the victim is destroyed from under its owner; that does not crash
# (the zeroed IV makes the next call croak), so the oracle is that the victim
# still works.  In a child in case a regression crashes.
{
    my $st = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $ss = Data::HashMap::Shared::SS->new(path('foreign'), 64);
            $ss->put('k', 'v');
            eval { Data::HashMap::Shared::II::DESTROY($ss); 1 } or POSIX::_exit(22);
            POSIX::_exit((eval { $ss->size } // -1) == 1 ? 0 : 20);
        }
        waitpid $pid, 0; $?;
    };
    is $st, 0, 'II::DESTROY on an SS map leaves that map alive'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);

    my $cst = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            my $ss = Data::HashMap::Shared::SS->new(path('foreign_c'), 64);
            $ss->put('k', 'v');
            my $c = $ss->cursor;
            eval { Data::HashMap::Shared::II::Cursor::DESTROY($c); 1 } or POSIX::_exit(23);
            my @kv = eval { $c->next };
            POSIX::_exit(@kv == 2 && $kv[0] eq 'k' ? 0 : 21);
        }
        waitpid $pid, 0; $?;
    };
    is $cst, 0, 'II::Cursor::DESTROY on an SS cursor leaves that cursor alive'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $cst, $cst & 127, $cst >> 8);
}

# in a child: a copy that got through would free the handle under the original
{
    my $st = do {
        my $pid = fork // die "fork: $!";
        unless ($pid) {
            require Storable;
            my $ss = Data::HashMap::Shared::SS->new(path('storable'), 64);
            $ss->put('k', 'v');
            my $cur = $ss->cursor;
            my $n = 0;
            for my $obj ($ss, $cur) {
                my $class = ref $obj;
                for my $copy (\&Storable::dclone, \&Storable::freeze, \&Storable::nfreeze,
                              sub { $_[0]{held}->FREEZE('Sereal') }) {
                    $n++;
                    POSIX::_exit(30 + $n) if eval { $copy->({ held => $obj }); 1 };
                    POSIX::_exit(40 + $n)
                        unless $@ =~ /^\Q$class\E: a handle cannot be copied or serialised/;
                }
            }
            POSIX::_exit(($ss->get('k') // '') eq 'v' && ($cur->next)[0] eq 'k' ? 0 : 29);
        }
        waitpid $pid, 0; $?;
    };
    is $st, 0, 'Storable dclone, freeze and nfreeze, and FREEZE, croak on a map and on a cursor, naming the class'
        or diag sprintf('child status 0x%04x (signal %d, exit %d)', $st, $st & 127, $st >> 8);
}

# the CK_U32 arguments not covered by t/27 (max_entries) and t/14 (ttl,
# flush_expired_partial); drain's limit is clamped in UV space instead
{
    my @cases = (
        ['lru_max',     sub { Data::HashMap::Shared::II->new(undef, 64, 2**32) }],
        ['ttl_default', sub { Data::HashMap::Shared::II->new(undef, 64, 0, 2**32) }],
        ['lru_skip',    sub { Data::HashMap::Shared::II->new(undef, 64, 0, 0, 2**32) }],
        ['num_shards',  sub { Data::HashMap::Shared::II->new_sharded(path('s'), 2**32, 64) }],
    );
    for my $c (@cases) {
        my ($what, $run) = @$c;
        ok !eval { $run->(); 1 }, "new: $what of 2**32 is refused, not truncated";
        like $@, qr/\Q$what\E 4294967296 exceeds the maximum of 4294967295/,
            "  ...naming $what and the limit";
    }
    my $m = Data::HashMap::Shared::II->new(path('r'), 64);
    ok !eval { $m->reserve(2**32); 1 }, 'reserve: target of 2**32 is refused';
    like $@, qr/target 4294967296 exceeds the maximum of 4294967295/, '  ...naming target';
}

{
    for my $mode (-1, 2**33, 010000, 0120644) {
        my $p = path("mode$mode");
        ok !eval { Data::HashMap::Shared::II->new($p, 16, 0, 0, 0, 0, $mode); 1 },
            sprintf('new: file_mode %#o is refused', $mode);
        like $@, $mode < 0 ? qr/file_mode must not be negative/
                                  : qr/file_mode 0\d+ exceeds the maximum of 07777/, '  ...naming the limit';
        ok !-e $p, '  ...before any file is created';
    }
    ok !eval { Data::HashMap::Shared::II->new_sharded(path('smode'), 2, 16, 0, 0, 0, 0, -1); 1 },
        'new_sharded: file_mode -1 is refused';
    like $@, qr/file_mode must not be negative/, '  ...naming the limit';
    ok !eval { Data::HashMap::Shared::II->new(path('r'), 64, 0, 0, 0, 0, -1); 1 },
        'attaching an existing file checks file_mode too';
    my $p = path('mode0640');
    Data::HashMap::Shared::II->new($p, 16, 0, 0, 0, 0, 0640);
    is +(stat $p)[2] & 07777, 0640, 'a mode within range is applied exactly';
    my $copy = path('modecopy');
    ok eval { Data::HashMap::Shared::II->new($copy, 16, 0, 0, 0, 0, (stat $p)[2]); 1 },
        'a regular file\'s st_mode, type bits and all, is taken as a mode' or diag $@;
    is +(stat $copy)[2] & 07777, 0640, '  ...its permission bits applied';
}

{
    ok !eval { Data::HashMap::Shared::II->new_sharded(path('s4097'), 4097, 16); 1 },
        'new_sharded: more than 4096 shards is refused';
    like $@, qr/num_shards 4097 exceeds the maximum of 4096/, '  ...naming the limit';
    ok !-e path('s4097') . '.0', '  ...before any shard is created';
    my $one = Data::HashMap::Shared::II->new_sharded(path('s0'), 0, 16);
    ok -e path('s0') . '.0' && !-e path('s0') . '.1', 'new_sharded: 0 shards is taken as 1';
}

{
    my $q = Data::HashMap::Shared::SS->new(undef, 64);
    $q->put("j$_", $_) for 1 .. 10;
    my $pending = 12;
    ok !eval { $q->drain(10 - $pending); 1 }, 'drain with a negative limit croaks';
    like $@, qr/^Data::HashMap::Shared::SS: drain limit must not be negative/, '  ...saying why';
    ok !eval { my @b = shm_ss_drain $q, -1; 1 }, '  ...in keyword form too';
    is $q->size, 10, '  ...draining nothing';
    is scalar(my @b = $q->drain(3)), 6, 'a positive limit still drains that many';
}

{
    my $p = path('tiny');
    open my $fh, '>', $p or die $!; print $fh 'abc'; close $fh;
    ok !eval { Data::HashMap::Shared::II->new($p, 64); 1 }, 'new on a short file is refused';
    like $@, qr/file too small \(3 bytes, need \d+\)/, '  ...reporting both sizes';
    ok !eval { Data::HashMap::Shared::II->new_readonly($p); 1 },
        'new_readonly on a short file is refused';
    like $@, qr/file too small for header/, '  ...saying the header does not fit';
}

{
    for my $delta (-4096, 4096) {
        my $p = path("resized$delta");
        Data::HashMap::Shared::II->new($p, 64)->put(1, 1);
        my $size = -s $p;
        truncate $p, $size + $delta or die "truncate: $!";
        ok !eval { Data::HashMap::Shared::II->new($p, 64); 1 },
            sprintf('a file %s by 4096 bytes is refused', $delta < 0 ? 'truncated' : 'extended');
        like $@, qr/the file is @{[ $size + $delta ]} bytes but its header says $size/,
            '  ...naming both sizes';
    }

    my $f = path('resized_frozen');
    { my $m = Data::HashMap::Shared::II->new($f, 64); $m->put(1, 1); $m->freeze }
    my $size = -s $f;
    truncate $f, $size + 4096 or die "truncate: $!";
    ok !eval { Data::HashMap::Shared::II->new_readonly($f); 1 }, 'new_readonly refuses a resized frozen file';
    like $@, qr/the file is @{[ $size + 4096 ]} bytes but its header says $size/, '  ...naming both sizes';

    my $d = path('resized_fd');
    Data::HashMap::Shared::II->new($d, 64)->put(1, 1);
    $size = -s $d;
    truncate $d, $size + 4096 or die "truncate: $!";
    open my $fh, '+<', $d or die "open: $!";
    ok !eval { Data::HashMap::Shared::II->new_from_fd(fileno $fh); 1 }, 'new_from_fd refuses a resized file';
    like $@, qr/fd: the file is @{[ $size + 4096 ]} bytes but its header says $size/, '  ...naming both sizes';
}

{
    ok !eval { Data::HashMap::Shared::II->new_sharded('x' x 5000, 2, 16); 1 },
        'new_sharded refuses a prefix that overflows the shard path buffer';
    like $@, qr/shard path too long/, '  ...saying so';
    my $long = path('x' x 5000);
    my $toolong = do { local $! = POSIX::ENAMETOOLONG(); "$!" };
    ok !eval { Data::HashMap::Shared::II->new($long, 16); 1 },
        'new refuses a path longer than PATH_MAX';
    like $@, qr/\Q$toolong\E/, '  ...and its message keeps the reason';
    ok !eval { Data::HashMap::Shared::II->new_readonly($long); 1 }, '  ...as does new_readonly';
    like $@, qr/\Q$toolong\E/, '  ...keeping the reason';

    my $deep = File::Spec->catfile($dir, ('d' x 60) x 5, 'x.shm');   # ~300 bytes, in no directory
    my $noent = do { local $! = POSIX::ENOENT(); "$!" };
    ok !eval { Data::HashMap::Shared::II->new($deep, 16); 1 }, 'new under a missing directory fails';
    like $@, qr/\Q$noent\E/, '  ...and a path of 300 bytes does not crowd out the reason';
}

{
    my $p = path('wronly');
    Data::HashMap::Shared::II->new($p, 16);
    open my $w, '>>', $p or die $!;
    ok !eval { Data::HashMap::Shared::II->new_from_fd(fileno $w); 1 },
        'new_from_fd on a write-only descriptor is refused';
    my $badf = do { local $! = POSIX::EBADF(); "$!" };
    like $@, qr/read: \Q$badf\E/, '  ...naming the read error, not a foreign file';
}

SKIP: {
    my $target = path('linked');
    { my $m = Data::HashMap::Shared::II->new($target, 16); $m->put(1, 2); $m->freeze }
    my ($link, $dangling) = (path('link'), path('dangling'));
    skip 'no symlinks here', 6
        unless eval { symlink $target, $link } && symlink path('nowhere'), $dangling;
    ok !eval { Data::HashMap::Shared::II->new($link, 16); 1 }, 'new refuses a symlink to a map';
    like $@, qr/open\(\Q$link\E\): is a symbolic link/, '  ...saying that is what it is';
    ok !eval { Data::HashMap::Shared::II->new_readonly($link); 1 }, 'new_readonly refuses it too';
    like $@, qr/open\(\Q$link\E\): is a symbolic link/, '  ...in the same words';
    ok !eval { Data::HashMap::Shared::II->new($dangling, 16); 1 }, 'new refuses a dangling symlink';
    ok !-e path('nowhere'), '  ...without creating its target';
}

{
    my $p = path('lay');
    { my $m = Data::HashMap::Shared::II->new($p, 1024); $m->put(1, 2); }
    poke($p, 24, 'L', 8);                    # max_size: LRU arrays the file has no room for
    ok !eval { Data::HashMap::Shared::II->new($p, 1024); 1 },
        'attach refuses a header whose LRU/TTL arrays do not fit';
    like $@, qr/file too small for LRU\/TTL arrays/, '  ...naming the region';

    my $q = path('lay2');
    { my $m = Data::HashMap::Shared::II->new($q, 1024); $m->put(1, 2); }
    poke($q, 80, 'Q', 0);                    # reader_slots_off = 0
    ok !eval { Data::HashMap::Shared::II->new($q, 1024); 1 },
        'attach refuses a header with no reader_slots region';
    like $@, qr/reader_slots region missing or out of bounds/, '  ...naming the region';
}

{
    my $p = path('froz');
    { my $m = Data::HashMap::Shared::II->new($p, 64); $m->put(1, 2); $m->freeze }
    my $holder = fork // die "fork: $!";
    if (!$holder) { exec('sleep', '30') or POSIX::_exit(1) }
    poke($p, 128, 'L', 0x80000000 | $holder);   # another process, alive
    ok !eval { Data::HashMap::Shared::II->new_readonly($p); 1 },
        'new_readonly refuses a frozen file with a write in flight';
    like $@, qr/a write is still in flight on this frozen file \(pid $holder\); retry/,
        '  ...naming the live holder, not a crashed writer';
    kill KILL => $holder;
    waitpid $holder, 0;

    poke($p, 128, 'L', 0x80000000 | $$);        # our own pid, held by no thread of ours
    ok !eval { Data::HashMap::Shared::II->new_readonly($p); 1 },
        'new_readonly refuses one whose lock word holds our own pid';
    like $@, qr/left mid-update by a crashed writer/,
        '  ...as a crashed writer whose pid we reuse, not one to wait for';
}

SKIP: {
    skip 'an address-space limit starves a sanitizer runtime', 3
        if ($ENV{LD_PRELOAD} // '') =~ /san/;
    my $p = path('nomap');
    my $child = path('nomap_child');
    open my $fh, '>', $child or die $!;
    print $fh 'use Data::HashMap::Shared::SS; ',
        'print eval { Data::HashMap::Shared::SS->new($ARGV[0], 10_000_000) } ? "created" : $@;';
    close $fh;
    open my $ph, '-|', 'sh', '-c', 'ulimit -v 400000 && exec "$@" 2>&1', 'sh',
        $^X, (map "-I$_", @INC), $child, $p or die "sh: $!";
    my $out = do { local $/; <$ph> };
    close $ph;
    skip "the child died of signal @{[ $? & 127 ]} (a file size limit?)", 3 if $? & 127;
    like $out, qr/mmap\(.*\)/, 'a map larger than the address space refuses at mmap';
    ok -e $p, '  ...after creating its file';
    is -s $p, 0, '  ...which it leaves empty, not at its full size';
}

# Another user's create, caught between its open and its flock: the file is
# still empty and not ours to initialize, so the open must wait for that user.
# Two users take root.
SKIP: {
    skip 'needs root, to be a second user', 2 if $>;
    my $other = (getpwnam 'nobody')[2] // 65534;
    my $shared = File::Temp::tempdir(CLEANUP => 1);
    chmod 0777, $shared or die "chmod: $!";
    my $p = "$shared/raced.shm";
    pipe my $r, my $w or die "pipe: $!";
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        close $r;
        $> = $other;
        POSIX::_exit(9) unless $> == $other;
        open my $fh, '>', $p or POSIX::_exit(8);
        close $fh;
        syswrite $w, 'x';
        select undef, undef, undef, 0.01;
        my $m = eval { Data::HashMap::Shared::II->new($p, 16) } or POSIX::_exit(7);
        POSIX::_exit($m->put(1, 7) ? 0 : 6);
    }
    close $w;
    sysread $r, my $created, 1;
    my $m = eval { Data::HashMap::Shared::II->new($p, 16) };
    my $err = $@;
    waitpid $pid, 0;
    skip 'could not become another user with a file there', 2 if ($? >> 8) == 9 || ($? >> 8) == 8;
    ok $m, "an open that meets another user's empty file waits for that user to create the map"
        or diag $err, sprintf 'child status 0x%04x', $?;
    is $m && $m->get(1), 7, '  ...and attaches to it';
}

done_testing;
