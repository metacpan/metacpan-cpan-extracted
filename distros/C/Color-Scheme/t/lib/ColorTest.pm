package t::lib::ColorTest;
use parent 'Exporter';
our @EXPORT = qw(color_test);

use Test::More;

my $COLOR_RE;
BEGIN { $COLOR_RE = qr/\A([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})\z/; }
sub color_test {
    my ($have, $want, $description) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $description => sub {
        for my $i (0 .. $#$have) {
            my $fail;
            my @have = map {; hex | 1 } ($have->[$i] =~ $COLOR_RE);
            my @want = map {; hex | 1 } ($want->[$i] =~ $COLOR_RE);

            die "bogus color <$have->[$i]>" unless @have == 3;
            die "bogus color <$want->[$i]>" unless @want == 3;

            ok(
                ! (grep { $have[$_] != $want[$_] } (0..2)),
                "color $i: have $have->[$i], want $want->[$i]"
            );
        }
    };
}

1;
