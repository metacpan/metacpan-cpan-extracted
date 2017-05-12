#!/usr/bin/env perl

use strict;
use warnings;

# write a package that keeps track of the number of splices
# we do just to be on the safe side
package SpliceCounter;
use Tie::Array;
use base qw(Tie::StdArray);

our $splice_counter;

sub SPLICE {
	$splice_counter++;
	my $self = shift;
	return $self->SUPER::SPLICE(@_);
}

package main;

use Test::More tests => 3;

use Array::Extract qw(extract);

my @array;
tie @array, "SpliceCounter";
push @array, qw(MufasaLion SimbaLion Timone NarlaLion Pumba ScarLion);

my @preditors = extract { /Lion/ } @array;

is_deeply \@preditors, [qw( MufasaLion SimbaLion NarlaLion ScarLion )], "It's the circle!";
is_deeply \@array,     [qw( Timone Pumba )], "circle of life!";

is($SpliceCounter::splice_counter, 3, "And it took just three splices");

