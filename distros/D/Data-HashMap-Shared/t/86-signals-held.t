use strict;
use warnings;
use Test::More;
use POSIX ();
use Time::HiRes ();
use File::Temp ();

use Data::HashMap::Shared::II;
use Data::HashMap::Shared::SS;

# Perl croaks a call from inside its C signal handler once 120 signals are
# pending.  Out of a long pass under the write lock that leaves the lock held by
# a live process nobody can recover, so such a pass blocks signals until the
# lock is released.  Each pass runs in a child under a timer firing 240 times
# (480 for a large result built after the lock is dropped); meanwhile another
# process must get the lock.  Outside the lock the call may still be croaked,
# having done all of its work or none. The same timer must first croak a long
# call that blocks nothing, keys, or the case skips.

my $dir = File::Temp::tempdir(CLEANUP => 1);
my $n = 300_000;
my @ii = map { ($_, $_) } 1 .. $n;
my @ss = map { ("key-$_", "value-$_") } 1 .. $n;
my @more = map { ("key-$_", "value-$_") } $n + 1 .. $n + 4095;
my @scattered = map { 'key-' . 73 * $_ } 1 .. 4095;

# One child per group runs its cases in turn, after the group's wait:
# [ name, class, constructor arguments after the path, fill, the pass,
#   the map with the pass done, the map with it not begun, timer fires ]
my $expired = sub { $_[0]->set_multi(@ii) };
my $empty   = sub { $_[0]->size == 0 };
my $never   = sub { 0 };
my @groups = (
    [ 0,
      [ 'reserve, a table resize', 'II', [ 4 * $n ],
        sub { $_[0]->set_multi(@ii) },
        sub { $_[0]->reserve(3 * $n) },
        sub { $_[0]->size == $n && $_[0]->get($n) == $n }, $never ],
      [ 'set_multi', 'II', [ 4 * $n ],
        sub { $_[0]->put(-1, -1); $_[0]->reserve($n + 1) },   # no resize to hold for it
        sub { $_[0]->set_multi(@ii) },
        sub { $_[0]->size == $n + 1 && $_[0]->get($n) == $n },
        sub { $_[0]->size == 1 } ],
      [ 'remove_multi', 'II', [ 4 * $n, 4 * $n ],             # LRU: a heavier remove
        sub { $_[0]->set_multi(@ii) },
        sub { $_[0]->remove_multi(2 .. $n) },
        sub { $_[0]->size == 1 && $_[0]->get(1) == 1 },
        sub { $_[0]->size == $n } ],
      # a few thousand entries scattered over a large table cost a page fault each
      [ 'set_multi of 4095 entries', 'SS', [ 4 * $n, 4 * $n ],
        sub { $_[0]->set_multi(@ss); $_[0]->reserve($n + 4096) },
        sub { $_[0]->set_multi(@more) },
        sub { $_[0]->size == $n + 4095 && $_[0]->get('key-' . ($n + 4095)) eq 'value-' . ($n + 4095) },
        sub { $_[0]->size == $n } ],
      [ 'remove_multi of 4095 entries', 'SS', [ 4 * $n, 4 * $n ],
        sub { $_[0]->set_multi(@ss) },
        sub { $_[0]->remove_multi(@scattered) },
        sub { $_[0]->size == $n - 4095 && $_[0]->get('key-1') eq 'value-1' },
        sub { $_[0]->size == $n } ],
      [ 'drain of 4095 entries', 'II', [ 4 * $n, 4 * $n ],
        sub { $_[0]->set_multi(@ii) },
        sub { my @kv = $_[0]->drain(4095) },
        sub { $_[0]->size == $n - 4095 },
        sub { $_[0]->size == $n } ],
      [ 'drain', 'II', [ 4 * $n ],
        sub { $_[0]->set_multi(@ii) },
        sub { my @kv = $_[0]->drain($n - 1) },
        sub { $_[0]->size == 1 },
        sub { $_[0]->size == $n } ],
      [ 'compact, an arena slide', 'SS', [ 4 * $n ],
        sub { $_[0]->set_multi(map { ("key-$_", "value-$_") } 1 .. $n);
              $_[0]->remove_multi(map { "key-$_" } grep { $_ % 2 } 1 .. $n) },
        sub { $_[0]->compact },
        sub { $_[0]->size == $n / 2 && $_[0]->get("key-$n") eq "value-$n" }, $never ],
    ],
    # every entry of these has expired by the time of the pass
    [ 2.1,
      [ 'flush_expired', 'II', [ 4 * $n, 0, 1 ],
        sub { $_[0]->put_ttl(-1, -1, 0); $_[0]->set_multi(@ii) },
        sub { $_[0]->flush_expired },
        sub { $_[0]->size == 1 && $_[0]->get(-1) == -1 }, $never ],
      [ 'pop, sweeping expired entries',             'II', [ 4 * $n, 0, 1 ],      $expired,
        sub { my @kv = $_[0]->pop },       $empty, $never ],
      [ 'shift, sweeping expired entries',           'II', [ 4 * $n, 0, 1 ],      $expired,
        sub { my @kv = $_[0]->shift },     $empty, $never ],
      [ 'a short drain, sweeping expired entries',   'II', [ 4 * $n, 0, 1 ],      $expired,
        sub { my @kv = $_[0]->drain(10) }, $empty, $never ],
      [ 'pop, sweeping an expired LRU list',         'II', [ 4 * $n, 4 * $n, 1 ], $expired,
        sub { my @kv = $_[0]->pop },       $empty, $never ],
      [ 'shift, sweeping an expired LRU list',       'II', [ 4 * $n, 4 * $n, 1 ], $expired,
        sub { my @kv = $_[0]->shift },     $empty, $never ],
      [ 'a short drain, sweeping an expired LRU list', 'II', [ 4 * $n, 4 * $n, 1 ], $expired,
        sub { my @kv = $_[0]->drain(10) }, $empty, $never ],
    ],
    # one batch fills this, so it is over its load when every entry expires
    [ 4.1,
      [ 'a put that flushes an overloaded TTL table and compacts it', 'II', [ $n, 0, 3 ],
        sub { $_[0]->set_multi(@ii, map { ($_, $_) } $n + 1 .. $n + $n / 3) },
        sub { $_[0]->put_ttl(-1, -1, 0) },
        sub { $_[0]->size == 1 && $_[0]->get(-1) == -1 }, $never ],
    ],
);

# A call that has to read the map back from disk can be croaked anywhere, lock
# held or not.
sub read_bytes {
    open my $fh, '<', '/proc/self/io' or return 0;
    local $/;
    return <$fh> =~ /^read_bytes:\s*(\d+)/m ? $1 : 0;
}

# Run $code in a child under a timer of $period; a croak from the signal handler
# can leave the interpreter broken, so a croaked process runs nothing else.
# Returns 10 if croaked, 0 if it returned, 1 if it died otherwise, -1 if perl
# itself died.  With a pipe pair the child reports r, c, e, or m (croaked after
# reading from disk, so a held lock is not the pass's fault) and waits for the
# parent's answer.
sub under_timer {
    my ($period, $code, $report, $answer) = @_;
    my $pid = fork // die "fork: $!";
    unless ($pid) {
        open STDERR, '>', '/dev/null';
        $SIG{ALRM} = sub { };
        my $read = read_bytes();
        Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), $period, $period);
        my $ok = eval { $code->(); 1 };
        my $how = $ok ? 'r' : $@ =~ /Maximal count of pending signals/ ? 'c' : 'e';
        Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0, 0);
        $how = 'm' if $how eq 'c' && read_bytes() > $read;
        if ($report) {
            syswrite $report, $how;
            sysread $answer, my $ack, 1;     # alive, while the parent probes the lock
        }
        POSIX::_exit({ r => 0, c => 10, m => 10, e => 1 }->{$how});
    }
    waitpid $pid, 0;
    return $? & 127 ? -1 : $? >> 8;
}

# Bytes, not slots: an arena of many megabytes behind a small table, and a
# batch of a few large values.  Author runs only: they write about a gigabyte.
if ($ENV{AUTHOR_TESTING}) {
    my $quarter = 256 << 10;
    my @big = map { ("big$_", 'x' x (1 << 20)) } 1 .. 48;
    push @groups, [ 0,
      [ 'compact, a large arena behind a small table', 'SS', [ 1000, 0, 0, 0, 128 << 20 ],
        sub { $_[0]->set_multi(map { ("k$_", chr(65 + $_ % 26) x $quarter) } 1 .. 200);
              $_[0]->remove_multi(map { "k$_" } grep { $_ % 2 } 1 .. 200) },
        sub { $_[0]->compact },
        sub { $_[0]->size == 100 && $_[0]->get('k200') eq chr(65 + 200 % 26) x $quarter }, $never ],
      [ 'set_multi of a few large values', 'SS', [ 1000, 0, 0, 0, 128 << 20 ],
        sub { $_[0]->put('k0', 'v') },
        sub { $_[0]->set_multi(@big) },
        sub { $_[0]->size == 49 && length $_[0]->get('big48') == 1 << 20 },
        sub { $_[0]->size == 1 } ],
    ];

    # a value of 40 MB copied out, or compared, under the write lock
    my $mb = 1 << 20;
    my $huge = 'x' x (40 * $mb);
    my @lru = (1000, 1000, 0, 0, 128 << 20);
    my $fill = sub { $_[0]->put('huge', $huge) };
    my $gone = sub { $_[0]->size == 0 };
    my $kept = sub { length($_[0]->get('huge') // '') == 40 * $mb };
    my $swapped = sub { ($_[0]->get('huge') // '') eq 'v' };
    push @groups, [ 0,
      [ 'take of a large value',       'SS', \@lru, $fill, sub { $_[0]->take('huge') },               $gone, $kept, 480 ],
      [ 'pop of a large value',        'SS', \@lru, $fill, sub { my @kv = $_[0]->pop },               $gone, $kept, 480 ],
      [ 'shift of a large value',      'SS', \@lru, $fill, sub { my @kv = $_[0]->shift },             $gone, $kept, 480 ],
      [ 'drain of a large value',      'SS', \@lru, $fill, sub { my @kv = $_[0]->drain(1) },          $gone, $kept, 480 ],
      [ 'cas_take of a large value',   'SS', \@lru, $fill, sub { $_[0]->cas_take('huge', $huge) },    $gone, $kept, 480 ],
      [ 'swap of a large value',       'SS', \@lru, $fill, sub { $_[0]->swap('huge', 'v') },          $swapped, $kept, 480 ],
      [ 'get_or_set of a large value', 'SS', \@lru, $fill, sub { $_[0]->get_or_set('huge', 'v') },   $kept, $kept, 480 ],
      [ 'cas against a large value',   'SS', \@lru, $fill, sub { $_[0]->cas('huge', $huge, 'v') },    $swapped, $kept ],
      # a key of 40 MB hashed and compared under the write lock
      [ 'put of a large key',    'SS', \@lru, sub { $_[0]->put('k0', 'v') }, sub { $_[0]->put($huge, 'v') },
        sub { $_[0]->size == 2 }, sub { $_[0]->size == 1 }, 480 ],    # the hash is its first half
      [ 'remove of a large key', 'SS', \@lru, sub { $_[0]->put($huge, 'v') }, sub { $_[0]->remove($huge) },
        $gone, sub { $_[0]->size == 1 } ],
    ];

    # each expiry frees blocks on cold pages of the arena, so a slice of 4095
    # slots of a dense table takes milliseconds
    my $dense = 390 * 1000;
    push @groups, [ 4.1,
      [ 'flush_expired_partial of 4095 slots of an LRU map', 'SS', [ 4 * $dense, 4 * $dense, 3 ],
        sub { my $m = shift;
              $m->set_multi(map { ("key-$_", "value-$_" . 'v' x 64) } $_ * 1000 + 1 .. $_ * 1000 + 1000)
                  for 0 .. $dense / 1000 - 1 },
        sub { $_[0]->flush_expired_partial(4095) },
        sub { $_[0]->size < $dense }, sub { $_[0]->size == $dense } ],
    ];
}

my $file = 0;
for my $group (@groups) {
    my ($wait, @cases) = @$group;
    my @path = map { "$dir/" . $file++ . '.shm' } @cases;
    pipe my $from_child, my $to_parent or die "pipe: $!";
    pipe my $from_parent, my $to_child or die "pipe: $!";

    my $pid = fork // die "fork: $!";
    unless ($pid) {
        close $from_child; close $to_child;
        for my $i (0 .. $#cases) {
            my (undef, $cls, $args, $fill) = @{ $cases[$i] };
            $fill->("Data::HashMap::Shared::$cls"->new($_, @$args)) for "$path[$i].twin", $path[$i];
        }
        # the control call must last about as long as a pass, or the period it
        # sets croaks a batch while it is still reading its arguments
        my $listed = Data::HashMap::Shared::II->new(undef, 4 * $n);
        $listed->set_multi(@ii, map { $_ + $n } @ii);
        Time::HiRes::sleep($wait) if $wait;
        for my $i (0 .. $#cases) {
            my (undef, $cls, $args, undef, $pass, undef, undef, $fires) = @{ $cases[$i] };
            # a fresh handle: the fill left its own with a flush back-off
            my $twin = "Data::HashMap::Shared::$cls"->new("$path[$i].twin", @$args);
            my $t = Time::HiRes::time(); $pass->($twin);          my $took = Time::HiRes::time() - $t;
            $t    = Time::HiRes::time(); my @k = $listed->items;  my $ctl  = Time::HiRes::time() - $t;
            @k = ();
            # never above 100 kHz: a pass runs up to 16 entries or 256 slots
            # between two looks for signals, which must stay well short of 120
            # periods
            my $floor = 1e-5;
            my $period = ($took < $ctl ? $took : $ctl) / ($fires // 240);
            $period = $floor if $period < $floor;
            my $croaks = sub { my $r = under_timer($period, sub { my @all = $listed->items }); $r == 10 || $r < 0 };
            $period = $period / 2 < $floor ? $floor : $period / 2 unless $croaks->();
            unless ($croaks->()) {
                syswrite $to_parent, 's';
                sysread $from_parent, my $ack, 1;
                next;
            }
            my $status = under_timer($period, sub {
                $pass->("Data::HashMap::Shared::$cls"->new($path[$i], @$args));
            }, $to_parent, $from_parent);
            if ($status < 0) {
                syswrite $to_parent, 'x';
                sysread $from_parent, my $ack, 1;
            }
        }
        POSIX::_exit(0);
    }
    close $to_parent; close $from_parent;

    for my $i (0 .. $#cases) {
        my ($name, $cls, $args, undef, undef, $done, $not_begun, $fires) = @{ $cases[$i] };
        $fires //= 240;
        my $class = "Data::HashMap::Shared::$cls";
        sysread $from_child, my $how, 1;
        $how //= '';

        my $probed;
        unless ($how =~ /^[sx]$/) {
            my $probe = fork // die "fork: $!";
            unless ($probe) {
                alarm 30;
                my $m = $class->new($path[$i], @$args);
                # remove's answer is not asked: a key of a 1 s TTL can expire
                # between the two calls, and remove then takes it out as expired
                POSIX::_exit($m->put(-7, -7) ? do { $m->remove(-7); 0 } : 3);
            }
            waitpid $probe, 0;
            $probed = $?;
        }

        SKIP: {
            skip "$name: the timer could not croak a long call here", 3 if $how eq 's';
            skip "$name: perl itself died after croaking the call", 3 if $how eq 'x';
            skip "$name: croaked holding the lock while the map was read back from disk", 3
                if $how eq 'm' && $probed;
            $how = 'c' if $how eq 'm';
            like $how, qr/^[rc]$/, "$name under a timer firing $fires times returns, or is croaked by it";
            is $probed, 0, '  ... and leaves the lock free while its process lives';
            skip 'the lock is held: the map cannot be read', 1 if $probed;
            my $m = $class->new($path[$i], @$args);
            ok $done->($m) || $how eq 'c' && $not_begun->($m), '  ... having done all of its work, or none';
        }
        syswrite $to_child, 'k';
    }
    kill KILL => $pid;
    waitpid $pid, 0;
}

done_testing;
