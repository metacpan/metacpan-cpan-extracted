use strict;
use warnings;
use Test::More;
use Data::PubSub::Shared;

# Regression: with the old circular byte arena, a publish's write frontier
# could wrap onto a still-current slot's region without bumping THAT slot's
# sequence, so a lagging subscriber read corrupted bytes the seqlock never
# caught. It bit hardest at small capacity with variable-length messages.
#
# Here we publish self-describing, variable-length messages and, after every
# publish, read back every message still inside the readable window
# (write_pos-capacity .. write_pos-1) and confirm each is byte-for-byte what
# was published there. Each slot now owns a fixed arena region, so this holds.

sub run_config {
    my ($cap, $msg_size) = @_;
    my $ps  = Data::PubSub::Shared::Str->new(undef, $cap, $msg_size);
    my @pub;
    my $bad = 0;

    for my $seq (0 .. 6 * $cap + 8) {
        # variable length in [ len("seq-")+1 .. msg_size ] to exercise wrap waste
        my $min = length("$seq-") + 1;
        my $pad = $min + (($seq * 7) % ($msg_size - $min + 1));
        my $body = substr("$seq-" . ("abcdefgh" x $msg_size), 0, $pad);
        $pub[$seq] = $body;
        die "publish failed (cap=$cap msg=$msg_size seq=$seq)" unless $ps->publish($body);

        my $wp     = $seq + 1;                       # write_pos == count published
        my $oldest = $wp > $cap ? $wp - $cap : 0;
        my $sub    = $ps->subscribe;
        for (my $c = $oldest; $c < $wp; $c++) {
            $sub->cursor($c);
            my $got = $sub->poll;
            $bad++ unless defined($got) && $got eq $pub[$c];
        }
    }
    return $bad;
}

# msg_size not a multiple of 8 (small per-message slack) + tiny capacity is the
# worst case; include a few larger configs for breadth.
for my $cfg ([2, 25], [2, 33], [2, 100], [2, 127], [4, 17], [4, 63], [8, 100]) {
    my ($cap, $msg) = @$cfg;
    is(run_config($cap, $msg), 0,
        "cap=$cap msg_size=$msg: every in-window message reads back intact");
}

done_testing;
