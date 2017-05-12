#!/usr/bin/perl
package AI::ANN::Neuron;
BEGIN {
  $AI::ANN::Neuron::VERSION = '0.008';
}
# ABSTRACT: a neuron for an artificial neural network simulator

use strict;
use warnings;

use Moose;
use Inline C => <<'END_C';

double _execute_internals ( AV* inputs, AV* neurons, AV* inputweights, AV* neuronweights ) {
    double output = 0.0;
	int i;
	int v1 = av_len(inputweights);
	int v2 = av_len(inputs);
	if (v2 < v1) {
		v1 = v2;
	}
	if (v1 >= 0) {
		for (i=0; i<=v1; i++) {
			SV** val = av_fetch(inputs, i, 0);
			SV** weight = av_fetch(inputweights, i, 0);
			output += SvNV(*val) * SvNV(*weight);
		}
	}
	v1 = av_len(neuronweights);
	v2 = av_len(neurons);
	if (v2 < v1) {
		v1 = v2;
	}
	if (v1 >= 0) {
		for (i=0; i<=v1; i++) {
			SV** val = av_fetch(neurons, i, 0);
			SV** weight = av_fetch(neuronweights, i, 0);
			output += SvNV(*val) * SvNV(*weight);
		}
	}
	return output;
}

END_C


has 'id' => (is => 'rw', isa => 'Int');
has 'inputs' => (is => 'rw', isa => 'ArrayRef', required => 1);
has 'neurons' => (is => 'rw', isa => 'ArrayRef', required => 1);
has 'eta_inputs' => (is => 'rw', isa => 'ArrayRef');
has 'eta_neurons' => (is => 'rw', isa => 'ArrayRef');
has 'inline_c' => (is => 'ro', isa => 'Int', required => 1, default => 1);

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %data;
	if ( @_ >= 2 && ref $_[0] && ref $_[1]) {
		%data = ('inputs' => $_[0], 'neurons' => $_[1]);
		$data{'eta_inputs'} = $_[2] if defined $_[2];
		$data{'eta_neurons'} = $_[3] if defined $_[3];
	} elsif ( @_ >= 3 && ref $_[1] && ref $_[2]) {
		%data = ('id' => $_[0], 'inputs' => $_[1], 'neurons' => $_[2]);
		$data{'eta_inputs'} = $_[3] if defined $_[3];
		$data{'eta_neurons'} = $_[4] if defined $_[4];
	} elsif ( @_ == 1 && ref $_[0] eq 'HASH' ) {
		%data = %{$_[0]};
	} else {
		%data = @_;
	}
	if (ref $data{'inputs'} eq 'HASH') {
		my @temparray;
		foreach my $i (keys %{$data{'inputs'}}) {
			if (defined $data{'inputs'}->{$i} && $data{'inputs'}->{$i} != 0) {
				$temparray[$i]=$data{'inputs'}->{$i};
			}
		}
		$data{'inputs'}=\@temparray;
	}
	if (ref $data{'neurons'} eq 'HASH') {
		my @temparray;
		foreach my $i (keys %{$data{'neurons'}}) {
			if (defined $data{'neurons'}->{$i} && $data{'neurons'}->{$i} != 0) {
				$temparray[$i]=$data{'neurons'}->{$i};
			}
		}
		$data{'neurons'}=\@temparray;
	}
	if (defined $data{'eta_inputs'} && ref $data{'eta_inputs'} eq 'HASH') {
		my @temparray;
		foreach my $i (keys %{$data{'eta_inputs'}}) {
			if (defined $data{'eta_inputs'}->{$i} && $data{'eta_inputs'}->{$i} != 0) {
				$temparray[$i]=$data{'eta_inputs'}->{$i};
			}
		}
		$data{'eta_inputs'}=\@temparray;
	}
	if (defined $data{'eta_neurons'} && ref $data{'eta_neurons'} eq 'HASH') {
		my @temparray;
		foreach my $i (keys %{$data{'eta_neurons'}}) {
			if (defined $data{'eta_neurons'}->{$i} && $data{'eta_neurons'}->{$i} != 0) {
				$temparray[$i]=$data{'eta_neurons'}->{$i};
			}
		}
		$data{'eta_neurons'}=\@temparray;
	}
	foreach my $i (0..$#{$data{'inputs'}}) {
		$data{'inputs'}->[$i] ||= 0;
	}
	foreach my $i (0..$#{$data{'neurons'}}) {
		$data{'neurons'}->[$i] ||= 0;
	}
	foreach my $i (0..$#{$data{'eta_inputs'}}) {
		$data{'eta_inputs'}->[$i] ||= 0;
	}
	foreach my $i (0..$#{$data{'eta_neurons'}}) {
		$data{'eta_neurons'}->[$i] ||= 0;
	}
	return $class->$orig(%data);
};


sub ready {
	my $self = shift;
	my $inputs = shift;
	my $neurons = shift;
	if (ref $neurons eq 'HASH') {
		my @temparray;
		foreach my $i (keys %$neurons) {
			if (defined $neurons->{$i} && $neurons->{$i} != 0) {
				$temparray[$i]=$neurons->{$i};
			}
		}
		$neurons=\@temparray;
	}
	my @inputs = @$inputs;
	my @neurons = @$neurons;

	foreach my $id (0..$#{$self->{'inputs'}}) {
		unless ((not defined $self->{'inputs'}->[$id]) || 
				$self->{'inputs'}->[$id] == 0 || defined $inputs[$id])
				{return 0}
		# This probably shouldn't ever happen, as it would be weird if our
		# inputs weren't available yet.
	}
	foreach my $id (0..$#{$self->{'neurons'}}) {
		unless ((not defined $self->{'neurons'}->[$id]) || 
				$self->{'neurons'}->[$id] == 0 || defined $neurons[$id])
				{return 0}
	}
	return 1;
}


sub execute {
	my $self = shift;
	my $inputs = shift;
	my $neurons = shift;
	if (ref $neurons eq 'HASH') {
		my @temparray;
		foreach my $i (keys %$neurons) {
			$temparray[$i]=$neurons->{$i} || 0;
		}
		$neurons=\@temparray;
	}
	my @inputs = @$inputs;
	my @neurons = @$neurons;
	my @inputweights = @{$self->{'inputs'}};
	my @neuronweights = @{$self->{'neurons'}};
#	foreach my $i (0..$#inputs) {
#		$inputs[$i] ||= 0;
#	}
#	foreach my $i (0..$#neurons) {
#		$neurons[$i] ||= 0;
#	}
#	if ($#inputs < $#inputweights) {
#		foreach my $i ($#inputs+1..$#inputweights) {
#			$inputs[$i]=0;
#		}
#	}
#	if ($#neurons < $#neuronweights) {
#		foreach my $i ($#neurons+1..$#neuronweights) {
#			$neurons[$i]=0;
#		}
#	}
#print STDERR $self->{'id'}."\n";
#print STDERR join(',', @inputs)."\n";
#print STDERR join(',', @neurons)."\n";
#print STDERR join(',', @inputweights)."\n";
#print STDERR join(',', @neuronweights)."\n";
	my $output = 0;
	if ($self->{'inline_c'}) {
		$output = _execute_internals( \@inputs, \@neurons, \@inputweights, \@neuronweights );
	} else {
		foreach my $id (0..$#inputweights) {
			$output += ($inputweights[$id] || 0 ) * ($inputs[$id] || 0);
		}
		foreach my $id (0..$#neuronweights) {
			$output += ($neuronweights[$id] || 0) * ($neurons[$id] || 0);
		}
	}
	return $output;
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=head1 NAME

AI::ANN::Neuron - a neuron for an artificial neural network simulator

=head1 VERSION

version 0.008

=head1 METHODS

=head2 new

AI::ANN::Neuron->new( $neuronid, {$inputid => $weight, ...}, {$neuronid => $weight} )

Weights may be whatever the user chooses. Note that packages that use this 
one may place their own restructions. Neurons and inputs are assumed to be 
zero-indexed.

eta_inputs and eta_neurons are optional, required only if you wish to use the 
Gaussian mutation in AI::ANN::Evolver.

=head2 ready

$neuron->ready( [$input0, $input1, ...], [$neuronvalue0, ...] )

All inputs must be provided or you're insane.
If a neuron is not yet available, make it undef, not zero.
Returns 1 if ready, 0 otherwise.

=head2 execute

$neuron->execute( [$input0, $input1, ...], {$neuronid => $neuronvalue, ...} )

You /must/ pass the correct number of inputs and neurons, and undefined values
    /must/ be zeros, not undef.
Returns raw value (linear potential)

=head1 AUTHOR

Dan Collins <DCOLLINS@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Dan Collins.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut

