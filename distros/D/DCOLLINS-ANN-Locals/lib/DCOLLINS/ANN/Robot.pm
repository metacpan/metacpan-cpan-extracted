#!/usr/bin/perl
package DCOLLINS::ANN::Robot;
BEGIN {
  $DCOLLINS::ANN::Robot::VERSION = '0.004';
}
use strict;
use warnings;
# ABSTRACT: a wrapper for AI::ANN

use Moose;
extends 'AI::ANN';

use Storable qw(dclone);
use Math::Libm qw(erf M_PI tan);
#use Memoize;
#memoize('_afunc_default');
#memoize('_dafunc_default');


around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;
    if (defined $_[0] && ref $_[0] eq 'HASH') {
    	return $class->$orig(%{$_[0]});
    } elsif (@_ > 0) {
        my %data = @_;
        if (exists $data{'data'}) {
            return $class->$orig(@_);
        }
    }
    my %data = @_;
    $data{'inputs'} ||= 15;
    $data{'minvalue'} ||= -2;
    $data{'maxvalue'} ||= 2;
    $data{'backprop_eta'} ||= 0.01;
## Pull to center, 0
#    $data{'afunc'} ||= sub { tan( 2 * (shift)  / 3 ) / 2.1 };
#    $data{'dafunc'} ||= sub { 20/63 / cos( 2 * (shift) / 3 ) ** 2 };
## Pull away from center, 0
#    $data{'afunc'} ||= \&_afunc_default();
#    $data{'dafunc'} ||= \&_dafunc_default();
    $data{'afunc'} ||= sub{_afunc_c(shift)};
    $data{'dafunc'} ||= sub{_dafunc_c(shift)};

## Pull away from center, 1
#    $data{'afunc'} ||= sub { erf( 2 * ( (shift) - 1 ) ) + 1};
#    $data{'dafunc'} ||= sub { 4 / sqrt(M_PI) * exp( -4 * ( (shift) - 1 ) ** 2 ) };
    my @arg2 = ();
    for (my $i = 0; $i < 15; $i++) {
        push @arg2, { 'iamanoutput' => 0,
                      'inputs' => { $i => rand() },
                      'neurons' => [ ],
                      'eta_inputs' => { $i => rand() },
                      'eta_neurons' => [ ] };
        push @arg2, { 'iamanoutput' => 0,
                      'inputs' => { $i => 3 * rand() - 2 },
                      'neurons' => [ ],
                      'eta_inputs' => { $i => 3 * rand() - 2 },
                      'eta_neurons' => [ ] };
    } # Made neurons 0-29
    for (my $i = 0; $i < 15; $i++) {
        my @working = ();
        my @eta_working = ();
        for (my $j = 0; $j < 30; $j ++) {
            $working[$j] = rand() / 10 - 0.05;
            $eta_working[$j] = rand() / 10 - 0.05;
        }
        push @arg2, { 'iamanoutput' => 0,
                       'inputs' => [],
                       'neurons' => \@working,
                       'eta_inputs' => [],
                       'eta_neurons' => \@eta_working };
    } # Made neurons 30-44
    for (my $i = 0; $i < 15; $i++) {
        my @working = ();
        my @eta_working = ();
        for (my $j = 0; $j < 45; $j ++) {
            $working[$j] = rand() / 10 - 0.05;
            $eta_working[$j] = rand() / 10 - 0.05;
        }
        push @arg2, { 'iamanoutput' => 0,
                       'inputs' => [],
                       'neurons' => \@working,
                       'eta_inputs' => [],
                       'eta_neurons' => \@eta_working };
    } # Made neurons 45-59
    for (my $i = 0; $i < 5; $i++) {
        my @working = ();
        my @eta_working = ();
        for (my $j = 30; $j < 60; $j ++) {
            $working[$j] = rand() / 2 - 0.25;
            $eta_working[$j] = rand() / 2 - 0.25;
        }
        push @arg2, { 'iamanoutput' => 1,
                       'inputs' => [],
                       'neurons' => \@working,
                       'eta_inputs' => [],
                       'eta_neurons' => \@eta_working };
    } # Made neurons 60-64
    $data{'data'} = \@arg2;
    return $class->$orig(%data);
};

sub _afunc_default {
	return 2 * erf(shift);
}
sub _dafunc_default {
	return 4 / sqrt(M_PI) * exp( -1 * ((shift) ** 2) );
}

use Inline C => <<'END_C';
#include <math.h>
double afunc[4001];
double dafunc[4001];
void generate_globals() {
        int i;
        for (i=0;i<=4000;i++) {
                afunc[i] = 2 * (erf(i/1000.0-2));
                dafunc[i] = 4 / sqrt(M_PI) * pow(exp(-1 * ((i/1000.0-2))), 2);
        }
}
double _afunc_c (float input) {
        return afunc[(int) floor((input)*1000)+2000];
}
double _dafunc_c (float input) {
        return dafunc[(int) floor((input)*1000)+2000];
}
END_C

generate_globals();

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

DCOLLINS::ANN::Robot - a wrapper for AI::ANN

=head1 VERSION

version 0.004

=head1 SYNOPSIS

use DCOLLINS::ANN::Robot;
my $robot = new DCOLLINS::ANN::Robot ( );

=head1 METHODS

=head2 new

DCOLLINS::ANN::ROBOT::new( )

Creates a DCOLLINS::ANN::Robot object and a neural net to go with it.

This object has methods of its own, as well as the methods available in AI::ANN. We do, however, override the execute method.

For standardization, these are the parameters that SimWorld will pass to the 
	network:
Current battery power (0-1)
Current pain value (0-1)
Differential battery power ((-1)-1)
Differential pain value ((-1)-1)
Proximity readings, -90, -45, 0, 45, 90 degrees (0-1)
Current X location (0-1)
Current Y location (0-1)
Currently facing: N, S, E, W (0-1)

These are the parameters that SimWorld will expect as outputs from the network: 
Rotate L
Rotate R
Forwards
Reverse
Stop
The largest value will be accepted. If no output is greater than 1, SimWorld 
	will interpret as a stop.

=head1 AUTHOR

Dan Collins <dcollin1@stevens.edu>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dan Collins.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

