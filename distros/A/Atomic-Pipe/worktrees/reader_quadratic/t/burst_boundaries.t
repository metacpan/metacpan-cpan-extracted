use Test2::V0;
use Test2::Util qw/CAN_REALLY_FORK/;
use Atomic::Pipe;

# The writer runs in a forked child. Where fork is emulated with threads
# (MSWin32) Test2 refuses it; the thread-based tests cover the reader there.
skip_all "This test needs a real fork()" unless CAN_REALLY_FORK;
use Time::HiRes qw/time/;

# Bursts, messages and lines must come out intact no matter where read
# boundaries fall: inside a burst, inside a multi-byte prefix or postfix, or
# right before a burst byte that happens to equal the message key.

# A burst must fit in one atomic write (write_burst refuses bigger ones), and
# PIPE_BUF is only 512 on some platforms. Leave room for 3-byte delimiters.
my $MAX_BURST = Atomic::Pipe::PIPE_BUF() - 6;

my @ITEMS;
for my $i (1 .. 60) {
    # Burst data includes the message key byte (\x10) at varied offsets.
    my $len = 50 + ($i * 131) % ($MAX_BURST - 50);
    push @ITEMS => [burst => join '' => map { $_ % 37 ? chr(65 + $_ % 26) : "\x10" } 1 .. $len];
    push @ITEMS => [line  => "line $i\n"];
    push @ITEMS => [message => "message $i " x (1 + ($i * 71) % 700)] unless $i % 5;
}

sub write_items {
    my ($w) = @_;
    for my $item (@ITEMS) {
        my ($type, $data) = @$item;
        if    ($type eq 'burst')   { $w->write_burst($data) // die "burst of " . length($data) . " bytes did not fit\n" }
        elsif ($type eq 'message') { $w->write_message($data) }
        else                       { syswrite($w->wh, $data) }
    }
}

sub run_case {
    my ($name, $read_size, %params) = @_;
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1, %params);
    $r->read_size($read_size);

    my $pid = fork // die "fork: $!";
    unless ($pid) {
        $r->close;
        write_items($w);
        $w->close;
        exit 0;
    }
    $w->close;

    my @got;
    while (1) {
        my %m = $r->get_line_burst_or_data;
        last if !%m && $r->eof;
        next unless %m;
        my ($k) = keys %m;
        push @got => [$k => $m{$k}];
    }
    waitpid($pid, 0);

    is(\@got, \@ITEMS, "$name, read_size $read_size");
}

for my $rs (1, 2, 3, 7, 64, 1000, 4096, 65536) {
    run_case('default delimiters', $rs);
    run_case('3-byte delimiters', $rs, burst_prefix => '<<<', burst_postfix => '>>>');
}

subtest no_spin_on_partial_burst => sub {
    skip_all "non-blocking pipes behave differently on $^O" if $^O eq 'MSWin32';

    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1);
    syswrite($w->wh, "\x0Eabc");

    my $start   = time;
    my %m       = $r->get_line_burst_or_data;
    my $elapsed = time - $start;
    is(\%m, {}, 'returns empty while the burst is incomplete');
    ok($elapsed < 1, 'returned promptly instead of spinning');

    syswrite($w->wh, "def\x0F");
    %m = $r->get_line_burst_or_data;
    is(\%m, {burst => 'abcdef'}, 'burst completes once the rest arrives');
};

subtest multibyte_prefix_does_not_hold_lines => sub {
    skip_all "non-blocking pipes behave differently on $^O" if $^O eq 'MSWin32';

    # With the writer still open, a complete line must come out right away;
    # only bytes that could start the prefix may be held back.
    my ($r, $w) = Atomic::Pipe->pair(mixed_data_mode => 1, burst_prefix => '<<<', burst_postfix => '>>>');
    syswrite($w->wh, "hello\n");
    is({$r->get_line_burst_or_data}, {line => "hello\n"}, 'line returned while writer is open');

    syswrite($w->wh, "partial<<");
    is({$r->get_line_burst_or_data(peek_line => 1)}, {peek => 'partial'}, 'possible prefix start held, rest peeked');

    syswrite($w->wh, "<burst>>>after\n");
    # Unterminated line text stays buffered across a burst and joins the text
    # after it, as with single-byte delimiters.
    is({$r->get_line_burst_or_data}, {burst => 'burst'}, 'burst found across the split prefix');
    is({$r->get_line_burst_or_data}, {line => "partialafter\n"}, 'line text around the burst');

    syswrite($w->wh, "not a prefix <<x\n");
    is({$r->get_line_burst_or_data}, {line => "not a prefix <<x\n"}, 'partial match that turns out not to be a prefix is line data');
};

done_testing;
