package Acme::Prereq::F;

use 5.006;
use strict;
use warnings;

=head1 NAME

Acme::Prereq::F - Module for testing CPAN module prerequisites

=head1 VERSION

Version 2.0.0

=cut

our $VERSION = '2.0.0';

sub one() {
	print "One !\n";
}

sub two() {
	print "Two !\n";
}

1; # End of Acme::Prereq::F
