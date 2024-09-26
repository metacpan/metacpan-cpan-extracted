use 5.010;
use Data::Show with => 'Legacy';
use Test::More eval{require Data::Dump} ? 'no_plan' : (skip_all => 'This test requires Data::Dump');
my $STDERR;
close STDERR;
open *STDERR, '>', \$STDERR or die $!;

my %foo = (foo => 1, food => 2, fool => 3, foop => 4, foon => [5..10]);
my @bar = qw<b a r>;
my $baz = 'baz';
my $ref = \@bar;
sub sq;

show(%foo);
show $/;
show @bar;
show (
    @bar,
    $baz,
);
show $baz;
show $ref;
show @bar[do{1..2;}];
show 2*3;
show 'a+b';
show 100 * sq length $baz;
show $foo{q[;{{{]};
do {
    show 'foo' =~ m/;\{\/\{/
};
show $/{Answer};

my $str = 'foo';
$str =~ m/(?<bar>\w+)/;
show $+{bar};

my @expected = <DATA>;
my @got      = split "(?<=\n)", $STDERR;

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

__DATA__
===(  %foo  )==================================[ 'show_legacy.t', line 14 ]===

    ( foo => 1, food => 2, fool => 3, foon => [5 .. 10], foop => 4 )

===(  $/  )====================================[ 'show_legacy.t', line 15 ]===

    "\n"

===(  @bar  )==================================[ 'show_legacy.t', line 16 ]===

    ("b", "a", "r")

===(   @bar, $baz,   )=========================[ 'show_legacy.t', line 17 ]===

    ("b", "a", "r", "baz")

===(  $baz  )==================================[ 'show_legacy.t', line 21 ]===

    "baz"

===(  $ref  )==================================[ 'show_legacy.t', line 22 ]===

    ["b", "a", "r"]

===(  @bar[do{1..2;}]  )=======================[ 'show_legacy.t', line 23 ]===

    ("a", "r")

===(  2*3  )===================================[ 'show_legacy.t', line 24 ]===

    6

===(  'a+b'  )=================================[ 'show_legacy.t', line 25 ]===

    "a+b"

===(  100 * sq length $baz  )==================[ 'show_legacy.t', line 26 ]===

    900

===(  $foo{q[;{{{]}  )=========================[ 'show_legacy.t', line 27 ]===

    undef

===(  'foo' =~ m/;\{\/\{/   )==================[ 'show_legacy.t', line 29 ]===

    ()

===(  $/{Answer}  )============================[ 'show_legacy.t', line 31 ]===

    undef

===(  $+{bar}  )===============================[ 'show_legacy.t', line 35 ]===

    "foo"

