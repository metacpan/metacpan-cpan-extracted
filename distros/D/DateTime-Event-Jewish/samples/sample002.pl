#!perl 

=head1 NAME

sample001.pl	- How to use this module

=head1 DESCRIPTION

This is a sample program that prints the parsha name for this
week.

=cut

use strict;
use warnings;

use lib qw(../lib);

use DateTime;
use DateTime::Event::Jewish::Parshah qw(parshah);

my $today	= DateTime->today();
my $parshah	= parshah($today);

print $today->ymd, "\t$parshah\n";
exit 0;
