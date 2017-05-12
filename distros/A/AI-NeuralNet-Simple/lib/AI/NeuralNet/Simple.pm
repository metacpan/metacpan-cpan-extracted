package AI::NeuralNet::Simple;

use Log::Agent;

use strict;

use vars qw( $REVISION $VERSION @ISA );

$REVISION = '$Id: Simple.pm,v 1.3 2004/01/31 20:34:11 ovid Exp $';
$VERSION  = '0.11';

if ( $] >= 5.006 ) {
    require XSLoader;
    XSLoader::load( 'AI::NeuralNet::Simple', $VERSION );
}
else {
    require DynaLoader;
    push @ISA, 'DynaLoader';
    AI::NeuralNet::Simple->bootstrap($VERSION);
}

sub handle { $_[0]->{handle} }

sub new {
    my ( $class, @args ) = @_;
    logdie "you must supply three positive integers to new()"
      unless 3 == @args;
    foreach (@args) {
        logdie "arguments to new() must be positive integers"
          unless defined $_ && /^\d+$/;
    }
    my $seed = rand(1);    # Perl invokes srand() on first call to rand()
    my $handle = c_new_network(@args);
    logdie "could not create new network" unless $handle >= 0;
    my $self = bless {
        input  => $args[0],
        hidden => $args[1],
        output => $args[2],
        handle => $handle,
    }, $class;
    $self->iterations(10000);    # set a reasonable default
}

sub train {
    my ( $self, $inputref, $outputref ) = @_;
    return c_train( $self->handle, $inputref, $outputref );
}

sub train_set {
    my ( $self, $set, $iterations, $mse ) = @_;
    $iterations ||= $self->iterations;
    $mse = -1.0 unless defined $mse;
    return c_train_set( $self->handle, $set, $iterations, $mse );
}

sub iterations {
    my ( $self, $iterations ) = @_;
    if ( defined $iterations ) {
        logdie "iterations() value must be a positive integer."
          unless $iterations
          and $iterations =~ /^\d+$/;
        $self->{iterations} = $iterations;
        return $self;
    }
    $self->{iterations};
}

sub delta {
    my ( $self, $delta ) = @_;
    return c_get_delta( $self->handle )              unless defined $delta;
    logdie "delta() value must be a positive number" unless $delta > 0.0;
    c_set_delta( $self->handle, $delta );
    return $self;
}

sub use_bipolar {
    my ( $self, $bipolar ) = @_;
    return c_get_use_bipolar( $self->handle ) unless defined $bipolar;
    c_set_use_bipolar( $self->handle, $bipolar );
    return $self;
}

sub infer {
    my ( $self, $data ) = @_;
    c_infer( $self->handle, $data );
}

sub winner {

    # returns index of largest value in inferred answer
    my ( $self, $data ) = @_;
    my $arrayref = c_infer( $self->handle, $data );

    my $largest = 0;
    for ( 0 .. $#$arrayref ) {
        $largest = $_ if $arrayref->[$_] > $arrayref->[$largest];
    }
    return $largest;
}

sub learn_rate {
    my ( $self, $rate ) = @_;
    return c_get_learn_rate( $self->handle ) unless defined $rate;
    logdie "learn rate must be between 0 and 1, exclusive"
      unless $rate > 0 && $rate < 1;
    c_set_learn_rate( $self->handle, $rate );
    return $self;
}

sub DESTROY {
    my $self = shift;
    c_destroy_network( $self->handle );
}

#
# Serializing hook for Storable
#

sub STORABLE_freeze {
    my ( $self, $cloning ) = @_;
    my $internal = c_export_network( $self->handle );

    # This is an excellent example where "we know better" than
    # the recommended way in Storable's man page...
    # Behaviour is the same whether we're cloning or not --RAM

    my %copy = %$self;
    delete $copy{handle};

    return ( "", \%copy, $internal );
}

#
# Deserializing hook for Storable
#
sub STORABLE_thaw {
    my ( $self, $cloning, $x, $copy, $internal ) = @_;
    %$self = %$copy;
    $self->{handle} = c_import_network($internal);
}

1;

__END__

=head1 NAME

AI::NeuralNet::Simple - An easy to use backprop neural net.

=head1 SYNOPSIS

  use AI::NeuralNet::Simple;
  my $net = AI::NeuralNet::Simple->new(2,1,2);
  # teach it logical 'or'
  for (1 .. 10000) {
      $net->train([1,1],[0,1]);
      $net->train([1,0],[0,1]);
      $net->train([0,1],[0,1]);
      $net->train([0,0],[1,0]);
  }
  printf "Answer: %d\n",   $net->winner([1,1]);
  printf "Answer: %d\n",   $net->winner([1,0]);
  printf "Answer: %d\n",   $net->winner([0,1]);
  printf "Answer: %d\n\n", $net->winner([0,0]);

=head1 ABSTRACT

  This module is a simple neural net designed for those who have an interest
  in artificial intelligence but need a "gentle" introduction.  This is not
  intended to replace any of the neural net modules currently available on the
  CPAN.

=head1 DESCRIPTION

=head2 The Disclaimer

Please note that the following information is terribly incomplete.  That's
deliberate.  Anyone familiar with neural networks is going to laugh themselves
silly at how simplistic the following information is and the astute reader will
notice that I've raised far more questions than I've answered.

So why am I doing this?  Because I'm giving I<just enough> information for
someone new to neural networks to have enough of an idea of what's going on so
they can actually use this module and then move on to something more powerful,
if interested.

=head2 The Biology

A neural network, at its simplest, is merely an attempt to mimic nature's
"design" of a brain.  Like many successful ventures in the field of artificial
intelligence, we find that blatantly ripping off natural designs has allowed us
to solve many problems that otherwise might prove intractable.  Fortunately,
Mother Nature has not chosen to apply for patents.

Our brains are comprised of neurons connected to one another by axons.  The
axon makes the actual connection to a neuron via a synapse.  When neurons
receive information, they process it and feed this information to other neurons
who in turn process the information and send it further until eventually
commands are sent to various parts of the body and muscles twitch, emotions are
felt and we start eyeing our neighbor's popcorn in the movie theater, wondering
if they'll notice if we snatch some while they're watching the movie.

=head2 A simple example of a neuron

Now that you have a solid biology background (uh, no), how does this work when
we're trying to simulate a neural network?  The simplest part of the network is
the neuron (also known as a node or, sometimes, a neurode).  A we might think
of a neuron as follows (OK, so I won't make a living as an ASCII artist):

Input neurons   Synapses   Neuron   Output

                            ----
  n1            ---w1----> /    \
  n2            ---w2---->|  n4  |---w4---->
  n3            ---w3----> \    /
                            ----

(Note that the above doesn't quite match what's in the C code for this module,
but it's close enough for you to get the idea.  This is one of the many
oversimplifications that have been made).

In the above example, we have three input neurons (n1, n2, and n3).  These
neurons feed whatever output they have through the three synapses (w1, w2, w3)
to the neuron in question, n4.  The three synapses each have a "weight", which
is an amount that the input neurons' output is multiplied by.  

The neuron n4 computes its output with something similar to the following:

  output = 0

  foreach (input.neuron)
      output += input.neuron.output * input.neuron.synapse.weight

  ouput = activation_function(output)

The "activation function" is a special function that is applied to the inputs
to generate the actual output.  There are a variety of activation functions
available with three of the most common being the linear, sigmoid, and tahn
activation functions.  For technical reasons, the linear activation function
cannot be used with the type of network that C<AI::NeuralNet::Simple> employs.
This module uses the sigmoid activation function.  (More information about
these can be found by reading the information in the L<SEE ALSO> section or by
just searching with Google.)

Once the activation function is applied, the output is then sent through the
next synapse, where it will be multiplied by w4 and the process will continue.

=head2 C<AI::NeuralNet::Simple> architecture

The architecture used by this module has (at present) 3 fixed layers of
neurons: an input, hidden, and output layer.  In practice, a 3 layer network is
applicable to many problems for which a neural network is appropriate, but this
is not always the case.  In this module, we've settled on a fixed 3 layer
network for simplicity.

Here's how a three layer network might learn "logical or".  First, we need to
determine how many inputs and outputs we'll have.  The inputs are simple, we'll
choose two inputs as this is the minimum necessary to teach a network this
concept.  For the outputs, we'll also choose two neurons, with the neuron with
the highest output value being the "true" or "false" response that we are
looking for.  We'll only have one neuron for the hidden layer.  Thus, we get a
network that resembles the following:

           Input   Hidden   Output

 input1  ----> n1 -+    +----> n4 --->  output1
                    \  /
                     n3
                    /  \
 input2  ----> n2 -+    +----> n5 --->  output2

Let's say that output 1 will correspond to "false" and output 2 will correspond
to true.  If we feed 1 (or true) or both input 1 and input 2, we hope that output
2 will be true and output 1 will be false.  The following table should illustrate
the expected results:

 input   output
 1   2   1    2
 -----   ------
 1   1   0    1
 1   0   0    1
 0   1   0    1
 0   0   1    0

The type of network we use is a forward-feed back error propagation network,
referred to as a back-propagation network, for short.  The way it works is
simple.  When we feed in our input, it travels from the input to hidden layers
and then to the output layers.  This is the "feed forward" part.  We then
compare the output to the expected results and measure how far off we are.  We
then adjust the weights on the "output to hidden" synapses, measure the error
on the hidden nodes and then adjust the weights on the "hidden to input"
synapses.  This is what is referred to as "back error propagation".

We continue this process until the amount of error is small enough that we are
satisfied.  In reality, we will rarely if ever get precise results from the
network, but we learn various strategies to interpret the results.  In the
example above, we use a "winner takes all" strategy.  Which ever of the output
nodes has the greatest value will be the "winner", and thus the answer.

In the examples directory, you will find a program named "logical_or.pl" which
demonstrates the above process.

=head2 Building a network

In creating a new neural network, there are three basic steps:

=over 4

=item 1 Designing

This is choosing the number of layers and the number of neurons per layer.  In
C<AI::NeuralNet::Simple>, the number of layers is fixed.

With more complete neural net packages, you can also pick which activation
functions you wish to use and the "learn rate" of the neurons.

=item 2 Training

This involves feeding the neural network enough data until the error rate is
low enough to be acceptable.  Often we have a large data set and merely keep
iterating until the desired error rate is achieved.

=item 3 Measuring results

One frequent mistake made with neural networks is failing to test the network
with different data from the training data.  It's quite possible for a
backpropagation network to hit what is known as a "local minimum" which is not
truly where it should be.  This will cause false results.  To check for this,
after training we often feed in other known good data for verification.  If the
results are not satisfactory, perhaps a different number of neurons per layer
should be tried or a different set of training data should be supplied.

=back

=head1 Programming C<AI::NeuralNet::Simple>

=head2 C<new($input, $hidden, $output)>

C<new()> accepts three integers.  These number represent the number of nodes in
the input, hidden, and output layers, respectively.  To create the "logical or"
network described earlier:

  my $net = AI::NeuralNet::Simple->new(2,1,2);

By default, the activation function for the neurons is the sigmoid function
S() with delta = 1:

	S(x) = 1 / (1 + exp(-delta * x))

but you can change the delta after creation.  You can also use a bipolar
activation function T(), using the hyperbolic tangent:

	T(x) = tanh(delta * x)
	tanh(x) = (exp(x) - exp(-x)) / (exp(x) + exp(-x))

which allows the network to have neurons negatively impacting the weight,
since T() is a signed function between (-1,+1) whereas S() only falls
within (0,1).

=head2 C<delta($delta)>

Fetches the current I<delta> used in activation functions to scale the
signal, or sets the new I<delta>. The higher the delta, the steeper the
activation function will be.  The argument must be strictly positive.

You should not change I<delta> during the traning.

=head2 C<use_bipolar($boolean)>

Returns whether the network currently uses a bipolar activation function.
If an argument is supplied, instruct the network to use a bipolar activation
function or not.

You should not change the activation function during the traning.

=head2 C<train(\@input, \@output)>

This method trains the network to associate the input data set with the output
data set.  Representing the "logical or" is as follows:

  $net->train([1,1] => [0,1]);
  $net->train([1,0] => [0,1]);
  $net->train([0,1] => [0,1]);
  $net->train([0,0] => [1,0]);

Note that a one pass through the data is seldom sufficient to train a network.
In the example "logical or" program, we actually run this data through the
network ten thousand times.

  for (1 .. 10000) {
    $net->train([1,1] => [0,1]);
    $net->train([1,0] => [0,1]);
    $net->train([0,1] => [0,1]);
    $net->train([0,0] => [1,0]);
  }

The routine returns the Mean Squared Error (MSE) representing how far the
network answered.

It is far preferable to use C<train_set()> as this lets you control the MSE
over the training set and it is more efficient because there are less memory
copies back and forth.

=head2 C<train_set(\@dataset, [$iterations, $mse])>

Similar to train, this method allows us to train an entire data set at once.
It is typically faster than calling individual "train" methods.  The first
argument is expected to be an array ref of pairs of input and output array
refs.

The second argument is the number of iterations to train the set.  If
this argument is not provided here, you may use the C<iterations()> method to
set it (prior to calling C<train_set()>, of course).  A default of 10,000 will
be provided if not set.

The third argument is the targeted Mean Square Error (MSE). When provided,
the traning sequence will compute the maximum MSE seen during an iteration
over the training set, and if it is less than the supplied target, the
training stops.  Computing the MSE at each iteration costs, but you are
certain to not over-train your network.

  $net->train_set([
    [1,1] => [0,1],
    [1,0] => [0,1],
    [0,1] => [0,1],
    [0,0] => [1,0],
  ], 10000, 0.01);

The routine returns the MSE of the last iteration, which is the highest MSE
seen over the whole training set (and not an average MSE).

=head2 C<iterations([$integer])>

If called with a positive integer argument, this method will allow you to set
number of iterations that train_set will use and will return the network
object.  If called without an argument, it will return the number of iterations
it was set to.

  $net->iterations;         # returns 100000
  my @training_data = ( 
    [1,1] => [0,1],
    [1,0] => [0,1],
    [0,1] => [0,1],
    [0,0] => [1,0],
  );
  $net->iterations(100000) # let's have lots more iterations!
      ->train_set(\@training_data);
  
=head2 C<learn_rate($rate)>)

This method, if called without an argument, will return the current learning
rate.  .20 is the default learning rate.

If called with an argument, this argument must be greater than zero and less
than one.  This will set the learning rate and return the object.
  
  $net->learn_rate; #returns the learning rate
  $net->learn_rate(.1)
      ->iterations(100000)
      ->train_set(\@training_data);

If you choose a lower learning rate, you will train the network slower, but you
may get a better accuracy.  A higher learning rate will train the network
faster, but it can have a tendancy to "overshoot" the answer when learning and
not learn as accurately.

=head2 C<infer(\@input)>

This method, if provided with an input array reference, will return an array
reference corresponding to the output values that it is guessing.  Note that
these values will generally be close, but not exact.  For example, with the 
"logical or" program, you might expect results similar to:

  use Data::Dumper;
  print Dumper $net->infer([1,1]);
  
  $VAR1 = [
          '0.00993729281477686',
          '0.990100297418451'
        ];

That clearly has the second output item being close to 1, so as a helper method
for use with a winner take all strategy, we have ...

=head2 C<winner(\@input)>

This method returns the index of the highest value from inferred results:

  print $net->winner([1,1]); # will likely print "1"

For a more comprehensive example of how this is used, see the 
"examples/game_ai.pl" program.

=head1 EXPORT

None by default.

=head1 CAVEATS

This is B<alpha> code.  Very alpha.  Not even close to ready for production,
don't even think about it.  I'm putting it on the CPAN lest it languish on my
hard-drive forever.  Hopefully someone will get some use out of it and think to
send me a patch or two.

=head1 TODO

=over 4

=item * Allow different numbers of layers

=back

=head1 BUGS

Probably.

=head1 SEE ALSO

L<AI::FANN> - Perl wrapper for the Fast Artificial Neural Network library

L<AI::NNFlex> - A base class for implementing neural networks 

L<AI::NeuralNet::BackProp> - A simple back-prop neural net that uses Delta's
and Hebbs' rule

"AI Application Programming by M. Tim Jones, copyright (c) by Charles River
Media, Inc.  

The C code in this module is based heavily upon Mr. Jones backpropogation
network in the book.  The "game ai" example in the examples directory is based
upon an example he has graciously allowed me to use.  I I<had> to use it
because it's more fun than many of the dry examples out there :)

"Naturally Intelligent Systems", by Maureen Caudill and Charles Butler,
copyright (c) 1990 by Massachussetts Institute of Technology.

This book is a decent introduction to neural networks in general.  The forward
feed back error propogation is but one of many types.

=head1 AUTHORS

Curtis "Ovid" Poe, C<ovid [at] cpan [dot] org>

Multiple network support, persistence, export of MSE (mean squared error),
training until MSE below a given threshold and customization of the
activation function added by Raphael Manfredi C<Raphael_Manfredi@pobox.com>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2003-2005 by Curtis "Ovid" Poe

Copyright (c) 2006 by Raphael Manfredi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
