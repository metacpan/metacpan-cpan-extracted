use Test2::V0;
use Atomic::Pipe;

my ($r, $w) = Atomic::Pipe->pair;

$w->write_message("hello");
is($r->read_message, "hello", "intact message ok");

# A truncated header: fewer raw bytes than the 16-byte message header, then
# EOF. This must raise, not read as a clean EOF (silent data loss).
syswrite($w->wh, "\x01\x02\x03\x04\x05\x06\x07\x08") or die "syswrite: $!";
$w->close;

like(
    dies {
        # First call may consume the partial bytes before EOF is visible.
        $r->read_message for 1 .. 5;
    },
    qr/invalid state/i,
    "truncated header at EOF throws instead of looking like clean EOF",
);

# A truncated payload: an intact 16-byte header claiming more bytes than
# arrive before EOF. Must also raise, not return undef as if EOF were clean.
my ($r3, $w3) = Atomic::Pipe->pair;
syswrite($w3->wh, pack('l2L2', $$, 0, 0, 100) . 'AAAAA') or die "syswrite: $!";
$w3->close;

like(
    dies {
        $r3->read_message for 1 .. 5;
    },
    qr/invalid state/i,
    "truncated payload at EOF throws instead of reading as clean EOF",
);

# Clean EOF (no trailing garbage) still reads as undef.
my ($r2, $w2) = Atomic::Pipe->pair;
$w2->write_message("x");
$w2->close;
is($r2->read_message, "x",   "got message");
is($r2->read_message, undef, "clean EOF returns undef");

done_testing;
