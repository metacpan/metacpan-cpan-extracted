#!perl -T

use Algorithm::NeedlemanWunsch;
use Test::More tests => 17;

sub kronecker {
    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : 0;
}

sub nowarn_kronecker {
    no strict;
    no warnings;

    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : 0;
}

sub simple {
    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : -2;
}

my @a;
my @b;
my $oa;
my $ob;

sub prepend_align {
    my ($i, $j) = @_;

    $oa = $a[$i] . $oa;
    $ob = $b[$j] . $ob;
}

sub prepend_first_only {
    my $i = shift;

    $oa = $a[$i] . $oa;
    $ob = "-$ob";
}

sub prepend_second_only {
    my $j = shift;

    $oa = "-$oa";
    $ob = $b[$j] . $ob;
}

my $matcher = Algorithm::NeedlemanWunsch->new(\&kronecker, 0);

my $score = $matcher->align([ ], [ ]);
is($score, 0);

$score = $matcher->align([ 'a', 'b', 'c' ], [ 'd', 'e' ]);
is($score, 0);

@a = qw(a b c);
@b = qw(d e);
$oa = '';
$ob = '';
$score = $matcher->align(\@a, \@b,
			 {
			  align => \&prepend_align,
			  shift_a => \&prepend_first_only,
			  shift_b => \&prepend_second_only
			 });
is($score, 0);
is($oa, 'abc');
is ($ob, '-de');

my $float_gap = -3.14;
my $eps = 0.0001;
$matcher = Algorithm::NeedlemanWunsch->new(\&kronecker, $float_gap);

$score = $matcher->align([ 1 ], [ ]);
my $delta = abs($score - $float_gap);
ok($delta < $eps);

$score = $matcher->align([ ], [ 2.5 ]);
$delta = abs($score - $float_gap);
ok($delta < $eps);

$matcher = Algorithm::NeedlemanWunsch->new(\&nowarn_kronecker, -1);
$score = $matcher->align([ '', undef, '' ], [ '', '', '', '' ]);
is($score, 2);

$oa = '';
$ob = '';
@a = ( 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1 );
@b = ( 0, 1, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0 );

$matcher = Algorithm::NeedlemanWunsch->new(\&simple);
$matcher->gap_open_penalty(-1);
$matcher->gap_extend_penalty(0);
$score = $matcher->align(\@a, \@b,
			 {
			  align => \&prepend_align,
			  shift_a => \&prepend_first_only,
			  shift_b => \&prepend_second_only
			 });
is($score, 3);
is($oa, '-10--11--00011111');
is($ob, '010011100000-----');

$oa = '';
$ob = '';
my @t = @a; @a = @b; @b = @t;
$score = $matcher->align(\@a, \@b,
			 {
			  align => \&prepend_align,
			  shift_a => \&prepend_first_only,
			  shift_b => \&prepend_second_only
			 });
is($score, 3);
is($oa, '-01--00--11100000');
is($ob, '101100011111-----');

$oa = '';
$ob = '';
$matcher->local(1);
$score = $matcher->align(\@a, \@b,
			 {
			  align => \&prepend_align,
			  shift_a => \&prepend_first_only,
			  shift_b => \&prepend_second_only
			 });
is($score, 5);
is($oa, '0---100---11100000');
is($ob, '-101100011111-----');
