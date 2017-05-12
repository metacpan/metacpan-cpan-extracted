#!perl -T

use Test::More tests => 21;
use Data::Dumper;

BEGIN {
	use_ok( 'Acme::AlgebraicToRPN' );
}

diag( "Testing Acme::AlgebraicToRPN $Acme::AlgebraicToRPN::VERSION, Perl $], $^X" );

my $rpn = Acme::AlgebraicToRPN->new(userFunc => [qw(box news foo)]);

my $expr = '4+3';
test($expr, qw(4 3 add));
$expr = '-4+3';
test($expr, qw(4 negate 3 add));
test('sin(3)', qw(3 sin));
test('sin(pi/2)', qw(pi 2 divide sin));
test('-sin(pi/2)', qw(pi 2 divide sin negate));
test('-sin(pi+3/2)', qw(pi 3 2 divide add sin negate));
test('news(hammer)', qw(hammer 1 news));
test('1+3^x', qw(1 3 x exponentiate add));
test('-3-3*x', qw(3 negate 3 x multiply subtract));
test('sqrt(4)', qw(4 0.5 exponentiate));
$expr = '2*news(a)/2+pi';
test('-sin(box(a,20))', qw(a 20 2 box sin negate));
test('log(a)', qw(a log));
test('atan2(a,b)', qw(a b atan2));
test('a^b', qw(a b exponentiate));
test('a^b3', qw(a b3 exponentiate));
test('a^-1', qw(a 1 negate exponentiate));
test('sin(pi/3)*2/log(2,1.3)', qw(pi 3 divide sin 2 multiply 2 1.3 log divide));
test('4*foo(a,3)', qw(4 a 3 2 foo multiply));
test('4*foo(a,3,55)', qw(4 a 3 55 3 foo multiply));
print STDERR "Shouldn't parse due to 'boo' function, which we don't know\n";
ok(!defined($rpn->rpn('4*boo(a,3,55)')));
#print $rpn->rpn_as_string($expr), "\n";

sub test {
    my ($expr, @desired) = @_;
    print STDERR "rpn = $expr... ";
    my @r = $rpn->rpn($expr);
    #print Dumper(\@r);
    my $same = $rpn->check(\@desired, @r);
    print STDERR "Different lengths\n" unless @r == @desired;
    print STDERR $same ? "Ok!\n" : "NOT Ok!\n";
    print STDERR "Got: ", Dumper(\@r) unless $same;
    print STDERR "Expected: ", Dumper(\@desired) unless $same;
    ok($same);
}
