#Algorithm::Viterbi
#Copyright (c) 2006 Koen Dejonghe. All rights reserved.
#This program is free software; you can redistribute it and/or
#modify it under the same terms as Perl itself.
package Algorithm::Viterbi;

use vars qw/$VERSION/;
$VERSION = '0.01';

=head1 NAME

Algorithm::Viterbi - Compute Viterbi path and probability 

=head1 SYNOPSIS

  use Algorithm::Viterbi;
  
  my $start_probability = { 'Rainy'=> 0.6, 'Sunny'=> 0.4 };

  my $transition_probability = {
   'Rainy' => {'Rainy'=> 0.7, 'Sunny'=> 0.3},
   'Sunny' => {'Rainy'=> 0.4, 'Sunny'=> 0.6},
  };

  my $emission = {
    'shop' =>  { 'Sunny' => '0.3', 'Rainy' => '0.4' },
    'walk' =>  { 'Sunny' => '0.6', 'Rainy' => '0.1' },
    'clean' => { 'Sunny' => '0.1', 'Rainy' => '0.5' }
  };

  my $v = Algorithm::Viterbi->new();
  $v->start($start_probability);
  $v->transition($transition_probability);
  $v->emission($emission_probability);

  my $observations = [ 'walk', 'shop', 'clean' ];

  my ($prob, $v_path, $v_prob) = $v->forward_viterbi($observations);

  -- or --
   
  my $training_data = [
    [ 'walk', 'Sunny' ],
    [ 'walk', 'Sunny' ],
    [ 'walk', 'Rainy' ],
    [ 'shop', 'Rainy' ],
    [ 'clean', 'Rainy' ],
    [ 'clean', 'Rainy' ],
    ...
  ];

  $v->train($training_data);
  my ($prob, $v_path, $v_prob) = $v->forward_viterbi($observations);

=head1 DESCRIPTION

Algorithm::Viterbi computes the forward probability, the Viterbi path
and the Viterbi probability of a sequence of observations, based on 
a given start, emission and transition probability.
Alternatively, the start, emission and transition probability can be 
computed from a set of training data.

The whole idea of this module is inspired by an article on the Viterbi 
algorithm in Wikipedia, the free encyclopedia. Rather than copying all 
text, I'm just including the link to the Wikipedia page: 
L<http://en.wikipedia.org/wiki/Viterbi_algorithm>.
I think the page is well-written and I see no need to repeat the theory 
here. Reading it may clarify the documentation below.

=cut

use strict;
use warnings;

=head1 METHODS

=over 8

=item new

Creates a new C<Algorithm::Viterbi> object. 
The following attributes can be set with the constructor:

  my $v = Algorthm::Viterbi->new(
    start_state => '$',
    unknown_emission_prob => undef,
    unknown_transition_prob => 0);

The values of the attributes in the example are the default values.
For a detailed description and use of these attributes, see below.

=cut

sub new
{
  my $class = shift; 
  my $self = {@_};
  bless $self, $class;

  $self->{unknown_transition_prob} = 0 if (!defined($self->{unknown_transition_prob}));
  $self->{start_state} = '$' if (!defined($self->{start_state}));

  return $self;
}

=item train

This method computes the start, emission and transition probabilities 
from a set of observations and their associated states.
The probabilities are simple averages of the passed observations,
so if you require sophisticated smoothing on the emission, start and/or
transition, then you're better off rolling your own.

The value of member start_state is a bogus state used to define the begin state of the first transition.
By default, this state is set to '$'. You can change this by setting the variable in the constructor
or later by accessing the member directly. See example below.

This state can also be used as a separator between the beginning and end of a sequence of observations. 
For example, you could assign this state (tag) to every end-of-sentence symbol when training on a 
pre-tagged corpus.

The set of observations is passed as a reference to an array as shown in the following example:

  use strict;
  use Algorithm::Viterbi;
  use Data::Dumper;

  my $observations = [
    [ 'work', 'rainy' ],
    [ 'work', 'sunny' ],
    [ 'walk', 'sunny' ],
    [ 'walk', 'rainy' ],
    [ 'shop', 'rainy' ],
    [ 'work', 'rainy' ],
  ];

  my $v = Algorithm::Viterbi->new(start_state => '###');
  $v->train($observations);

  print Dumper($v);

will produce:

  $VAR1 = bless( {
                 'transition' => {
                                   'sunny' => {
                                                'sunny' => '0.5',
                                                'rainy' => '0.25'
                                              },
                                   'rainy' => {
                                                'sunny' => '0.5',
                                                'rainy' => '0.5'
                                              },
                                   '###' => {
                                              'rainy' => '0.25'
                                            }
                                 },
                 'emission' => {
                                 'shop' => {
                                             'rainy' => '0.25'
                                           },
                                 'walk' => {
                                             'sunny' => '0.5',
                                             'rainy' => '0.25'
                                           },
                                 'work' => {
                                             'sunny' => '0.5',
                                             'rainy' => '0.5'
                                           }
                               },
                 'start_state' => '###',
                 'states' => [
                               'sunny',
                               'rainy'
                             ],
                 'unknown_transition_prob' => 0,
                 'start' => {
                              'sunny' => '0.333333333333333',
                              'rainy' => '0.666666666666667'
                            }
               }, 'Algorithm::Viterbi' );

=cut

sub train
{
  my ($self, $training_data) = @_;

  my $ep = {};
  my $tp = {};
  my $sp = {};

  my $pt = $self->{start_state};

  foreach my $o(@$training_data){
    my ($a, $t) = @$o;
    $ep->{$a}{$t}++;
    $tp->{$pt}{$t}++;
    $pt = $t;
    $sp->{$t}++;
  }

  #emission
  foreach my $a(keys %$ep){
    foreach my $t(keys %{$ep->{$a}}){
      $ep->{$a}{$t} /= $sp->{$t};
    }
  }  

  #transition
  foreach my $pt(keys %$tp){
    foreach my $t(keys %{$tp->{$pt}}){
      $tp->{$pt}{$t} /= $sp->{$t};
    }
  }

  #start
  foreach my $t(keys %$sp){
    $sp->{$t} /= @$training_data;
  }

  $self->start($sp);
  $self->emission($ep);
  $self->transition($tp);

  return ($sp, $ep, $tp);
}

=item start

Initializes the start probabilities. 
The start probabilities are passed as a reference to a hash, as shown in
this example:

  my $start_probability = { 'Rainy'=> 0.6, 'Sunny'=> 0.4 };
  my $v = Algorithm::Viterbi->new();
  $v->start($start_probability);

From the start probabilities, all possible states are derived, by 
copying the keys of the start hash. This list of states is used by the 
forward_viterbi method. It is therefore important to mention all 
possible states in the start hash.

Returns the start probabilities.

=cut

sub start
{
  my $self = shift;
  if (@_){
    ($self->{start}) = @_;
    @{$self->{states}} = keys %{$self->{start}};
  }
  return $self->{start};
}

=item emission

Initializes the emission probabilities. 
The emission is passed as a reference to a hash, as shown in
this example:

  my $emission_probability = {
          'shop' =>  { 'Sunny' => '0.3', 'Rainy' => '0.4' },
          'swim' =>  { 'Sunny' => '0.1' }, 
	  'walk' =>  { 'Sunny' => '0.5', 'Rainy' => '0.1' },
          'clean' => { 'Sunny' => '0.1', 'Rainy' => '0.5' }
        };
  my $v = Algorithm::Viterbi->new();
  $v->emission($emission_probability);

The keys of the emission hash constitute the dictionary, which is used to determine 
whether an observation is a known or an unknown observation.

Returns the emission probabilities.

=cut

sub emission
{
  my $self = shift;
  ($self->{emission}) = @_ if (@_);
  return $self->{emission};
}

=item transition

Initializes the transition probabilities. 
The transition is passed as a reference to a hash, as shown in
this example:

  my $transition_probability = {
   'Rainy' => {'Rainy'=> 0.7, 'Sunny'=> 0.3},
   'Sunny' => {'Rainy'=> 0.4, 'Sunny'=> 0.6},
  };
  my $v = Algorithm::Viterbi->new();
  $v->transition($transition_probability);

The transition hash can be 'sparse': it is sufficient to include only known 
transitions between states. See method get_transition.

Returns the transition probabilities.

=cut

sub transition
{
  my $self = shift;
  ($self->{transition}) = @_ if (@_);
  return $self->{transition};
}

=item forward_viterbi

This method calculates the forward probability, the Viterbi path 
and the Viterbi probability of a given sequence of observations.
For a detailed description of the Algorithm, see the Wikipedia page
L<http://en.wikipedia.org/wiki/Viterbi_algorithm>.

The difference with the algorithm described in the web page above, 
is that the emission and the transition are calculated somewhat
differently. See methods get_emission and get_transition.

Example:

  use strict;
  use Algorithm::Viterbi;
  use Data::Dumper;

    
  my $observations = [ 'walk', 'shop', 'clean' ];
   my $start = { 'Rainy'=> 0.6, 'Sunny'=> 0.4 };
   my $transition = {
      'Rainy' => {'Rainy'=> 0.7, 'Sunny'=> 0.3},
      'Sunny' => {'Rainy'=> 0.4, 'Sunny'=> 0.6},
      };

  my $emission = {
    'shop' => {
      'Sunny' => '0.3',
      'Rainy' => '0.4',
    },

    'walk' => {
      'Sunny' => '0.6',
      'Rainy' => '0.1'
    },
    'clean' => {
      'Sunny' => '0.1',
      'Rainy' => '0.5'
      }
  };

  my $v = Algorithm::Viterbi->new();
  $v->emission($emission);
  $v->transition($transition);
  $v->start($start);

  print Dumper ($v->forward_viterbi($observations));

produces:

  $VAR1 = '0.033612';
  $VAR2 = [
	    'Sunny',
	    'Rainy',
	    'Rainy',
	    'Rainy'
	  ];
  $VAR3 = '0.009408';

=cut

sub forward_viterbi
{
  my ($self, $observation) = @_;

  my $T = { };
  foreach my $state (@{$self->{states}}) {
    ##               prob.                   V. path   V. prob.
    $T->{$state} = [ $self->{start}{$state}, [$state], $self->{start}{$state} ]; 
  }

  foreach my $output (@$observation) {
    my $U = { };
    foreach my $next_state (@{$self->{states}}) {
      my $total = 0;
      my $argmax = [ ];
      my $valmax = 0;
      foreach my $state (@{$self->{states}}) {
	my ($prob, $v_path, $v_prob) = @{$T->{$state}};

	my $e = $self->get_emission($output, $state);
	my $t = $self->get_transition($state, $next_state);

	my $p = $e * $t;
	$prob *= $p;
	$v_prob *= $p;
	$total += $prob;

	if ($v_prob > $valmax) {
	  $argmax = [ @$v_path, $next_state ];
	  $valmax = $v_prob;
	}
      }
      $U->{$next_state} = [ $total, $argmax, $valmax ];
    }
    $T = $U;
  }

  ## apply sum/max to the final states
  my $total = 0;
  my $argmax = [];
  my $valmax = 0;
  foreach my $state (@{$self->{states}}) {
    my ($prob, $v_path, $v_prob) = @{$T->{$state}};
    $total += $prob;
    if ($v_prob > $valmax) {
      $argmax = $v_path;
      $valmax = $v_prob;
    }
  }
  return ($total, $argmax, $valmax);
}

=item get_emission

Usage: $v->get_emission($observation, $state);

Returns the emission probability for a given observation and state.
This method is primarily for internal usage and is called
by the forward_viterbi method.

The dictionary consists of the keys of the emission table, e.g. a list 
of known observations.

If $observation is a known observation in the dictionary and $state
exists as a state for the observation in the emission table, then return 
the probability associated with $observation and $state.

If the observation exists in the dictionary, but $state is a state not 
connected to the observation, then return 0.

If the observation does not exist in the dictionary and $v->{unknown_emission_prob}
is defined, then return $v->{unknown_emission_prob}.
Setting $v->{unknown_emission_prob} = 1 actually means that you are returning all
possible states for an unknown observation.

If the observation is unknown in the dictionary and $v->{unknown_emission_prob}
is not defined, then return the start probability of $state.

Example:

  my $emission = {
    'shop' => {
		'Sunny' => '0.3',
		'Rainy' => '0.4'
	      },
    'swim' => {
		'Sunny' => '0.1'
	      },
    'walk' => {
		'Sunny' => '0.5',
		'Rainy' => '0.1'
	      },
    'clean' => {
		 'Sunny' => '0.1',
		 'Rainy' => '0.5'
	       }
  };

  my $start = { 'Rainy'=> 0.6, 'Sunny'=> 0.4 };

  my $v = Algorithm::Viterbi->new();
  $v->emission($emission);
  $v->start($start);
  my $e;
  $e = get_emission('shop', 'Rainy'); # $e = 0.4
  $e = get_emission('swim', 'Rainy'); # $e = 0
  $e = get_emission('hack', 'Rainy'); # $e = 0.6
  $v->{unknown_emission_prob} = 1;
  $e = get_emission('hack', 'Rainy'); # $e = 1

=cut

sub get_emission
{
  my ($self, $output, $state) = @_;

  my $e = 0;
  if (defined($self->{emission}{$output})){
    if (defined($self->{emission}{$output}{$state})){
      $e = $self->{emission}{$output}{$state};
    }
    else {
      #output exists, but not for this state
      $e = 0;
    }
  }
  else {
    if (defined($self->{unknown_emission_prob})){
      $e = $self->{unknown_emission_prob};
    }
    else {
      $e = $self->{start}{$state};
    }
  }
  return $e;
}

=item get_transition

Usage: $v->get_transition($state, $next_state);

Returns the transition probability between a state and the next state.
This method is primarily for internal usage and is called
by the forward_viterbi method.

If the transition between $state and $next_state is defined, then return
the probability associated with it.

If the transition between $state and $next_state does not exist, then return
the value of $v->unknown_transition_prob, which will be 0 unless otherwise defined.
Setting this attribute to a very small value allows you to still obtain a Viterbi path, 
although no suitable transitions were found between states of a given observation.

Example:

    use Algorithm::Viterbi;

    my $observations = [ 'walk', 'shop', 'read' ];

    my $start = { 'Rainy'=> 0.5, 'Sunny'=> 0.4, 'Stormy'=> 0.1 };

    my $transition = {
       'Rainy' => {'Rainy'=> 0.7, 'Sunny'=> 0.3},
       'Sunny' => {'Rainy'=> 0.4, 'Sunny'=> 0.5, 'Stormy'=>.1},
       };

    my $emission = {
      'shop' => {
		  'Sunny' => '0.4',
		  'Rainy' => '0.9'
		},
      'read' => {
		  'Stormy' => '1'
		},
      'walk' => {
		  'Sunny' => '0.6',
		  'Rainy' => '0.1'
		},
    };

    my $v = Algorithm::Viterbi->new();
    $v->emission($emission);
    $v->transition($transition);
    $v->start($start);

    my ($prob, $v_path, $v_prob) = $v->forward_viterbi($observations); 
      # returns 0, [], 0

    $v->{unknown_transition_prob} = 1e-100;

    ($prob, $v_path, $v_prob) = $v->forward_viterbi($observations); 
      # returns 1.62e-102, ['Sunny', 'Sunny', 'Stormy', 'Stormy' ], 4.8e-103;

=cut

sub get_transition
{
  my ($self, $state, $next_state) = @_;
  
  my $t = defined($self->{transition}{$state}{$next_state}) 
    ? $self->{transition}{$state}{$next_state} 
    : $self->{unknown_transition_prob};

  return $t;
}

=head1 AUTHOR

Koen Dejonghe 	koen@fietsoverland.com
Copyright (c) 2006 Koen Dejonghe. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 VERSION

Version 0.01 (2006-Nov-07)

=cut

1;

