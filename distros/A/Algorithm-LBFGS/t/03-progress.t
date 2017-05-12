use strict;
use warnings;

use Test::More tests => 5;
use Test::Number::Delta within => 1e-5;

my $__;
sub NAME { $__ = shift };

sub norm2(@) {
    my $x = shift;
    my $r = 0;
    for (@$x) { $r += $_ ** 2 }
    return sqrt($r);
}

###
NAME 'Preparation of the following tests';
use Algorithm::LBFGS;
my $o = Algorithm::LBFGS->new;
my $lbfgs_eval = sub {
    my $x = shift;
    my $f = $x->[0] ** 2 / 2 + $x->[1] ** 2 / 3;
    my $g = [$x->[0], 2 * $x->[1] / 3];
    return ($f, $g);
};
my $log = [];
my $x = $o->fmin($lbfgs_eval, [5, 5], 'logging', $log);
ok 1,
$__;

###
NAME 'Iteration number k should be growing natural numbers';
{
    my @k = map { $_->{k} } @$log;
    is_deeply \@k, [1..scalar(@$log)],
    $__;
}

###
NAME 'Check the consistency of x and xnorm';
{
    my @xnorm = map { norm2($_->{x}) } @$log;
    my @expected_xnorm = map { $_->{xnorm} } @$log;
    is_deeply \@xnorm, \@expected_xnorm,
    $__;
}

###
NAME 'Check the consistency of g (grad f(x)) and gnorm';
{
    my @gnorm = map { norm2($_->{g}) } @$log;
    my @expected_gnorm = map { $_->{gnorm} } @$log;
    is_deeply \@gnorm, \@expected_gnorm,
    $__;
}

###
NAME 'f(x) should be decreasing';
{
    my $d = [];
    if (scalar(@$log) > 1) {
        for (my $i = 1; $i < scalar(@$log); $i++) {
            $d->[$i - 1] = $log->[$i]->{fx} < $log->[$i - 1] ? 1 : 0;
        }
    }
    my $d_expected = [];
    if (scalar(@$log) > 1) {
        push @$d_expected, 1 for (1..scalar(@$log)-1);
    }
    is_deeply $d, $d_expected,
    $__;
}

