#######################################################
# AI::NNFlex::Mathlib
#######################################################
# Various custom mathematical functions for AI::NNFlex
#######################################################
#
# Version history
# ===============
#
# 1.0 	CColbourn	20050315	Compiled into a
#					single module
#
# 1.1	CColbourn	20050321	added in sigmoid_slope
#
# 1.2	CColbourn	20050330	Added in hopfield_threshold
#
# 1,3	CColbourn	20050407	Changed sigmoid function to
#					a standard sigmoid. sigmoid2
#					now contains old sigmoid,
#					which is more used in BPTT
#					and I think needs cross 
#					entropy calc to work.
#
#######################################################
#Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify

package AI::NNFlex::Mathlib;
use strict;

#######################################################
# tanh activation function
#######################################################
sub tanh
{

	my $network = shift;
	my $value = shift;

	my @debug = @{$network->{'debug'}};

	my $a = exp($value);
	my $b = exp(-$value);
   if ($value > 20){ $value=1;}
    elsif ($value < -20){ $value= -1;}
    else
        {
	        my $a = exp($value);
       		 my $b = exp(-$value);
   	        $value =  ($a-$b)/($a+$b);
        }
	if (scalar @debug > 0)
	{$network->dbug("Tanh activation returning $value",5)};	
	return $value;
}

sub tanh_slope
{
	my $network = shift;
	my $value = shift;
	my @debug = @{$network->{'debug'}};


	my $return = 1-($value*$value);
	if (scalar @debug > 0)
	{$network->dbug("Tanh_slope returning $value",5);}

	return $return;
}

#################################################################
# Linear activation function
#################################################################
sub linear
{

	my $network = shift;
	my $value = shift;	

	my @debug = @{$network->{'debug'}};
	if (scalar @debug >0)
	{$network->dbug("Linear activation returning $value",5)};	
	return $value;
}

sub linear_slope
{
	my $network = shift;
	my $value = shift;
	my @debug = @{$network->{'debug'}};
	if (scalar @debug >0)
	{$network->dbug("Linear slope returning $value",5)};
	return $value;
}


############################################################
# P&B sigmoid activation (needs slope)
############################################################

sub sigmoid2
{
	my $network = shift;
	my $value = shift;	
	$value = (1+exp(-$value))**-1;
	$network->dbug("Sigmoid activation returning $value",5);	
	return $value;
}

sub sigmoid2_slope
{
	my $network = shift;
	my $value = shift;
	my @debug = @{$network->{'debug'}};


	my $return = exp(-$value) * ((1 + exp(-$value)) ** -2);
	if (scalar @debug > 0)
	{$network->dbug("sigmoid_slope returning $value",5);}

	return $return;
}

############################################################
# standard sigmoid activation 
############################################################

sub sigmoid
{
	my $network = shift;
	my $value = shift;	
	$value = 1/(1+exp(1)**-$value);
	$network->dbug("Sigmoid activation returning $value",5);	
	return $value;
}

sub sigmoid_slope
{
	my $network = shift;
	my $value = shift;
	my @debug = @{$network->{'debug'}};


	my $return = $value * (1-$value);
	if (scalar @debug > 0)
	{$network->dbug("sigmoid_slope returning $value",5);}

	return $return;
}

############################################################
# hopfield_threshold
# standard hopfield threshold activation - doesn't need a 
# slope (because hopfield networks don't use them!)
############################################################
sub hopfield_threshold
{
	my $network = shift;
	my $value = shift;

	if ($value <0){return -1}
	if ($value >0){return 1}
	return $value;
}

############################################################
# atanh error function
############################################################
sub atanh
{
	my $network = shift;
	my $value = shift;
	if ($value >-0.5 && $value <0.5)
	{
		$value = log((1+$value)/(1-$value))/2;
	}
	return $value;
}

1;

=pod

=head1 NAME

AI::NNFlex::Mathlib - miscellaneous mathematical functions for the AI::NNFlex NN package

=head1 DESCRIPTION

The AI::NNFlex::Mathlib package contains activation and error functions. At present there are the following:

Activation functions

=over

=item *
tanh

=item *
linear

=item *
hopfield_threshold

=back

Error functions

=over

=item *
atanh

=back

If you want to implement your own activation/error functions, you can add them to this module. All activation functions to be used by certain types of net (like Backprop) require an additional function <function name>_slope, which returns the 1st order derivative of the function.

This rule doesn't apply to all network types. Hopfield for example requires no slope calculation.

=head1 CHANGES

v1.2 includes hopfield_threshold

=head1 COPYRIGHT

Copyright (c) 2004-2005 Charles Colbourn. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 CONTACT

 charlesc@nnflex.g0n.net



=cut
