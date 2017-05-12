#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;
use Danga::Socket;
use Socket;

############################################################
### Test Loop Timeout and PostLoopCallback

my ($t1, $t2, $iters);

$t1 = time();
$iters = 0;

Danga::Socket->SetLoopTimeout(250);
Danga::Socket->SetPostLoopCallback(sub {
    $iters++;
    return $iters < 4 ? 1 : 0;
});

Danga::Socket->EventLoop;

$t2 = time();

ok($iters == 4,    "four iters");
ok($t2 >= $t1 + 1, "took a second (or maybe a bit more)");
ok($t2 <= $t1 + 2, "took less than 2 seconds");


############################################################
### Test Timers

# use a hash of timers to provide some randomisation
my %timers = map { $_ => 1 } (0 .. 5);
my $timers = keys %timers;
for my $n (keys %timers) {
    Danga::Socket->AddTimer($n,
        sub {
            $timers--;
            my $t3 = time();
            ok($t3 >= $t2 + $n, "took $n seconds (or maybe a bit more)");
            ok($t3 <= $t2 + $n + 1, "took less than $n + 1 seconds");
        });
}

Danga::Socket->SetPostLoopCallback(sub { return $timers });

Danga::Socket->EventLoop;

############################################################
### Test Per Object PostLoopCallbacks

socketpair(Rdr, Wtr, AF_UNIX, SOCK_STREAM, PF_UNSPEC);
my $reader = Danga::Socket->new(\*Rdr);
my $writer = Danga::Socket->new(\*Wtr);
print "# reader: $reader\n# writer: $writer\n";
my $reader_fired = 0;
my $writer_fired = 0;
$reader->SetPostLoopCallback(sub {
    my Danga::Socket $self = shift;
    ok(1, "reader PLC fired");
    $reader_fired++;
    return $reader_fired && $writer_fired ? 0 : 1;
    });
$writer->SetPostLoopCallback(sub {
    my Danga::Socket $self = shift;
    ok(1, "writer PLC fired");
    $writer_fired++;
    return $reader_fired && $writer_fired ? 0 : 1;
    });
Danga::Socket->EventLoop;
