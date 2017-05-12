use strict;
use warnings;

package AI::MaxEntropy;

use Algorithm::LBFGS;
use AI::MaxEntropy::Model;
use XSLoader;

our $VERSION = '0.20';
XSLoader::load('AI::MaxEntropy', $VERSION);

sub new {
    my $class = shift;
    my $self = {
       smoother => {},
       algorithm => {},
       @_,
       samples => [],
       x_bucket => {},
       y_bucket => {},
       x_list => [],
       y_list => [],
       x_num => 0,
       y_num => 0,
       f_num => 0,
       af_num => 0,
       f_freq => [],
       f_map => [],
       last_cut => -1,
       _c => {}
    };
    return bless $self, $class;
}

sub see {
    my ($self, $x, $y, $w) = @_;
    $w = 1 if not defined($w);
    my ($x1, $y1) = ([], undef);
    # preprocess if $x is hashref
    $x = [
        map {
	    my $attr = $_;
	    ref($x->{$attr}) eq 'ARRAY' ? 
	        map { "$attr:$_" } @{$x->{$attr}} : "$_:$x->{$_}" 
        } keys %$x
    ] if ref($x) eq 'HASH';
    # update af_num
    $self->{af_num} = scalar(@$x) if $self->{af_num} == 0;
    $self->{af_num} = -1 if $self->{af_num} != scalar(@$x);
    # convert y from string to ID
    my $y_id = $self->{y_bucket}->{$y};
    # new y
    if (!defined($y_id)) {
        # update y_list, y_num, y_bucket, f_freq
        push @{$self->{y_list}}, $y;
	$self->{y_num} = scalar(@{$self->{y_list}});
	$y_id = $self->{y_num} - 1;
	$self->{y_bucket}->{$y} = $y_id;
	push @{$self->{f_freq}}, [map { 0 } (1 .. $self->{x_num})];
	# save ID
	$y1 = $y_id;
    }
    # old y
    else { $y1 = $y_id }
    # convert x from strings to IDs
    for (@$x) {
        my $x_id = $self->{x_bucket}->{$_};
	# new x
	if (!defined($x_id)) {
	    # update x_list, x_num, x_bucket, f_freq
	    push @{$self->{x_list}}, $_;
	    $self->{x_num} = scalar(@{$self->{x_list}});
	    $x_id = $self->{x_num} - 1;
	    $self->{x_bucket}->{$_} = $x_id;
	    push @{$self->{f_freq}->[$_]}, 0 for (0 .. $self->{y_num} - 1);
	    # save ID
	    push @$x1, $x_id;
	}
        # old x
	else { push @$x1, $x_id }
	# update f_freq
	$self->{f_freq}->[$y_id]->[$x_id] += $w;
    }
    # add the sample
    push @{$self->{samples}}, [$x1, $y1, $w];
    $self->{last_cut} = -1;
}

sub cut {
    my ($self, $t) = @_;
    $self->{f_num} = 0;
    for my $y (0 .. $self->{y_num} - 1) {
        for my $x (0 .. $self->{x_num} - 1) {
	    if ($self->{f_freq}->[$y]->[$x] >= $t) {
	        $self->{f_map}->[$y]->[$x] = $self->{f_num};
		$self->{f_num}++;
	    }
	    else { $self->{f_map}->[$y]->[$x] = -1 }
	}
    }
    $self->{last_cut} = $t;
}

sub forget_all {
    my $self = shift;
    $self->{samples} = [];
    $self->{x_bucket} = {};
    $self->{y_bucket} = {};
    $self->{x_num} = 0;
    $self->{y_num} = 0;
    $self->{f_num} = 0;
    $self->{x_list} = [];
    $self->{y_list} = [];
    $self->{af_num} = 0;
    $self->{f_freq} = [];
    $self->{f_map} = [];
    $self->{last_cut} = -1;
    $self->{_c} = {};
}

sub _cache {
    my $self = shift;
    $self->_cache_samples;
    $self->_cache_f_map;
}

sub _free_cache {
    my $self = shift;
    $self->_free_cache_samples;
    $self->_free_cache_f_map;
}

sub learn {
    my $self = shift;
    # cut 0 for default
    $self->cut(0) if $self->{last_cut} == -1;
    # initialize
    $self->{lambda} = [map { 0 } (1 .. $self->{f_num})];
    $self->_cache;
    # optimize
    my $type = $self->{algorithm}->{type} || 'lbfgs';
    if ($type eq 'lbfgs') {
        my $o = Algorithm::LBFGS->new(%{$self->{algorithm}});
        $o->fmin(\&_neg_log_likelihood, $self->{lambda},
            $self->{algorithm}->{progress_cb}, $self);
    }
    elsif ($type eq 'gis') {
        die 'GIS is not applicable'
	    if $self->{af_num} == -1 or $self->{last_cut} != 0;
	my $progress_cb = $self->{algorithm}->{progress_cb};
	$progress_cb = sub {
	    print "$_[0]: |lambda| = $_[3], |d_lambda| = $_[4]\n"; 0;
        } if defined($progress_cb) and $progress_cb eq 'verbose';
        my $epsilon = $self->{algorithm}->{epsilon} || 1e-3;
        $self->{lambda} = $self->_apply_gis($progress_cb, $epsilon);
    }
    else { die "$type is not a valid algorithm type" }
    # finish
    $self->_free_cache;
    return $self->_create_model;
}

sub _create_model {
    my $self = shift;
    my $model = AI::MaxEntropy::Model->new;    
    $model->{$_} = ref($self->{$_}) eq 'ARRAY' ? [@{$self->{$_}}] :
                   ref($self->{$_}) eq 'HASH' ? {%{$self->{$_}}} :
		   $self->{$_}
    for qw/x_list y_list lambda x_num y_num f_num x_bucket y_bucket/;
    $model->{f_map}->[$_] = [@{$self->{f_map}->[$_]}]
       for (0 .. $self->{y_num} - 1); 
    return $model;
}

1;

__END__

=head1 NAME

AI::MaxEntropy - Perl extension for learning Maximum Entropy Models

=head1 SYNOPSIS

  use AI::MaxEntropy;

  # create a maximum entropy learner
  my $me = AI::MaxEntropy->new; 
  
  # the learner see 2 red round smooth apples
  $me->see(['round', 'smooth', 'red'] => 'apple' => 2);
  
  # the learner see 3 yellow long smooth bananas
  $me->see(['long', 'smooth', 'yellow'] => 'banana' => 3);

  # and more

  # samples needn't have the same numbers of active features
  $me->see(['rough', 'big'] => 'pomelo');

  # the order of active features is not concerned, too
  $me->see(['big', 'rough'] => 'pomelo');

  # ...

  # and, let it learn
  my $model = $me->learn;

  # then, we can make predictions on unseen data

  # ask what a red thing is most likely to be
  print $model->predict(['red'])."\n";
  # the answer is apple, because all red things the learner have ever seen
  # are apples
  
  # ask what a smooth thing is most likely to be
  print $model->predict(['smooth'])."\n";
  # the answer is banana, because the learner have seen more smooth bananas
  # (weighted 3) than smooth apples (weighted 2)

  # ask what a red, long thing is most likely to be
  print $model->predict(['red', 'long'])."\n";
  # the answer is banana, because the learner have seen more long bananas
  # (weighted 3) than red apples (weighted 2)

  # print out scores of all possible answers to the feature round and red
  for ($model->all_labels) {
      my $s = $model->score(['round', 'red'] => $_);
      print "$_: $s\n";
  }
  
  # save the model
  $model->save('model_file');

  # load the model
  $model->load('model_file');

=head1 CONCEPTS

=head2 What is a Maximum Entropy model?

Maximum Entropy (ME) model is a popular approach for machine learning.
From a user's view, it just behaves like a classifier which classify things
according to the previously learnt things.

Theorically, a ME learner try to recover the real probability distribution 
of the data based on limited number of observations, by applying the
principle of maximum entropy. 

You can find some good tutorials on Maximum Entropy model here:

L<http://homepages.inf.ed.ac.uk/s0450736/maxent.html>

=head2 Features

Generally, a feature is a binary function answers a yes-no question on a
specified piece of data. 

For examples, 

  "Is it a red apple?"

  "Is it a yellow banana?"

If the answer is yes,
we say this feature is active on that piece of data.

In practise, a feature is usually represented as
a tuple C<E<lt>x, yE<gt>>. For examples, the above two features can be
represented as

  <red, apple>

  <yellow, banana>

=head2 Samples

A sample is a set of active features, all of which share a common C<y>.
This common C<y> is sometimes called label or tag.
For example, we have a big round red apple, the correpsonding sample is 

  {<big, apple>, <round, apple>, <red, apple>}

In this module, a samples is denoted in Perl code as

  $xs => $y => $w

C<$xs> is an array ref holding all C<x>,
C<$y> is a scalar holding the label
and C<$w> is the weight of the sample, which tells how many times the
sample occurs.

Therefore, the above sample can be denoted as

  ['big', 'round', 'red'] => 'apple' => 1.0

The weight C<$w> can be ommited when it equals to 1.0,
so the above denotation can be shorten to

  ['big', 'round', 'red'] => 'apple'

=head2 Models

With a set of samples, a model can be learnt for future predictions.
The model (the lambda vector essentailly) is a knowledge representation
of the samples that it have seen before.
By applying the model, we can calculate the probability of each possible
label for a certain sample. And choose the most possible one
according to these probabilities.

=head1 FUNCTIONS

NOTE: This is still an alpha version, the APIs may be changed
in future versions.

=head2 new

Create a Maximum Entropy learner. Optionally, initial values of properties
can be specified.

  my $me1 = AI::MaxEntropy->new;
  my $me2 = AI::MaxEntropy->new(
      algorithm => { epsilon => 1e-6 });
  my $me3 = AI::MaxEntropy->new(
      algorithm => { m => 7, epsilon => 1e-4 },
      smoother => { type => 'gaussian', sigma => 0.8 }
  );

=head2 see

Let the Maximum Entropy learner see a sample.

  my $me = AI::MaxEntropy->new;

  # see a sample with default weight 1.0
  $me->see(['red', 'round'] => 'apple');
  
  # see a sample with specified weight 0.5
  $me->see(['yellow', 'long'] => 'banana' => 0.5);

The sample can be also represented in the attribute-value form, which like

  $me->see({color => 'yellow', shape => 'long'} => 'banana');
  $me->see({color => ['red', 'green'], shape => 'round'} => 'apple');

Actually, the two samples above are converted internally to,

  $me->see(['color:yellow', 'shape:long'] => 'banana');
  $me->see(['color:red', 'color:green', 'shape:round'] => 'apple');

=head2 forget_all

Forget all samples the learner have seen previously.

=head2 cut

Cut the features that occur less than the specified number.

For example, 

  ...
  $me->cut(1)

will cut all features that occur less than one time.

=head2 learn 

Learn a model from all the samples that the learner have seen so far,
returns an L<AI::MaxEntropy::Model> object, which can be used to make
prediction on unlabeled samples.

  ...

  my $model = $me->learn;

  print $model->predict(['x1', 'x2', ...]);

=head1 PROPERTIES

=head2 algorithm

This property enables client program to choose different algorithms for
learning the ME model and set their parameters.

There are mainly 3 algorithm for learning ME models, they are GIS, IIS and
L-BFGS. This module implements 2 of them, namely,  L-BFGS and GIS.
L-BFGS provides full functionality, while GIS runs faster, but only 
applicable on limited scenarios.

To use GIS, the following conditions must be satisified:

1. All samples have same number of active features

2. No feature has been cut

3. No smoother is used (in fact, the property L</smoother> is simplly
ignored when the type of algorithm equal to 'gis').

This property C<algorithm> is supposed to be a hash ref, like

  {
    type => ...,
    progress_cb => ...,
    param_1 => ...,
    param_2 => ...,
    ...,
    param_n => ...
  }

=head3 type

The entry C<type =E<gt> ...> specifies which algorithm is used for the 
optimization. Valid values include:

  'lbfgs'       Limited-memory Broyden-Fletcher-Goldfarb-Shanno (L-BFGS)
  'gis'         General Iterative Scaling (GIS)

If ommited, C<'lbfgs'> is used by default.

=head3 progress_cb

The entry C<progress_cb =E<gt> ...> specifies the progress callback
subroutine which is used to trace the process of the algorithm. 
The specified callback routine will be called at each iteration of the
algorithm.

For L-BFGS, C<progress_cb> will be directly passed to
L<Algorithm::LBFGS/fmin>. C<f(x)> is the negative log-likelihood of current
lambda vector.

For GIS, the C<progress_cb> is supposed to have a prototype like

  progress_cb(i, lambda, d_lambda, lambda_norm, d_lambda_norm)

C<i> is the number of the iterations, C<lambda> is an array ref containing
the current lambda vector, C<d_lambda> is an array ref containing the
delta of the lambda vector in current iteration, C<lambda_norm> and
C<d_lambda_norm> are Euclid norms of C<lambda> and C<d_lambda> respectively.

For both L-BFGS and GIS, the client program can also pass a string
C<'verbose'> to C<progress_cb> to use a default progress callback
which simply print out the progress on the screen.

C<progress_cb> can also be omitted if the client program
do not want to trace the progress.

=head3 parameters

The rest entries are parameters for the specified algorithm.
Each parameter will be assigned with its default value when it is not
given explicitly.

For L-BFGS, the parameters will be directly passed to
L<Algorithm::LBFGS> object, please refer to L<Algorithm::LBFGS/Parameters>
for details.

For GIS, there is only one parameter C<epsilon>, which controls the
precision of the algorithm (similar to the C<epsilon> in
L<Algorithm::LBFGS>). Generally speaking, a smaller C<epsilon> produces
a more precise result. The default value of C<epsilon> is 1e-3.

=head2 smoother

The smoother is a solution to the over-fitting problem. 
This property chooses which type of smoother the client program want to
apply and sets the smoothing parameters. 

Only one smoother have been implemented in this version of the module, 
the Gaussian smoother.

One can apply the Gaussian smoother as following,

  my $me = AI::MaxEntropy->new(
      smoother => { type => 'gaussian', sigma => 0.6 }
  );

The parameter C<sigma> indicates the strength of smoothing.
Usually, sigma is a positive number no greater than 1.0.
The strength of smoothing grows as sigma getting close to 0.

=head1 SEE ALSO

L<AI::MaxEntropy::Model>, L<AI::MaxEntropy::Util>

L<Algorithm::LBFGS>

L<Statistics::MaxEntropy>, L<Algorithm::CRF>, L<Algorithm::SVM>,
L<AI::DecisionTree>

=head1 AUTHOR

Laye Suen, E<lt>laye@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The MIT License

Copyright (C) 2008, Laye Suen

Permission is hereby granted, free of charge, to any person obtaining a 
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

=head1 REFERENCE

=over

=item
A. L. Berge, V. J. Della Pietra, S. A. Della Pietra. 
A Maximum Entropy Approach to Natural Language Processing,
Computational Linguistics, 1996.

=item
S. F. Chen, R. Rosenfeld.
A Gaussian Prior for Smoothing Maximum Entropy Models,
February 1999 CMU-CS-99-108.

=back
