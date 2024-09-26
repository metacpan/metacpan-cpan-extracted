use 5.010;
use Data::Show; use Data::Show as => 'explicate';
use Test::More eval{require Data::Pretty} ? 'no_plan' : (skip_all => 'This test requires Data::Pretty');
my $STDERR;
close STDERR;
open *STDERR, '>', \$STDERR or die $!;

my %foo = (foo => 1, food => 2, fool => 3, foop => 4, foon => [5..10]);
my @bar = qw<b a r>;
my $baz = 'baz';
my $ref = \@bar;
sub sq;

explicate(%foo);
explicate $/;
show @bar;
explicate (
    @bar,
    $baz,
);
explicate $baz;
explicate $ref;
explicate @bar[do{1..2;}];
explicate 2*3;
show 'a+b';
explicate 100 * sq length $baz;
explicate $foo{q[;{{{]};
do {
    explicate 'foo' =~ m/;\{\/\{/
};
explicate $/{Answer};

my $str = 'foo';
$str =~ m/(?<bar>\w+)/;
explicate $+{bar};

my @expected = <DATA>;                    chomp @expected;
my @got      = split "[ \t]*\n", $STDERR;    chomp @got;

for my $n (0..$#expected) {
    is $got[$n], $expected[$n] => ": $expected[$n]";
}

sub sq {
    my ($n) = @_;
    return $n * $n;
}

__DATA__
t/as.t
14   explicate(%foo);
( foo => 1, food => 2, fool => 3, foon => [5 .. 10], foop => 4 )

15   explicate $/;
"\n"

16   show @bar;
(qw( b a r ))

17   explicate (
18       @bar,
19       $baz,
20   );
(qw( b a r baz ))

21   explicate $baz;
"baz"

22   explicate $ref;
[qw( b a r )]

23   explicate @bar[do{1..2;}];
(qw( a r ))

24   explicate 2*3;
6

25   show 'a+b';
"a+b"

26   explicate 100 * sq length $baz;
900

27   explicate $foo{q[;{{{]};
undef

29   explicate 'foo' =~ m/;\{\/\{/
()

31   explicate $/{Answer};
undef

35   explicate $+{bar};
"foo"
