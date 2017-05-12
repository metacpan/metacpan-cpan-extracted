#!perl -T

use Algorithm::NeedlemanWunsch;
use Test::More tests => 4;

sub kronecker {
    my ($a, $b) = @_;

    return ($a eq $b) ? 1 : 0;
}

my $lcs = Algorithm::NeedlemanWunsch->new(\&kronecker, 0);

my @same_a = qw(a b c);
my @same_b = qw(a b c);

my $score = $lcs->align(\@same_a, \@same_b);
is($score, 3);

$score = $lcs->align(\@same_a, \@same_a);
is($score, 3);

my @alignment;

sub check_align {
    my ($i, $j) = @_;

    unshift @alignment, [$i, $j];
}

sub check_select_align {
    my $arg = shift;

    die "alignment not an option" unless exists($arg->{align});
    unshift @alignment, $arg->{align};
    return 'align';
}

@alignment = ();
$lcs->align(\@same_a, \@same_b, { align => \&check_align });
is_deeply(\@alignment, [ [0, 0], [1, 1], [2, 2] ]);

@alignment = ();
$lcs->align(\@same_a, \@same_b, { select_align => \&check_select_align });
is_deeply(\@alignment, [ [0, 0], [1, 1], [2, 2] ]);
