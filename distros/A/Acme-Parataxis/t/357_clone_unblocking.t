use v5.40;
use blib;
use Test2::V1 -ipP;
use Config;
use IO::Socket::INET;
use Acme::Parataxis qw[run fiber await_sleep];

# Deferred so skip_all below can run before perl tries to load threads on a perl that has no thread support. threads->create itself is the "spawn a cloned interpreter" primitive that spawn_blocking wraps; the corruption it demonstrates is in the clone, not in Blocking's marshalling, so this test never has to load Acme::Parataxis::Blocking at all.
my $CAN_CLONE = ( defined $Config{useithreads} && $Config{useithreads} eq 'define' ) && eval {
    require threads;
    require threads::shared;
    1;
};
skip_all 'cloning a scheduled interpreter requires an ithreads perl', 1 unless $CAN_CLONE;

# Transparent unblocking has to be installed before the test bodies below are compiled, or their read()/sysread()
# calls would bind to the raw builtins and the whole point of the test disappears. Top level (fid -1) delegates to
# CORE::, so this INSTALLED prefix pollutes nothing by itself.
BEGIN { Acme::Parataxis->enable_transparent_unblocking }
$|++;
my $PAYLOAD_MB = do {
    ( defined $ENV{PARATAXIS_SB_PAYLOAD_MB} && $ENV{PARATAXIS_SB_PAYLOAD_MB} =~ /\A[1-9][0-9]*\z/ ) ? int( $ENV{PARATAXIS_SB_PAYLOAD_MB} ) : 4;
};

sub socket_pair {
    my $server = IO::Socket::INET->new( LocalAddr => '127.0.0.1', LocalPort => 0, Listen => 8, ReuseAddr => 1 ) or die "listen: $!";
    my $client = IO::Socket::INET->new( PeerAddr  => '127.0.0.1:' . $server->sockport )                         or die "connect: $!";
    my $conn   = $server->accept or die "accept: $!";
    return ( $client, $conn );
}

# Run one clone. $park controls whether a fiber is parked inside the read override (awaiting data on a socket that is
# empty until the writer fires $delay ms in) while threads->create duplicates the interpreter. Returns (rc, buf,
# joined): the read's byte count and payload, and what the cloned worker returned.
sub run_one_clone {
    my ($park) = @_;
    my $expected = $PAYLOAD_MB * 1_048_576;
    my ( $rc, $buf, $joined );
    run(
        sub {
            my ( $client, $conn ) = socket_pair();
            if ($park) {
                my $reader = fiber {
                    $rc = read( $conn, $buf, 7 );    # parks inside CORE::GLOBAL::read with a live pad until data arrives
                    1;
                };
                my $writer = fiber {
                    await_sleep(400);
                    syswrite $client, 'framed!';
                    1;
                };
                await_sleep(50);    # the reader is guaranteed parked before the clone below
                my $worker = threads->create( sub { length( 'x' x $expected ) } );
                $joined = $worker->join;
                $writer->await;
                $reader->await;
            }
            else {
                my $worker = threads->create( sub { length( 'x' x $expected ) } );
                $joined = $worker->join;
            }
        }
    );
    return ( $rc, $buf, $joined );
}

# The payload size goes in the subtest name so every run says which size it actually exercised. A green run that
# silently fell back to the default is the exact failure this test cannot otherwise catch: it passed at 4 MB while
# the corruption was still live, and a misconfigured CI env var would have reproduced that invisibly.
subtest "a scheduled interpreter can be cloned at ${PAYLOAD_MB} MB with the overrides on, nothing parked" => sub {
    my ( $rc, $buf, $joined ) = run_one_clone(0);
    is $joined, $PAYLOAD_MB * 1_048_576, 'the cloned interpreter returned the payload length';
    is $rc,     undef,                   'no read happened, so no read result exists';
    is $buf,    undef,                   'the read buffer was never touched';
};

# Every warning a scheduled interpreter clone can leak, trapped so a pre-fix build FAILS on the documented symptoms
# ("Attempt to free unreferenced scalar", "Use of uninitialized value $ready in numeric lt (<)") instead of merely
# crashing in the middle of the file. The documented 4 MiB build was still "returning the right answer" while
# printing these; a test that only checked the answer would have let the corruption in.
my @leaked;
$SIG{__WARN__} = sub { push @leaked, $_[0] };
subtest 'cloning while a fiber is parked inside the read override leaves the heap intact' => sub {
    my $before = scalar @leaked;
    my ( $rc, $buf, $joined ) = run_one_clone(1);
    is $joined,        $PAYLOAD_MB * 1_048_576, 'the clone ran to completion while the read was parked';
    is $rc,            7,                       'the parked read was not clobbered by the clone';
    is $buf,           'framed!',               'the read payload is intact';
    is scalar @leaked, $before,                 'no interpreter-leak warning escaped the parked clone' or diag join q{}, @leaked;
};
#
done_testing();
