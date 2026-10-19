use Test2::V0;
use Atomic::Pipe;

# get_line_burst_or_data must never spin inside a single call. A message
# truncated by EOF must throw (poisoned pipe), and a message still in flight
# on a non-blocking pipe must return empty so the caller can select() and
# retry. Both cases used to loop forever inside one call.

# Capture the real wire bytes of one mixed-mode message so the replays below
# use genuine framing.
my $wire = do {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    $w->write_message('A' x 100);
    $w->close;
    my ($bytes, $buf) = ('', '');
    $bytes .= $buf while sysread($r->rh, $buf, 1024);
    $bytes;
};
ok(length($wire) > 100, "captured the on-wire form of a 100-byte message");

# Cut mid-payload: past the prefix+key+header (18 bytes) but well short of
# the end.
my $cut = 30;

# A single call that used to hang; the alarm turns a regression into a test
# failure instead of a stuck suite.
sub one_call {
    my ($pipe) = @_;
    local $SIG{ALRM} = sub { die "SINGLE CALL DEADLINE EXCEEDED\n" };
    alarm 10;
    my @got = eval { $pipe->get_line_burst_or_data };
    my $err = $@;
    alarm 0;
    return ($err, @got);
}

subtest truncated_message_at_eof_throws => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    syswrite($w->wh, substr($wire, 0, $cut)) or die "syswrite: $!";
    $w->close;
    $r->blocking(0);

    my ($err) = one_call($r);
    unlike($err, qr/DEADLINE/, "the call returned instead of spinning");
    like($err, qr/invalid state/i, "a message truncated by EOF throws");
};

subtest partial_message_pre_eof_returns_empty => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    syswrite($w->wh, substr($wire, 0, $cut)) or die "syswrite: $!";
    $r->blocking(0);

    my ($err, @got) = one_call($r);
    unlike($err, qr/DEADLINE/, "the call returned instead of spinning");
    is($err, '', "no exception while the writer is still alive");
    ok(!@got, "returned empty: nothing complete yet, caller may retry");

    # Deliver the rest; the reassembled message must come through intact.
    syswrite($w->wh, substr($wire, $cut)) or die "syswrite: $!";
    ($err, @got) = one_call($r);
    is($err, '', "no exception once the message completed");
    my %got = @got;
    is($got{message}, 'A' x 100, "the completed message arrived intact");
};

subtest partial_burst_pre_eof_returns_empty => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    syswrite($w->wh, "\x0Epartial-burst-without-terminator") or die "syswrite: $!";
    $r->blocking(0);

    my ($err, @got) = one_call($r);
    is($err, '', "no exception");
    ok(!@got, "a burst still in flight returns empty");
};

done_testing;
