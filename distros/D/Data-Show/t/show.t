use Data::Show;
use Test::More 'no_plan';
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
======(  %foo  )=============================[ 'show.t', line 13 ]======

    { foo => 1, food => 2, fool => 3, foon => [5 .. 10], foop => 4 }


======(  $/  )===============================[ 'show.t', line 14 ]======

    "\n"


======(  @bar  )=============================[ 'show.t', line 15 ]======

    ["b", "a", "r"]


======(  @bar, $baz,  )======================[ 'show.t', line 16 ]======

    ("b", "a", "r", "baz")


======(  $baz  )=============================[ 'show.t', line 20 ]======

    "baz"


======(  $ref  )=============================[ 'show.t', line 21 ]======

    ["b", "a", "r"]


======(  @bar[do{1..2;}]  )==================[ 'show.t', line 22 ]======

    ("a", "r")


======(  2*3  )==============================[ 'show.t', line 23 ]======

    6


======(  'a+b'  )============================[ 'show.t', line 24 ]======

    "a+b"


======(  100 * sq length $baz  )=============[ 'show.t', line 25 ]======

    900


======(  $foo{q[;{{{]}  )====================[ 'show.t', line 26 ]======

    undef


======(  'foo' =~ m/;\{\/\{/  )==============[ 'show.t', line 28 ]======

    ()


======(  $/{Answer}  )=======================[ 'show.t', line 30 ]======

    undef


======(  $+{bar}  )==========================[ 'show.t', line 34 ]======

    "foo"

