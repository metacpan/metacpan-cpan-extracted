=head1 NAME

AI::Perceptron - example of a node in a neural network.

=head1 SYNOPSIS

 use AI::Perceptron;

 my $p = AI::Perceptron->new
           ->num_inputs( 2 )
           ->learning_rate( 0.04 )
           ->threshold( 0.02 )
           ->weights([ 0.1, 0.2 ]);

 my @inputs  = ( 1.3, -0.45 );   # input can be any number
 my $target  = 1;                # output is always -1 or 1
 my $current = $p->compute_output( @inputs );

 print "current output: $current, target: $target\n";

 $p->add_examples( [ $target, @inputs ] );

 $p->max_iterations( 10 )->train or
   warn "couldn't train in 10 iterations!";

 print "training until it gets it right\n";
 $p->max_iterations( -1 )->train; # watch out for infinite loops

=cut

package AI::Perceptron;

use strict;
use accessors qw( num_inputs learning_rate _weights threshold
		  training_examples max_iterations );

our $VERSION = '1.0';
our $Debug   = 0;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    return $self->init( @_ );
}

sub init {
    my $self = shift;
    my %args = @_;

    $self->num_inputs( $args{Inputs} || 1 )
         ->learning_rate( $args{N} || 0.05 )
	 ->max_iterations( -1 )
	 ->threshold( $args{T} || 0.0 )
	 ->training_examples( [] )
	 ->weights( [] );

    # DEPRECATED: backwards compat
    if ($args{W}) {
	$self->threshold( shift @{ $args{W} } )
	     ->weights( [ @{ $args{W} } ] );
    }

    return $self;
}

sub verify_weights {
    my $self = shift;

    for my $i (0 .. $self->num_inputs-1) {
	$self->weights->[$i] ||= 0.0;
    }

    return $self;
}

# DEPRECATED: backwards compat
sub weights {
    my $self = shift;
    my $ret  = $self->_weights(@_);
    return wantarray ? ( $self->threshold, @{ $self->_weights } ) : $ret;
}

sub add_examples {
    my $self = shift;

    foreach my $ex (@_) {
	die "training examples must be arrayrefs!" unless (ref $ex eq 'ARRAY');
	my @inputs = @{$ex}; # be nice, take a copy
	my $target = shift @inputs;
	die "expected result must be either -1 or 1, not $target!"
	  unless (abs $target == 1);
	# TODO: avoid duplicate entries
	push @{ $self->training_examples }, [$target, @inputs];
    }

    return $self;
}

sub add_example {
    shift->add_examples(@_);
}

sub compute_output {
    my $self   = shift;
    my @inputs = @_;

    my $sum = $self->threshold; # start at threshold
    for my $i (0 .. $self->num_inputs-1) {
	$sum += $self->weights->[$i] * $inputs[$i];
    }

    # binary (returning the real $sum is not part of this model)
    return ($sum > 0) ? 1 : -1;
}

##
# $p->train( [ @training_examples ] )
#                    \--> [ $target_output, @inputs ]
sub train {
    my $self = shift;
    $self->add_examples( @_ ) if @_;

    $self->verify_weights;

    # adjust the weights for each training example until the output
    # function correctly classifies all the training examples.
    my $iter = 0;
    while(! $self->classifies_examples_correctly ) {

	if (($self->max_iterations > 0) and
	    ($iter >= $self->max_iterations)) {
	    $self->emit( "stopped training after $iter iterations" );
	    return;
	}

	$iter++;
	$self->emit( "Training iteration $iter" );

	foreach my $training_example (@{ $self->training_examples }) {
	    my ($expected_output, @inputs) = @$training_example;

	    $self->emit( "Training X=<", join(',', @inputs),
			 "> with target $expected_output" ) if $Debug > 1;

	    # want the perceptron's output equal to training output
	    # TODO: this duplicates work by classifies_examples_correctly()
	    my $output = $self->compute_output(@inputs);
	    next if ($output == $expected_output);

	    $self->adjust_threshold( $expected_output, $output )
	         ->adjust_weights( \@inputs, $expected_output, $output );
	}
    }

    $self->emit( "completed in $iter iterations." );

    return $self;
}

# return true unless all training examples are correctly classified
sub classifies_examples_correctly {
    my $self = shift;
    my $training_examples = $self->training_examples;

    foreach my $training_example (@$training_examples) {
	my ($output, @inputs) = @{$training_example};
	return if ($self->compute_output( @inputs ) != $output);
    }

    return 1;
}

sub adjust_threshold {
    my $self            = shift;
    my $expected_output = shift;
    my $output          = shift;
    my $n               = $self->learning_rate;

    my $delta = $n * ($expected_output - $output);
    $self->threshold( $self->threshold + $delta );

    return $self;
}

sub adjust_weights {
    my $self            = shift;
    my $inputs          = shift;
    my $expected_output = shift;
    my $output          = shift;
    my $n               = $self->learning_rate;

    for my $i (0 .. $self->num_inputs-1) {
	my $delta = $n * ($expected_output - $output) * $inputs->[$i];
	$self->weights->[$i] += $delta;
    }

    return $self;
}

sub emit {
    return unless $Debug;
    my $self = shift;
    push @_, "\n" unless grep /\n/, @_;
    warn( @_ );
}

1;

__END__

=head1 DESCRIPTION

This module is meant to show how a single node of a neural network works.

Training is done by the I<Stochastic Approximation of the Gradient-Descent>
model.

=head1 MODEL

Model of a Perceptron

              +---------------+
 X[1] o------ |W[1]      T    |
 X[2] o------ |W[2] +---------+         +-------------------+
  .           | .   |   ___   |_________|    __  Squarewave |_______\  Output
  .           | .   |   \     |    S    | __|    Generator  |       /
  .           | .   |   /__   |         +-------------------+
 X[n] o------ |W[n] |   Sum   |
              +-----+---------+

	     S  =  T + Sum( W[i]*X[i] )  as i goes from 1 -> n
	Output  =  1 if S > 0; else -1

Where C<X[n]> are the perceptron's I<inputs>, C<W[n]> are the I<Weights> that
get applied to the corresponding input, and C<T> is the I<Threshold>.

The I<squarewave generator> just turns the result into a positive or negative
number.

So in summary, when you feed the perceptron some numeric inputs you get either
a positive or negative output depending on the input's weights and a threshold.

=head1 TRAINING

Usually you have to train a perceptron before it will give you the outputs you
expect.  This is done by giving the perceptron a set of examples containing the
output you want for some given inputs:

    -1 => -1, -1
    -1 =>  1, -1
    -1 => -1,  1
     1 =>  1,  1

If you've ever studied boolean logic, you should recognize that as the truth
table for an C<AND> gate (ok so we're using -1 instead of the commonly used 0,
same thing really).

You I<train> the perceptron by iterating over the examples and adjusting the
I<weights> and I<threshold> by some value until the perceptron's output matches
the expected output of each example:

    while some examples are incorrectly classified
        update weights for each example that fails

The value each weight is adjusted by is calculated as follows:

    delta[i] = learning_rate * (expected_output - output) * input[i]

Which is know as a negative feedback loop - it uses the current output as an
input to determine what the next output will be.

Also, note that this means you can get stuck in an infinite loop.  It's not a
bad idea to set the maximum number of iterations to prevent that.

=head1 CONSTRUCTOR

=over 4

=item new( [%args] )

Creates a new perceptron with the following default properties:

    num_inputs    = 1
    learning_rate = 0.01
    threshold     = 0.0
    weights       = empty list

Ideally you should use the accessors to set the properties, but for backwards
compatability you can still use the following arguments:

    Inputs => $number_of_inputs  (positive int)
    N      => $learning_rate     (float)
    W      => [ @weights ]       (floats)

The number of elements in I<W> must be equal to the number of inputs plus one.
This is because older version of AI::Perceptron combined the threshold and the
weights a single list where W[0] was the threshold and W[1] was the first
weight.  Great idea, eh? :)  That's why it's I<DEPRECATED>.

=back

=head1 ACCESSORS

=over 4

=item num_inputs( [ $int ] )

Set/get the perceptron's number of inputs.

=item learning_rate( [ $float ] )

Set/get the perceptron's number of inputs.

=item weights( [ \@weights ] )

Set/get the perceptron's weights (floats).

For backwards compatability, returns a list containing the I<threshold> as the
first element in list context:

  ($threshold, @weights) = $p->weights;

This usage is I<DEPRECATED>.

=item threshold( [ $float ] )

Set/get the perceptron's number of inputs.

=item training_examples( [ \@examples ] )

Set/get the perceptron's list of training examples.  This should be a list of
arrayrefs of the form:

    [ $expected_result => @inputs ]

=item max_iterations( [ $int ] )

Set/get the perceptron's number of inputs, a negative value implies no maximum.

=back

=head1 METHODS

=over 4

=item compute_output( @inputs )

Computes and returns the perceptron's output (either -1 or 1) for the given
inputs.  See the above model for more details.

=item add_examples( @training_examples )

Adds the @training_examples to to current list of examples.  See
L<training_examples()> for more details.

=item train( [ @training_examples ] )

Uses the I<Stochastic Approximation of the Gradient-Descent> model to adjust
the perceptron's weights until all training examples are classified correctly.

@training_examples can be passed for convenience.  These are passed to
L<add_examples()>.  If you want to re-train the perceptron with an entirely new
set of examples, reset the L<training_examples()>.

=back

=head1 AUTHOR

Steve Purkis E<lt>spurkis@epn.nuE<gt>

=head1 COPYRIGHT

Copyright (c) 1999-2003 Steve Purkis.  All rights reserved.

This package is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 REFERENCES

I<Machine Learning>, by Tom M. Mitchell.

=head1 THANKS

Himanshu Garg E<lt>himanshu@gdit.iiit.netE<gt> for his bug-report and feedback.
Many others for their feedback.

=head1 SEE ALSO

L<Statistics::LTU>,
L<AI::jNeural>,
L<AI::NeuralNet::BackProp>,
L<AI::NeuralNet::Kohonen>

=cut

