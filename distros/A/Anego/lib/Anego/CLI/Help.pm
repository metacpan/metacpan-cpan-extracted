package Anego::CLI::Help;
use strict;
use warnings;
use utf8;

sub run {
    my ($class, @args) = @_;

    my $module = 'Anego';
    system 'perldoc', $module;
}

1;
