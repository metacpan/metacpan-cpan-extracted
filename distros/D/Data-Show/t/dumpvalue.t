use 5.010;
use Test::More eval{require Dumpvalue} ? 'no_plan' : (skip_all => 'This test requires Dumpvalue');
use Data::Show with => 'Dumpvalue';
my $STDERR;
close STDERR;
open *STDERR, '>', \$STDERR or die $!;

my %foo = (foo => 1, food => 2, fool => 3, foop => 4);
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
t/dumpvalue.t
14   show(%foo);
'foo' => 1
'food' => 2
'fool' => 3
'foop' => 4

15   show $/;
'
'

16   show @bar;
0  'b'
1  'a'
2  'r'

17   show (
18       @bar,
19       $baz,
20   );
0  'b'
1  'a'
2  'r'
3  'baz'

21   show $baz;
'baz'

22   show $ref;
0  'b'
1  'a'
2  'r'

23   show @bar[do{1..2;}];
0  'a'
1  'r'

24   show 2*3;
6

25   show 'a+b';
'a+b'

26   show 100 * sq length $baz;
900

27   show $foo{q[;{{{]};
undef

29   show 'foo' =~ m/;\{\/\{/
  empty array

31   show $/{Answer};
undef

35   show $+{bar};
'foo'
