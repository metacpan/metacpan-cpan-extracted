#!perl -T

use Test::More tests => 9;
use Acme::RFC4824;

use Data::Dumper;

my $sfss = Acme::RFC4824->new();
ok(defined $sfss, 'New object creation');

my $test_packet = pack('H*','450000405c1740004006c8500a2581020a2581040185800a0023c8ea61a8d55db012ffff56fe0000020405b4010303000101080a59d6325b0004bbca04020000');

my $ascii = $sfss->encode({
    PACKET => $test_packet,
    TYPE   => 'ASCII',
});
if ($ENV{DEBUG}) {
    diag "ASCII string: $ascii\n";
}
# test correct ASCII representation
is($ascii, 'QBAAAEFAAAAEAFMBHEAAAEAAGMIFAAKCFIBACAKCFIBAEABIFIAAKAACDMIOKGBKINFFNLABCPPPPFGPOAAAAACAEAFLEABADADAAABABAIAKFJNGDCFLAAAELLMKAEACAAAAAAAAR', 'Correct ASCII representation');

my $ascii_art_string = $sfss->encode({
    PACKET => $test_packet,
    TYPE   => 'ASCII art',
});
if ($ENV{DEBUG}) {
    diag "ASCII art string:\n" . $ascii_art_string;
}
# test that we get something back with a length
ok(length($ascii_art_string), 'ASCII art string has non-zero length');

my @ascii_art = $sfss->encode({
    PACKET => $test_packet,
    TYPE   => 'ASCII art',
});
if ($ENV{DEBUG}) {
    diag "ASCII art array:\n" . Dumper \@ascii_art;
}
# test that the number of characters in the ASCII string is the same as
# the number of ASCII art entries
is(scalar @ascii_art, length($ascii), 'ASCII art array has same number of elements as the string is long');

# test that the last entry is the representation of 'R' (FEN)
is($sfss->ascii2art_map()->{'R'}, $ascii_art[scalar @ascii_art - 1], 'Last symbol is R (FEN)');

# test packet from RFC 4824 authors
my $test_packet2 = pack('H*', '1e1f202122232425262728292a2b2c2d2e2f3031323334353637');
my $ascii2 = 'QABAABOBPCACBCCCDCECFCGCHCICJCKCLCMCNCOCPDADBDCDDDEDFDGDHLPOMR';
my $test = $sfss->decode({
    FRAME => $ascii2,
});
ok($test_packet2 eq $test, 'Test packet from RFC4824 authors decoding');

my $packet = $sfss->decode({
    FRAME => $ascii,
});
if ($ENV{DEBUG}) {
    diag "Decoded packet (in hex): " . unpack('H*', $packet);
}
# test that decoding the ASCII representation yields the original packet
ok($packet eq $test_packet, 'Re-encoding yields original representation');

# test that adding errors that are cancelled using SUN (signal undo)
# does not change the resulting packet
my $frame_cancelled_errors = 'AAASSS' . $ascii;
$packet = $sfss->decode({
    FRAME => $frame_cancelled_errors,
});
if ($ENV{DEBUG}) {
    diag "Decoded packet (in hex): " . unpack('H*', $packet);
}
is(unpack('H*', $packet), unpack('H*', $test_packet), 'Signal Undo cancelling works');

$frame_cancelled_errors = 'ABCDEFGHAAAT' . $ascii;
$packet = $sfss->decode({
    FRAME => $frame_cancelled_errors,
});
if ($ENV{DEBUG}) {
    diag "Decoded packet (in hex): " . unpack('H*', $packet);
}
# test that adding errors that are cancelled using FUN (frame undo)
# does not change the resulting packet
ok($packet eq $test_packet, 'Frame Undo cancelling works');
