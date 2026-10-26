use v5.40;
use blib;
$|++;
use Acme::Parataxis qw[:all];
use File::Temp      qw[tempfile];
use IO::Socket::INET;
use Time::HiRes qw[time];

# Turning a synchronous database driver into an asynchronous one.
#
# A driver is synchronous because every call blocks: it writes a query, waits
# for the server, reads rows. A fiber that calls one of those directly does not
# just block itself, it blocks every other fiber in the interpreter, because
# they all share one OS thread. The fix is not a faster driver, it is a driver
# that parks instead of blocking: same wire protocol, same SQL, same rows --
# the difference is that "wait for the server" becomes await_read() rather than
# sysread(), and the waiting fiber is suspended rather than stalled.
#
# Both halves are measured here against a real database. The database is a
# separate perl process, because a single-threaded parataxis interpreter
# cannot host both the server and a blocking client -- which is precisely the
# problem being demonstrated. It is a plain non-blocking round-robin server, so
# it answers many connections at once and each answer costs QUERY_LATENCY_MS
# of wall time. The client talks to it twice:
#
#   1. the synchronous driver -- one connection, QUERIES queries in sequence,
#      every call blocking. Total time is QUERIES x latency.
#   2. the asynchronous driver -- the same code with a parked transport, one
#      connection per query, all in flight together. Total time is one
#      latency, because the waits overlap.
#
# The two must return byte-identical rows, and the demo dies nonzero unless
# they do, the row count is right, the waits really did overlap, and the
# parked run really was faster.
#
# The second run also parks many fibers inside one closure. read_reply() is a
# single CV, and every concurrent client enters it and suspends there, so the
# interpreter holds QUERIES frames of the same sub at once. That is the shape
# a shared subroutine takes whenever a fiber waits inside a helper rather than
# inside the fiber body, and it is the shape that used to leave a fabricated
# CvDEPTH behind and take the process down with "Can't undef active
# subroutine during global destruction" on the way out. INSIDE_MAX is
# measured rather than assumed: if the waits had not actually overlapped,
# the demo would report that instead of claiming a speedup.
my $QUERY_LATENCY_MS = 20;
my @QUERIES          = ( 1 .. 12, 1 .. 12 );    # 24, two rounds so the row count is 2 * 78
my $EXPECTED_ROWS    = 2 * ( 12 * 13 / 2 );
my $PORT             = 0;                       # set once the child reports the port it bound

# A child perl running a non-blocking, round-robin line server. It never forks
# and never threads, so this is the same shape on every platform; concurrency
# comes from holding each connection's answer until its own deadline instead of
# sleeping inside the accept loop.
my $SERVER = <<'CHILD';
use strict;
use warnings;
use IO::Socket::INET;
use IO::Select;
use Time::HiRes qw[time];

my ( $portfile, $latency_ms ) = @ARGV;
my $latency = $latency_ms / 1000;

# Deterministic answer, so both transports must see identical bytes and the
# demo can compare them exactly rather than approximately.
sub answer {
    my ($line) = @_;
    my $sql = $line;
    $sql =~ s/\AQUERY\s+//;
    return "0\n.\n" if $sql !~ /id\s*<=\s*(\d+)/;
    my @rows = map { "$_|name=widget-$_" } 1 .. $1;
    return join( '', scalar(@rows), "\n", ( map {"$_\n"} @rows ), ".\n" );
}

my $srv = IO::Socket::INET->new(
    LocalHost => '127.0.0.1', LocalPort => 0, Proto => 'tcp', Listen => 128, Reuse => 1
) or die "bind failed: $!";
$_->blocking(0) for $srv;

open my $pf, '>', $portfile or die "port file: $!";
print $pf $srv->sockport, "\n";
close $pf;

my $sel = IO::Select->new($srv);
my ( %buf, %due, $idle );
while (1) {
    for my $s ( $sel->can_read(0.02) ) {
        if ( $s == $srv ) {
            while ( my $c = $srv->accept ) {
                $c->blocking(0);
                $sel->add($c);
                $buf{ fileno $c } = '';
            }
            next;
        }
        my $fd = fileno $s;
        my $n  = sysread( $s, my $chunk, 65536 );
        if ( !defined $n || $n == 0 ) {
            $sel->remove($s);
            delete $buf{$fd};
            delete $due{$fd};
            close $s;
            next;
        }
        $buf{$fd} .= $chunk;
        while ( $buf{$fd} =~ s/\A(QUERY[^\n]*\n)// ) {
            $due{$fd} = [ $s, time() + $latency, $1 ];
        }
    }
    my $now = time();
    for my $fd ( keys %due ) {
        my ( $s, $at, $line ) = @{ $due{$fd} };
        next if $now < $at;
        delete $due{$fd};
        syswrite( $s, answer($line) );
    }
    if ( $sel->count > 1 ) { $idle = $now }
    elsif ( defined $idle ) { last if $now - $idle > 1.0 }
}
CHILD

# One driver, two transports. Everything above read_reply() is identical; the
# only difference in the whole file is whether a wait calls await_read() or
# sysread().
my ( $INSIDE, $INSIDE_MAX ) = ( 0, 0 );

sub dbh_connect {
    my ($transport) = @_;
    my $sock = IO::Socket::INET->new( PeerHost => '127.0.0.1', PeerPort => $PORT, Proto => 'tcp', Blocking => ( $transport eq 'block' ? 1 : 0 ) ) or
        return;
    $sock->autoflush(1);
    return { sock => $sock, transport => $transport, buf => '' };
}

# Ask for readiness, then write. The wait is the whole story in two lines.
sub _put {
    my ( $dbh, $str ) = @_;
    my $s   = $dbh->{sock};
    my $off = 0;
    while ( $off < length $str ) {
        if ( $dbh->{transport} eq 'block' ) {
            my $w = syswrite( $s, $str, length($str) - $off, $off );
            return 0 if !defined $w || $w == 0;
            $off += $w;
        }
        else {
            my $r = await_write( $s, 5000 );
            return 0 if !defined $r || $r <= 0;
            my $w = syswrite( $s, $str, length($str) - $off, $off );
            return 0 if !defined $w;
            $off += $w;
        }
    }
    return 1;
}

# One complete line, or undef at EOF.
sub _line {
    my ($dbh) = @_;
    my $s = $dbh->{sock};
    my $i;
    while ( ( $i = index( $dbh->{buf}, "\n" ) ) < 0 ) {
        if ( $dbh->{transport} eq 'block' ) {
            my $n = sysread( $s, my $chunk, 65536 );
            return if !defined $n || $n == 0;
            $dbh->{buf} .= $chunk;
        }
        else {
            my $r = await_read( $s, 5000 );
            return if !defined $r || $r <= 0;
            my $n = sysread( $s, my $chunk, 65536 );
            return if !defined $n || $n == 0;
            $dbh->{buf} .= $chunk;
        }
    }
    return substr( $dbh->{buf}, 0, $i + 1, '' );
}

# The blocking part of the driver, and the one CV every concurrent fiber enters
# and suspends inside. The counter opens before the first wait, so it brackets
# the whole residency of a fiber here rather than just the tail of it, and
# every exit runs through the single return so the count cannot drift.
sub read_reply {
    my ($dbh) = @_;
    $INSIDE++;
    $INSIDE_MAX = $INSIDE if $INSIDE > $INSIDE_MAX;
    my ( @rows, $ok );
    if ( defined( my $head = _line($dbh) ) ) {
        chomp $head;
        if ( $head =~ /\A[0-9]+\z/ ) {
            my $whole = 1;
            for ( 1 .. $head ) {
                my $l = _line($dbh);
                if ( !defined $l ) { $whole = 0; last }
                chomp $l;
                push @rows, $l;
            }
            my $end = $whole ? _line($dbh) : undef;
            $ok = $whole && defined $end && $end eq ".\n";
        }
    }
    $INSIDE--;
    return $ok ? \@rows : undef;
}

sub dbh_selectall {
    my ( $dbh, $sql ) = @_;
    return if !_put( $dbh, "QUERY $sql\n" );
    return read_reply($dbh);
}

sub dbh_disconnect {
    my ($dbh) = @_;
    close $dbh->{sock};
}
my ( $pfh, $ppath ) = tempfile( 'parataxis-db-XXXXXX', TMPDIR => 1, UNLINK => 1 );
close $pfh;

# The database program goes in a file, not on a -e. Handing a multi-line program
# to the child as one command-line argument means trusting the platform to keep
# the newlines through the round trip, and it does not: on Windows the argument
# is re-split and the child was handed "use" as its whole program, dying with
# "syntax error at -e line 1, at EOF". A file path cannot be mangled that way.
my ( $sfh, $spath ) = tempfile( 'parataxis-db-server-XXXXXX', TMPDIR => 1, UNLINK => 1 );
print $sfh $SERVER or die "cannot write the database program: $!";
close $sfh         or die "cannot write the database program: $!";
open my $child, '-|', $^X, $spath, $ppath, $QUERY_LATENCY_MS or die "cannot start the database: $!";
for ( 1 .. 200 ) {
    if ( open my $rfh, '<', $ppath ) {
        chomp( my $l = <$rfh> // '' );
        close $rfh;
        if ( $l && $l =~ /\A([0-9]+)\z/ ) { $PORT = $1; last }
    }
    select undef, undef, undef, 0.05;
}
die "the database never reported a port\n" if !$PORT;
say "parataxis database driver: talking to a blocking server on 127.0.0.1:$PORT";
say sprintf '  %d queries, %d rows expected, %dms server latency per query', scalar @QUERIES, $EXPECTED_ROWS, $QUERY_LATENCY_MS;
run(
    sub {
        # 1. The synchronous driver. One connection, every query in sequence,
        #    every call blocking the whole interpreter.
        my $t0 = time;
        my @blocking;
        my $dbh_block = dbh_connect('block') or die "connect: $!";
        for my $sql (@QUERIES) {
            my $rows = dbh_selectall( $dbh_block, "SELECT * FROM widgets WHERE id <= $sql" );
            die "the synchronous driver got no reply\n" if !$rows;
            push @blocking, @$rows;
        }
        dbh_disconnect($dbh_block);
        my $t_block = time() - $t0;
        say sprintf '  synchronous : %d rows in %6.3fs  (%.1fms per query, one call at a time)', scalar @blocking, $t_block,
            $t_block * 1000 / scalar @QUERIES;

        # 2. The asynchronous driver. Same protocol, same SQL, a parked
        #    transport, and one connection per query so every wait is in flight
        #    at the same time.
        ( $INSIDE, $INSIDE_MAX ) = ( 0, 0 );
        my $t1   = time;
        my @jobs = map {
            spawn(
                sub {
                    my $sql  = $QUERIES[$_];
                    my $dbh  = dbh_connect('park') or die "connect: $!";
                    my $rows = dbh_selectall( $dbh, "SELECT * FROM widgets WHERE id <= $sql" );
                    dbh_disconnect($dbh);
                    $rows;
                }
            );
        } 0 .. $#QUERIES;
        my @parked;
        for my $j (@jobs) {
            my $rows = $j->await;
            die "a parked query never came back\n" if !$rows;
            push @parked, @$rows;
        }
        my $t_park = time() - $t1;
        say sprintf '  asynchronous: %d rows in %6.3fs  (%.1fms per query, all in flight at once)', scalar @parked, $t_park,
            $t_park * 1000 / scalar @QUERIES;
        say sprintf '  %d fibers were resident in the one shared closure read_reply() at the same time', $INSIDE_MAX;
        say '';

        # 3. The point of the demo, and the self-test. The overlap is checked
        #    two ways on purpose: $INSIDE_MAX is the mechanism (fibers really
        #    were resident in the shared closure together) and is exact, while
        #    the wall clock is the consequence and is only given a loose bound
        #    so a loaded machine cannot make this flaky.
        my @bad;
        push @bad, "row count: got " . scalar(@parked) . ", expected $EXPECTED_ROWS" if @parked != $EXPECTED_ROWS;
        push @bad, 'the two transports returned different rows'                      if join( "\0", @blocking ) ne join( "\0", @parked );
        push @bad, "the waits never overlapped: only $INSIDE_MAX fiber(s) in the shared closure at once" if $INSIDE_MAX < 2;
        push @bad, sprintf 'no speedup: async %.3fs vs sync %.3fs', $t_park, $t_block if $t_park * 3 > $t_block;
        die "self-test failed:\n  - $_\n" for @bad;
        say sprintf '  identical rows from both transports: %d',                             scalar @parked;
        say sprintf '  %.1fx faster with the same server, the same SQL and the same result', $t_block / $t_park;
        say '  the only difference was await_read() where the driver used to call sysread().';
        stop();
    }
);
close $child;
my $reaped = 0;    # the database stops on its own once it has no clients left
for ( 1 .. 40 ) {
    $reaped = waitpid( $child, 1 );
    last if $reaped > 0;
    select undef, undef, undef, 0.05;
}
kill 'TERM', $child if !$reaped;
say 'exit 0';
