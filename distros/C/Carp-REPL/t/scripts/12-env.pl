#!perl
use strict;
use warnings;

sub zero
{
    one('I');
}

sub one
{
    my $num = shift;
    two(($num) x 2);
}

sub two
{
    my ($a, $b) = @_;
    three($a => is => $b);
}

sub three
{
    my $uno = shift;
    my $dos = shift;
    my $tres = shift;

    four(
        H  => 1,
        He => 2,
        Li => 3,
        Be => 4,
    );
}

sub four
{
    my %args = @_;

    my $closure = sub {
        my ($alpha, $beta, $gamma, $delta) = @_;
        five($alpha + $beta + $gamma + $delta);
    };
    $closure->(sort values %args);
}

sub five
{
    die @_;
}

zero();

