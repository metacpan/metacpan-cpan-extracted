
# A module to implement a fuzzy inference system.
#
# Copyright Ala Qumsieh (aqumsieh@cpan.org) 2002.
# This program is distributed under the same terms as Perl itself.

package AI::FuzzyInference;
use strict;

use vars qw/$VERSION/;
$VERSION = 0.05;

use AI::FuzzyInference::Set;

############################################
#
# First some global vars.
#
############################################

# this hash defines the possible interpretations of the
# standard fuzzy logic operations.
my %_operations = (
		   '&' => {
		       min     => sub { (sort {$a <=> $b} @_)[0] },
		       product => sub { my $p = 1; $p *= $_ for @_; $p },
		       default => 'min',
		   },
		   '|'  => {
		       max     => sub { (sort {$a <=> $b} @_)[-1] },
		       sum     => sub { my $s = 0; $s += $_ for @_; $s > 1 ? 1 : $s },
		       default => 'max',
		   },
		   '!' => {
		       complement => sub { 1 - $_[0] },
		       custom  => sub {},
		       default    => 'complement',
		   },
		   );

# this hash defines the currently implemented implication methods.
my %_implication     = qw(
			  clip    1
			  scale   1
			  default clip
			  );

# this hash defines the currently implemented aggregation methods.
my %_aggregation     = qw(
			  max     1
			  default max
			  );

# this hash defines the currently implemented defuzzification methods.
my %_defuzzification = qw(
			  centroid 1
			  default  centroid
			  );

# sub new() - constructor.
# 
# doesn't take any arguments. Returns an initialized AI::FuzzyInference object.

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;

    my $obj = bless {} => $class;

    $obj->_init;

    return $obj;
}

# sub _init() - private method.
#
# no arguments. Initializes the data structures we will need.
# It also defines the default logic operations we might need.

sub _init {
    my $self = shift;

    $self->{SET}     = new AI::FuzzyInference::Set;
    $self->{INVARS}  = {};
    $self->{OUTVARS} = {};
    $self->{RULES}   = [];
    $self->{RESULTS} = {};

    $self->{IMPLICATION}     = $_implication{default};
    $self->{AGGREGATION}     = $_aggregation{default};
    $self->{DEFUZZIFICATION} = $_defuzzification{default};

    for my $op (qw/& | !/) {
	$self->{OPERATIONS}{$op} = $_operations{$op}{default};
    }
}

# sub implication() - public method.
#
# one optional argument: has to match one of the keys of the %_implication hash.
# used to query/set the implication method.

sub implication {
    my ($self,
	$new,
	) = @_;

    if (defined $new and exists $_implication{$new}) {
	$self->{IMPLICATION} = $new;
    }

    return $self->{IMPLICATION};
}

# sub aggregation() - public method.
#
# one optional argument: has to match one of the keys of the %_aggregation hash.
# used to query/set the aggregation method.

sub aggregation {
    my ($self,
	$new,
	) = @_;

    if (defined $new and exists $_aggregation{$new}) {
	$self->{AGGREGATION} = $new;
    }

    return $self->{AGGREGATION};
}

# sub defuzzification() - public method.
#
# one optional argument: has to match one of the keys of the %_defuzzification hash.
# used to query/set the defuzzification method.

sub defuzzification {
    my ($self,
	$new,
	) = @_;

    if (defined $new and exists $_defuzzification{$new}) {
	$self->{DEFUZZIFICATION} = $new;
    }

    return $self->{DEFUZZIFICATION};
}

# sub operation() - public method.
#
# two arguments: first one mandatory and specifies the logic operation
# in question. Second one is optional and has to match one of the keys
# of the %{$_operations{$first_arg}} hash.
# Used to query/set the logic operations method.

sub operation {
    my ($self,
	$op,
	$new,
	) = @_;

    return unless defined $op && exists $_operations{$op};

    if (defined $new and exists $_operations{$op}{$new}) {
	$self->{OPERATIONS}{$op} = $new;
    }

    return $self->{OPERATIONS}{$op};
}

# sub inVar() - public method.
#
# 4 arguments or more : First is a name of a new input variable.
# Second and third are the min and max values of that variable.
# These define the universe of discourse for that variable.
# Additional argumets constitute a hash. The keys of the hash
# are term set names defined for the given variable. The values
# are the coordinates of the vertices of the term sets.
#
# ex. $obj->inVar('height',
#                 5, 8,   # xmin, xmax (in feet, say)
#                 'tall' => [0, 0,
#                            5, 1,
#                            10,0],
#                  ....);

sub inVar {
    my ($self,
	$var,
	$xmin,
	$xmax,
	@sets,
	) = @_;

    $self->{INVARS}{$var} = [$xmin, $xmax];

    while (@sets) {
	my $s = shift @sets;
	my $c = shift @sets;

	$self->{SET}->add("$var:$s", $xmin, $xmax, @$c);
    }
}

# sub outVar() - public method.
#
# 4 arguments or more : First is a name of a new output variable.
# Second and third are the min and max values of that variable.
# These define the universe of discourse for that variable.
# Additional argumets constitute a hash. The keys of the hash
# are term set names defined for the given variable. The values
# are the coordinates of the vertices of the term sets.

sub outVar {
    my ($self,
	$var,
	$xmin,
	$xmax,
	@sets,
	) = @_;

    $self->{OUTVARS}{$var} = [$xmin, $xmax];

    while (@sets) {
	my $s = shift @sets;
	my $c = shift @sets;

	$self->{SET}->add("$var:$s", $xmin, $xmax, @$c);
    }
}

# sub addRule() - public method.
#
# Adds fuzzy if-then inference rules.
#
# $obj->addRule('x=medium'         => 'z = slow',
#               'x=low  & y=small' => 'z = fast',
#               'x=high & y=tiny'  => 'z=veryfast');
# spaces are optional. The characters [&=|] are special.

sub addRule {
    my ($self, %rules) = @_;

    for my $k (keys %rules) {
	my $v = $rules{$k};
	s/\s+//g for $v, $k;

	push @{$self->{RULES}} => [$k, $v];
    }

    return 1;
}

# sub show() - public method.
#
# This method displays the computed values of all
# output variables.
# It is ugly, and will be removed. Here for debugging.

sub show {
    my $self = shift;

    for my $var (keys %{$self->{RESULTS}}) {
	print "Var $var = $self->{RESULTS}{$var}.\n";
    }
}

# sub value() - public method.
#
# one argument: the name of an output variable.
# This method returns the computed value of a given output var.

sub value {
    my ($self,
	$var,
	) = @_;

    return undef unless exists $self->{RESULTS}{$var};
    return $self->{RESULTS}{$var};
}

# sub reset() - public method
# 
# cleans the data structures used.

sub reset {
    my $self = shift;

    my @list   =  $self->{SET}->listMatching(q|:implicated$|);
    push @list => $self->{SET}->listMatching(q|:aggregated$|);

    $self->{SET}->delete($_) for @list;

    $self->{RESULTS} = {};
}

# sub compute() - public method
#
# This method takes as input crisp values for each
# of the input vars, and produces a crisp output value
# based on the application of the fuzzy if-then rules.
# ex.
# $z = $obj->compute(x => 5,
#                    y => 24);

sub compute {
    my ($self,
	%vars,
	) = @_;

    $self->reset();

    # First thing we do is to fuzzify the inputs.
    $self->_fuzzify(%vars);

    # Now, apply the rules to see which ones fire.
    $self->_infer;

    # implicate
    $self->_implicate;

    # aggregate
    $self->_aggregate;

    # defuzzify .. final step.
    $self->_defuzzify;

    return 1;
}

# sub _defuzzify() - private method.
#
# no arguments. This method applies the defuzzification technique
# to get a crisp value out of the aggregated set of each output
# var.

sub _defuzzify {
    my $self = shift;

    my $_defuzzification = $self->{DEFUZZIFICATION};

    # iterate through all output vars.
    for my $var (keys %{$self->{OUTVARS}}) {

	my $result = 0;
	if ($self->{SET}->exists("$var:aggregated")) {
	    $result = $self->{SET}->$_defuzzification("$var:aggregated");
	}

	$self->{RESULTS}{$var} = $result;
    }
}

# sub _aggregate() - private method.
#
# no arguments. This method applies the aggregation technique to get
# one fuzzy set out of the implicated sets of each output var.

sub _aggregate {
    my $self = shift;

    my $_aggregation = $self->{AGGREGATION};

    # iterate through all output vars.
    for my $var (keys %{$self->{OUTVARS}}) {

	# get implicated sets.
	my @list = $self->{SET}->listMatching("\Q$var\E:.*:implicated\$");

	next unless @list;

	my $i = 0;
	my $current = shift @list;

	# aggregate everything together.
	while (@list) {
	    my $new  = shift @list;
	    my $name = "temp" . $i++;

	    my @c = $self->{SET}->$_aggregation($current, $new);
	    $self->{SET}->add($name, @{$self->{OUTVARS}{$var}}, @c);
	    $current = $name;
	}

	# rename the final aggregated set.
	my @c = $self->{SET}->coords($current);
	$self->{SET}->add("$var:aggregated", @{$self->{OUTVARS}{$var}}, @c);

	# delete the temporary sets.
	for my $j (0 .. $i - 1) {
	    $self->{SET}->delete("temp$j");
	}
    }
}

# sub _implicate() - private method.
#
# no arguments. This method applies the implication technique
# to all the fired rules to find a support value for each
# output variable.

sub _implicate {
  my $self = shift;

  my $_implication = $self->{IMPLICATION};

  my %ind;

  for my $ref (@{$self->{FIRED}}) {
    my ($i, $val) = @$ref;
    my ($var, $ts) = split /=/, $self->{RULES}[$i][1];

    if ($val > 0) {
      $ind{$var}{$ts}++;
      my @c = $self->{SET}->$_implication("$var:$ts", $val);
      my @u = @{$self->{OUTVARS}{$var}}; # the universe
      $self->{SET}->add("$var:$ts:$ind{$var}{$ts}:implicated", @u, @c);
    }
  }
}

# sub _fuzzify() - private method.
#
# one argument: a hash. The keys are input variables. The
# values are the crisp values of the input variables (same arguments
# as compute()). It finds the degree of membership of each input
# variable in each of its term sets.

sub _fuzzify {
    my ($self, %vars) = @_;

    my %terms;

    for my $var (keys %vars) {
	my $val = $vars{$var};

	for my $ts ($self->{SET}->listMatching("\Q$var\E")) {
	    my $deg = $self->{SET}->membership($ts, $val);

	    $terms{$var}{$ts} = $deg;
	}
    }

    $self->{FUZZIFY} = \%terms;
}

# sub _infer() - private method.
#
# no arguments. This method applies the logic operations to combine
# multiple parts of the antecedent of a rule to get one crisp value 
# that is the degree of support of that rule.
# Rules with positive support "fire".

sub _infer {
    my $self = shift;

    my @fired; # keep list of fired rules.

    for my $i (0 .. $#{$self->{RULES}}) {
	my $r = $self->{RULES}[$i][0];   # precedent

	my $val = 0;
	while ($r =~ /([&|]?)([^&|]+)/g) {
	    my ($op, $ant) = ($1, $2);
	    my ($var, $ts) = split /=/ => $ant;

	    $ts = "$var:$ts";

	    if ($op) {
		#$val = $self->{LOGIC}{$op}{SUB}->($val, $self->{FUZZIFY}{$var}{$ts});
		$val = $_operations{$op}{$self->{OPERATIONS}{$op}}->($val, $self->{FUZZIFY}{$var}{$ts});
	    } else {
		$val = $self->{FUZZIFY}{$var}{$ts};
	    }
	}

	# We only care about positive values.
	push @fired => [$i, $val];
    }

    $self->{FIRED} = \@fired;
}

__END__

=pod

=head1 NAME

AI::FuzzyInference - A module to implement a Fuzzy Inference System.

=head1 SYNOPSYS

    use AI::FuzzyInference;

    my $s = new AI::FuzzyInference;

    $s->inVar('service', 0, 10,
	  poor      => [0, 0,
			2, 1,
			4, 0],
	  good      => [2, 0,
			4, 1,
			6, 0],
	  excellent => [4, 0,
			6, 1,
			8, 0],
	  amazing   => [6, 0,
			8, 1,
			10, 0],
	  );

    $s->inVar('food', 0, 10,
	  poor      => [0, 0,
			2, 1,
			4, 0],
	  good      => [2, 0,
			4, 1,
			6, 0],
	  excellent => [4, 0,
			6, 1,
			8, 0],
	  amazing   => [6, 0,
			8, 1,
			10, 0],
	  );

    $s->outVar('tip', 5, 30,
	   poor      => [5, 0,
			 10, 1,
			 15, 0],
	   good      => [10, 0,
			 15, 1,
			 20, 0],
	   excellent => [15, 0,
			 20, 1,
			 25, 0],
	   amazing   => [20, 0,
			 25, 1,
			 30, 0],
	   );

    $s->addRule(
	    'service=poor      & food=poor'      => 'tip=poor',
	    'service=good      & food=poor'      => 'tip=poor',
	    'service=excellent & food=poor'      => 'tip=good',
	    'service=amazing   & food=poor'      => 'tip=good',

	    'service=poor      & food=good'      => 'tip=poor',
	    'service=good      & food=good'      => 'tip=good',
	    'service=excellent & food=good'      => 'tip=good',
	    'service=amazing   & food=good'      => 'tip=excellent',

	    'service=poor      & food=excellent' => 'tip=good',
	    'service=good      & food=excellent' => 'tip=excellent',
	    'service=excellent & food=excellent' => 'tip=excellent',
	    'service=amazing   & food=excellent' => 'tip=amazing',

	    'service=poor      & food=amazing'   => 'tip=good',
	    'service=good      & food=amazing'   => 'tip=excellent',
	    'service=excellent & food=amazing'   => 'tip=amazing',
	    'service=amazing   & food=amazing'   => 'tip=amazing',

	    );

    $s->compute(service => 2,
	    food    => 7);

=head1 DESCRIPTION

This module implements a fuzzy inference system. Very briefly, an FIS
is a system defined by a set of input and output variables, and a set
of fuzzy rules relating the input variables to the output variables.
Given crisp values for the input variables, the FIS uses the fuzzy rules
to compute a crisp value for each of the output variables.

The operation of an FIS is split into 4 distinct parts: I<fuzzification>,
I<inference>, I<aggregation> and I<defuzzification>.

=head2 Fuzzification

In this step, the crisp values of the input variables are used to
compute a degree of membership of each of the input variables in each
of its term sets. This produces a set of fuzzy sets.

=head2 Inference

In this step, all the defined rules are examined. Each rule has two parts:
the I<precedent> and the I<consequent>. The degree of support for each
rule is computed by applying fuzzy operators (I<and>, I<or>) to combine
all parts of its precendent, and generate a single crisp value. This value
indicates the "strength of firing" of the rule, and is used to reshape
(I<implicate>) the consequent part of the rule, generating modified
fuzzy sets.

=head2 Aggregation

Here, all implicated fuzzy sets of the fired rules are combined using
fuzzy operators to generate a single fuzzy set for each of the
output variables.

=head2 Defuzzification

Finally, a defuzzification operator is applied to the aggregated fuzzy
set to generate a single crisp value for each of the output variables.

For a more detailed explanation of fuzzy inference, you can check out
the tutorial by Jerry Mendel at
S<http://sipi.usc.edu/~mendel/publications/FLS_Engr_Tutorial_Errata.pdf>.

Note: The terminology used in this module might differ from that used
in the above tutorial.

=head1 PUBLIC METHODS

The module has the following public methods:

=over 4

=item new()

This is the constructor. It takes no arguments, and returns an
initialized AI::FuzzyInference object.

=item operation()

This method is used to set/query the fuzzy operations. It takes at least
one argument, and at most 2. The first argument specifies the logic
operation in question, and can be either C<&> for logical I<AND>,
C<|> for logical I<OR>, or C<!> for logical I<NOT>. The second
argument is used to set what method to use for the given operator.
The following values are possible:

=item &

=over 8

=item min

The result of C<A and B> is C<min(A, B)>. This is the default.

=item product

The result of C<A and B> is C<A * B>.

=back

=item |

=over 8

=item max

The result of C<A or B> is C<max(A, B)>. This is the default.

=item sum

The result of C<A or B> is C<min(A + B, 1)>.

=back

=item !

=over 8

=item complement

The result of C<not A> is C<1 - A>. This is the default.

=back

The method returns the name of the method to be used for the given
operation.

=item implication()

This method is used to set/query the implication method used to alter
the shape of the implicated output fuzzy sets. It takes one optional
argument which specifies the name of the implication method used.
This can be one of the following:

=over 8

=item clip

This causes the output fuzzy set to be clipped at its support value.
This is the default.

=item scale

This scales the output fuzzy set by multiplying it by its support value.

=back

=item aggregation()

This method is used to set/query the aggregation method used to combine
the output fuzzy sets. It takes one optional
argument which specifies the name of the aggregation method used.
This can be one of the following:

=over 8

=item max

The fuzzy sets are combined by taking at each point the maximum value of
all the fuzzy sets at that point.
This is the default.

=back

=item defuzzification()

This method is used to set/query the defuzzification method used to
extract a single crisp value from the aggregated fuzzy set.
It takes one optional
argument which specifies the name of the defuzzification method used.
This can be one of the following:

=over 8

=item centroid

The centroid (aka I<center of mass> and I<center of gravity>) of the
aggregated fuzzy set is computed and returned.
This is the default.

=back

=item inVar()

This method defines an input variable, along with its universe of
discourse, and its term sets. Here's an example:

      $obj->inVar('height',
                  5, 8,   # xmin, xmax (in feet, say)
                  'tall' => [5,   0,
                             5.5, 1,
                             6,   0],
                  'medium' => [5.5, 0,
                             6.5, 1,
                             7, 0],
                  'short' => [6.5, 0,
                             7, 1]
		  );

This example defines an input variable called I<height>. The minimum
possible value for height is 5, and the maximum is 8. It also defines
3 term sets associated with height: I<tall>, I<medium> and I<short>.
The shape of each of these triangular term sets is completely
specified by the supplied anonymous array of indices.

=item outVar()

This method defines an output variable, along with its universe of
discourse, and its term sets. The arguments are identical to those for
the C<inVar()> method.

=item addRule()

This method is used to add the fuzzy rules. Its arguments are hash-value
pairs; the keys are the precedents and the values are the consequents.
Each antecedent has to be a combination of 1 or more strings. The
strings have to be separated by C<&> or C<|> indicating the fuzzy
I<AND> and I<OR> operations respectively. Each consequent must be a
single string. Each string has the form: C<var = term_set>. Spaces
are completely optional. Example:

    $obj->addRule('height=short & weight=big' => 'diet = necessary',
		  'height=tall & weight=tiny' => 'diet = are_you_kidding_me');

The first rule basically says I<If the height is short, and the weight is
big, then diet is necessary>.

=item compute()

This method takes as input a set of hash-value pairs; the keys are names
of input variables, and the values are the values of the variables. It
runs those values through the FIS, generating corresponding values for
the output variables. It always returns a true value. To get the actual
values of the output variables, look at the C<value()> method below.
Example:

    $obj->compute(x => 5,
		  y => 24);

Note that any subsequent call to C<compute()> will implicitly clear out
the old computed values before recomputing the new ones. This is done
through a call to the C<reset()> method below.

=item value()

This method returns the value of the supplied output variable. It only
works for output variables (defined using the C<outVar()> method),
and only returns useful results after a call to C<compute()> has been
made.

=item reset()

This method resets all the data structures used to compute crisp values
of the output variables. It is implicitly called by the C<compute()>
method above.

=back

=head1 INSTALLATION

It's all in pure Perl. Just place it somewhere and point your @INC to it.

But, if you insist, here's the traditional way:

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install


=head1 AUTHOR

Copyright 2002, Ala Qumsieh. All rights reserved.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: aqumsieh@cpan.org

