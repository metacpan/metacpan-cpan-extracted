#!perl -T

use Algorithm::NeedlemanWunsch;
use Test::More tests => 4;

sub simple {
    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : -2;
}

my $matcher = Algorithm::NeedlemanWunsch->new(\&simple);
$matcher->gap_open_penalty(-5);
$matcher->gap_extend_penalty(-1);

my @a = qw(A T G T A G T G T A T A G T A C A T G C A);
my @b = qw(A T G T A G T A C A T G C A);

my $oa = '';
my $ob = '';

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

$matcher->align(\@a, \@b,
		{
		 align => \&prepend_align,
		 shift_a => \&prepend_first_only,
		 shift_b => \&prepend_second_only,
		});
is($oa, 'ATGTAGTGTATAGTACATGCA');
is($ob, 'ATG-------TAGTACATGCA');

my @t = @a; @a = @b; @b = @t;
$oa = '';
$ob = '';
$matcher->align(\@a, \@b,
		{
		 align => \&prepend_align,
		 shift_a => \&prepend_first_only,
		 shift_b => \&prepend_second_only,
		});
is($oa, 'ATG-------TAGTACATGCA');
is($ob, 'ATGTAGTGTATAGTACATGCA');
