my ($fh, $STDERR);
BEGIN {
    open $fh, '>', \$STDERR or die $!;
}

use Data::Dx {colour=>0, to=>$fh};
no utf8;

use Test::More;
plan tests => 41;

my %foo = (foo => 1, food => 2, fool => 3, foop => 4, foon => [5..10]);
my @bar = qw<b a r>;
my $baz = 'baz';
my $ref = \@bar;
sub sq;

Dx %foo;
Dx $/;
Dx @bar;
Dx (
    @bar,
    $baz,
);
Dx $baz;
Dx $ref;
Dx @bar[do{1..2;}];
Dx 2*3;
Dx 'a+b';
Dx 100 * sq length $baz;
Dx $foo{q[;{{{]};
do {
    Dx 'foo' =~ m/;\{\/\{/
};
Dx $/{Answer};

my $str = 'foo';
$str =~ m/(?<bar>\w+)/;
Dx $+{bar};

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
#line 18  t/Dx_noUTF8.t
%foo = { foo => 1, food => 2, fool => 3, foon => [5 .. 10], foop => 4 }

#line 19  t/Dx_noUTF8.t
$/ = "\n"

#line 20  t/Dx_noUTF8.t
@bar = ["b", "a", "r"]

#line 21  t/Dx_noUTF8.t
( @bar, $baz, ) = ["b", "a", "r", "baz"]

#line 25  t/Dx_noUTF8.t
$baz = "baz"

#line 26  t/Dx_noUTF8.t
$ref = ["b", "a", "r"]

#line 27  t/Dx_noUTF8.t
@bar[do{1..2;}] = ["a", "r"]

#line 28  t/Dx_noUTF8.t
2*3 = 6

#line 29  t/Dx_noUTF8.t
'a+b' = "a+b"

#line 30  t/Dx_noUTF8.t
100 * sq length $baz = 900

#line 31  t/Dx_noUTF8.t
$foo{q[;{{{]} = undef

#line 33  t/Dx_noUTF8.t
'foo' =~ m/;\{\/\{/ = undef

#line 35  t/Dx_noUTF8.t
$/{Answer} = undef

#line 39  t/Dx_noUTF8.t
$+{bar} = "foo"
END_EXPECTED
}

