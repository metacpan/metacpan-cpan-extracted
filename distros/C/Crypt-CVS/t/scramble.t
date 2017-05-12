use strict;
use warnings;
use Test::More tests => 2 + 1 + (1_000 * 3) + (26 * 2 + 10);
use Crypt::CVS qw(:all);

my %sanity = (
    'anonymous'  => q[Ay=0=a%0bZ],
    'fo shizzle' => q[AE0rZc?>>'d],
);

while (my ($k, $v) = each %sanity) {
    is scramble($k), $v, "sanity: scramble('$k') = '$v'";
}

{
    my @same;
    for (1 .. 255) {
        my $chr = chr $_;
        my $to = scramble($chr);
        my ($x) = $to =~ m/^.(.*)$/;
        push @same => $_ if $x eq $chr;
    }

    is_deeply(\@same, [ 1 .. 9, 11 .. 31, 113, 192 ], "some characters substitute to themselves");
}

for my $str (map { random_string() } 1 .. 1_000) {
    my $scrambled = scramble($str);
    my $descrambled = descramble($scrambled);

    my ($x, $y) = $scrambled =~ m/^(.)(.*)$/;
    is $x, 'A', "scramble('$str') = '$scrambled' begins with A";
    if ($str =~ /^q+$/) {
        is $y, $str, "scramble('$str') != '$y'";
    } else {
        isnt $y, $str, "scramble('$str') != '$y'";
    }
    is $descrambled, $str, "descramble(scramble('$str') = '$str'";
}

# Invalid password formats
for my $chr ("A" .. "Z", "a" .. "z", 0 .. 9) {
    local $@;
    eval { descramble("${chr}foobar") };
    if ($chr eq 'A') {
        is $@, '', "A is a valid password format";
    } else {
        like $@, qr/invalid password format `$chr'/, "$chr isn't a valid password format";
    }
}

sub random_string
{
    my $from   = 32;
    my $to     = 32 + int rand 128;
    my $length = 1 + int rand 20;

    my @chr = map { chr } $from .. $to;
    my @str = map { $chr[rand @chr] } 1 .. $length;
    my $str = join '', @str;

    return $str;
}
