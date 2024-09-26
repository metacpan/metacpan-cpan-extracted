use 5.010;
no Data::Show warnings => 'on', style => 'off';
use Test::More tests => 1;
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

pass 'Should be no output';

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
