use Test2::V0;
use Atomic::Pipe;
use Time::HiRes qw/sleep/;
BEGIN { *PIPE_BUF = Atomic::Pipe->can('PIPE_BUF') }

subtest peek_line => sub {
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    my $wh = $w->wh;
#    $w->wh->autoflush(1);

    my $size = syswrite($wh, "A Line with no newline");
    warn "Write error (Wrote " . ($size // 0) . " bytes): $!" unless $size;
#    print $wh "A Line with no newline";
#    $wh->flush();

    my ($type, $text) = $r->get_line_burst_or_data();
    ok(!$type, "Did not get a type");
    ok(!$text, "Did not get text");

    ok(!$r->eof, "Not EOF");

    ($type, $text) = $r->get_line_burst_or_data(peek_line => 1);
    is($type, 'peek', "peek type");
    is($text, "A Line with no newline", "peeked at line");

    ($type, $text) = $r->get_line_burst_or_data(peek_line => 1);
    is($type, 'peek', "peek type");
    is($text, "A Line with no newline", "peeked at line again");

    # Get to EOF
    $w->close;

    ($type, $text) = $r->get_line_burst_or_data(peek_line => 1);
    is($type, 'line', "line type");
    is($text, "A Line with no newline", "got line");

    ok($r->eof, "EOF");
};

done_testing;
