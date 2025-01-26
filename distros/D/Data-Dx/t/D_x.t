my ($fh, $STDERR);
BEGIN {
    open $fh, '>', \$STDERR or die $!;
}

use Data::Dx {colour=>0, to=>$fh};
use Test::More;

plan tests => 41;


my %foo = (foo => 1, food => 2, fool => 3, foop => 4, foon => [5..10]);
my @bar = qw<b a r>;
my $baz = 'baz';
my $ref = \@bar;
sub sq;

Dₓ %foo;
Dₓ $/;
Dₓ @bar;
Dₓ (
    @bar,
    $baz,
);
Dₓ $baz;
Dₓ $ref;
Dₓ @bar[do{1..2;}];
Dₓ 2*3;
Dₓ 'a+b';
Dₓ 100 * sq length $baz;
Dₓ $foo{q[;{{{]};
do {
    Dₓ 'foo' =~ m/;\{\/\{/
};
Dₓ $/{Answer};

my $str = 'foo';
$str =~ m/(?<bar>\w+)/;
Dₓ $+{bar};

my @expected;
my @got      = split /\n/, $STDERR;

for my $n (0..$#expected) {
    if ($expected[$n] =~ m{\A \s* \{ }xms) {
        is_deeply(eval($got[$n]), eval($expected[$n]) => ": $expected[$n]");
    }
    else {
        is $got[$n], $expected[$n] => ": $expected[$n]";
    }
}

sub sq {
    my ($n) = @_;
    return $n * $n;
}

BEGIN {
    @expected = split /\n/, <<'END_EXPECTED';
#line 18  t/D_x.t
%foo = { foo => 1, food => 2, fool => 3, foon => [5 .. 10], foop => 4 }

#line 19  t/D_x.t
$/ = "\n"

#line 20  t/D_x.t
@bar = ["b", "a", "r"]

#line 21  t/D_x.t
( @bar, $baz, ) = ["b", "a", "r", "baz"]

#line 25  t/D_x.t
$baz = "baz"

#line 26  t/D_x.t
$ref = ["b", "a", "r"]

#line 27  t/D_x.t
@bar[do{1..2;}] = ["a", "r"]

#line 28  t/D_x.t
2*3 = 6

#line 29  t/D_x.t
'a+b' = "a+b"

#line 30  t/D_x.t
100 * sq length $baz = 900

#line 31  t/D_x.t
$foo{q[;{{{]} = undef

#line 33  t/D_x.t
'foo' =~ m/;\{\/\{/ = undef

#line 35  t/D_x.t
$/{Answer} = undef

#line 39  t/D_x.t
$+{bar} = "foo"
END_EXPECTED
}
