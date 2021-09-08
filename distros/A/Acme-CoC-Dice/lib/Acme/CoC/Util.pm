package Acme::CoC::Util;
use strict;
use utf8;
use warnings;

use parent qw/Exporter/;
use Smart::Args;
use Moose;

our @EXPORT = qw/
    eq_any
    is_ccb
    get_target
    is_extream
    is_hard
    is_failed
/;

sub eq_any {
    my ($target, $array) = @_;
    for my $item (@{ $array }) {
        return 1 if $target eq $item;
    }
}

sub is_ccb {
    my ($command) = @_;
    return $command =~ /skill|ccb|cc/;
}

sub get_target {
    my ($command) = @_;
    $command =~ /(cc|ccb) ([1-9][0-9]*)/;
    return $2;
}

sub is_extream {
    my ($dice, $target) = @_;
    my $rate = sprintf("%.5g", ($dice / $target));
    return $rate <= 0.20000;
}

sub is_hard {
    my ($dice, $target) = @_;
    my $rate = sprintf("%.5g", ($dice / $target));
    return $rate <= 0.50000;
}

sub is_failed {
    my ($dice, $target) = @_;
    return $dice > $target;
}

1;
