package AI::FuzzyEngine;

use 5.008009;
use version 0.77; our $VERSION = version->declare('v0.2.2');

use strict;
use warnings;
use Carp;
use Scalar::Util;
use List::Util;
use List::MoreUtils;

use AI::FuzzyEngine::Variable;

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;

    $self->{_variables} = [];
    return $self;
}

sub variables { @{ shift->{_variables} } };

sub and {
    my ($self, @vals) = @_;

    # PDL awareness: any element is a piddle?
    return List::Util::min(@vals) if _non_is_a_piddle(@vals);

    _check_for_PDL();
    my $vals = $self->_cat_array_of_piddles(@vals);
    return $vals->mv(-1, 0)->minimum;
}

sub or {
    my ($self, @vals) = @_;

    # PDL awareness: any element is a piddle?
    return List::Util::max(@vals) if _non_is_a_piddle(@vals);

    _check_for_PDL();
    my $vals = $self->_cat_array_of_piddles(@vals);
    return $vals->mv(-1, 0)->maximum;
}

sub not {
    my ($self, $val) = @_;
    return 1-$val;
}

sub true  { return 1 }

sub false { return 0 }

sub new_variable {
    my ($self, @pars) = @_;

    my $variable_class = $self->_class_of_variable();
    my $var = $variable_class->new($self, @pars);
    push @{$self->{_variables}}, $var;
    Scalar::Util::weaken $self->{_variables}->[-1];
    return $var;
}

sub reset {
    my ($self) = @_;
    $_->reset() for $self->variables(); 
    return $self;
}

sub _class_of_variable { 'AI::FuzzyEngine::Variable' }

sub _non_is_a_piddle {
    return List::MoreUtils::none {ref $_ eq 'PDL'} @_;
}

my $_PDL_is_imported;
sub _check_for_PDL {
    return if $_PDL_is_imported;
    die "PDL not loaded"       unless $INC{'PDL.pm'};
    die "PDL::Core not loaded" unless $INC{'PDL/Core.pm'};
    $_PDL_is_imported = 1;
}

sub _cat_array_of_piddles {
    my ($class, @vals)  = @_;

    # TODO: Rapid return if @_ == 1 (isa piddle)
    # TODO: join "-", ndims -> Schnellcheck auf gleiche Dim.

    # All elements must get piddles
    my @pdls  = map { PDL::Core::topdl($_) } @vals;

    # Get size of wrapping piddle (using a trick)
    # applying valid expansion rules for element wise operations
    my $zeros = PDL->pdl(0);
    #        v-- does not work due to threading mechanisms :-((
    # $zeros += $_ for @pdls;
    # Avoid threading!
    for my $p (@pdls) {
        croak "Empty piddles are not allowed" if $p->isempty();
        eval { $zeros = $zeros + $p->zeros(); 1
            } or croak q{Can't expand piddles to same size};
    }

    # Now, cat 'em by expanding them on the fly
    my $vals = PDL::cat( map {$_ + $zeros} @pdls );
    return $vals;
};

1;

=pod

=head1 NAME

AI::FuzzyEngine - A Fuzzy Engine, PDL aware

=head1 SYNOPSIS

=head2 Regular Perl - without PDL

    use AI::FuzzyEngine;

    # Engine (or factory) provides fuzzy logical arithmetic
    my $fe = AI::FuzzyEngine->new();

    # Disjunction:
    my $a = $fe->or ( 0.2, 0.5, 0.8, 0.7 ); # 0.8
    # Conjunction:
    my $b = $fe->and( 0.2, 0.5, 0.8, 0.7 ); # 0.2
    # Negation:
    my $c = $fe->not( 0.4 );                # 0.6
    # Always true:
    my $t = $fe->true();                    # 1.0
    # Always false:
    my $f = $fe->false();                   # 0.0

    # These functions are constitutive for the operations
    # on the fuzzy sets of the fuzzy variables:

    # VARIABLES (AI::FuzzyEngine::Variable)

    # input variables need definition of membership functions of their sets
    my $flow = $fe->new_variable( 0 => 2000,
                        small => [0, 1,  500, 1, 1000, 0                  ],
                        med   => [       400, 0, 1000, 1, 1500, 0         ],
                        huge  => [               1000, 0, 1500, 1, 2000, 1],
                   );
    my $cap  = $fe->new_variable( 0 => 1800,
                        avg   => [0, 1, 1500, 1, 1700, 0         ],
                        high  => [      1500, 0, 1700, 1, 1800, 1],
                   );
    # internal variables need sets, but no membership functions
    my $saturation = $fe->new_variable( # from => to may be ommitted
                        low   => [],
                        crit  => [],
                        over  => [],
                   );
    # But output variables need membership functions for their sets:
    my $green = $fe->new_variable( -5 => 5,
                        decrease => [-5, 1, -2, 1, 0, 0            ],
                        ok       => [       -2, 0  0, 1, 2, 0      ],
                        increase => [              0, 0, 2, 1, 5, 1],
                   );

    # Reset FuzzyEngine (resets all variables)
    $fe->reset();

    # Reset a fuzzy variable directly
    $flow->reset;

    # Membership functions can be changed via the set's variable.
    # This might be useful during parameter identification algorithms
    # Changing a function resets the respective variable.
    $flow->change_set( med => [500, 0, 1000, 1, 1500, 0] );

    # Fuzzification of input variables
    $flow->fuzzify( 600 );
    $cap->fuzzify( 1000 );

    # Membership degrees of the respective sets are now available:
    my $flow_is_small = $flow->small(); # 0.8
    my $flow_is_med   = $flow->med();   # 0.2
    my $flow_is_huge  = $flow->huge();  # 0.0

    # RULES and their application

    # a) If necessary, calculate some internal variables first. 
    # They will not be defuzzified (in fact, $saturation can't)
    # Implicit application of 'and'
    # Multiple calls to a membership function
    # are similar to 'or' operations:
    $saturation->low( $flow->small(), $cap->avg()  );
    $saturation->low( $flow->small(), $cap->high() );
    $saturation->low( $flow->med(),   $cap->high() );

    # Explicite 'or', 'and' or 'not' possible:
    $saturation->crit( $fe->or( $fe->and( $flow->med(),  $cap->avg()  ),
                                $fe->and( $flow->huge(), $cap->high() ),
                       ),
                 );
    $saturation->over( $fe->not( $flow->small() ),
                       $fe->not( $flow->med()   ),
                       $flow->huge(),
                       $cap->high(),
                 );
    $saturation->over( $flow->huge(), $fe->not( $cap->high() ) );

    # b) deduce output variable(s) (here: from internal variable $saturation)
    $green->decrease( $saturation->low()  );
    $green->ok(       $saturation->crit() );
    $green->increase( $saturation->over() );

    # All sets provide their respective membership degrees: 
    my $saturation_is_over = $saturation->over(); # This is no defuzzification!
    my $green_is_ok        = $green->ok();

    # Defuzzification ( is a matter of the fuzzy variable )
    my $delta_green = $green->defuzzify(); # -5 ... 5

=head2 Using PDL and its threading capability

    use PDL;
    use AI::FuzzyEngine;

    # (Probably a stupide example)
    my $fe        = AI::FuzzyEngine->new();

    # Declare variables as usual
    my $severity  = $fe->new_variable( 0 => 10,
                          low  => [0, 1, 3, 1, 5, 0       ],
                          high => [      3, 0, 5, 1, 10, 1],
                        );

    my $threshold = $fe->new_variable( 0 => 1,
                           low  => [0, 1, 0.2, 1, 0.8, 0,     ],
                           high => [      0.2, 0, 0.8, 1, 1, 1],
                         );
    
    my $problem   = $fe->new_variable( -0.5 => 2,
                           no  => [-0.5, 0, 0, 1, 0.5, 0, 1, 0],
                           yes => [         0, 0, 0.5, 1, 1, 1, 1.5, 1, 2, 0],
                         );

    # Input data is a pdl of arbitrary dimension
    my $data = pdl( [0, 4, 6, 10] );
    $severity->fuzzify( $data );

    # Membership degrees are piddles now:
    print 'Severity is high: ', $severity->high, "\n";
    # [0 0.5 1 1]

    # Other variables might be piddles of other dimensions,
    # but all variables must be expandible to a common 'wrapping' piddle
    # ( in this case a 4x2 matrix with 4 colums and 2 rows)
    my $level = pdl( [0.6],
                     [0.2],
                   );
    $threshold->fuzzify( $level );

    print 'Threshold is low: ', $threshold->low(), "\n";
    # [
    #  [0.33333333]
    #  [         1]
    # ]

    # Apply some rules
    $problem->yes( $severity->high,  $threshold->low );
    $problem->no( $fe->not( $problem->yes )  );

    # Fuzzy results are represented by the membership degrees of sets 
    print 'Problem yes: ', $problem->yes,  "\n";
    # [
    #  [         0 0.33333333 0.33333333 0.33333333]
    #  [         0        0.5          1          1]
    # ]

    # Defuzzify the output variables
    # Caveat: This includes some non-threadable operations up to now
    my $problem_ratings = $problem->defuzzify();
    print 'Problems rated: ', $problem_ratings;
    # [
    #  [         0 0.60952381 0.60952381 0.60952381]
    #  [         0       0.75          1          1]
    # ]

=head1 EXPORT

Nothing is exported or exportable.

=head1 DESCRIPTION

This module is yet another implementation of a fuzzy inference system.
The aim was to  be able to code rules (no string parsing),
but avoid operator overloading,
and make it possible to split calculation into multiple steps.
All intermediate results (memberships of sets of variables)
should be available.

Beginning with v0.2.0 it is PDL aware,
meaning that it can handle piddles (PDL objects)
when running the fuzzy operations.
More information on PDL can be found at L<http://pdl.perl.org/>. 

Credits to Ala Qumsieh and his L<AI::FuzzyInference>,
that showed me that fuzzy is no magic.
I learned a lot by analyzing his code,
and he provides good information and links to learn more about Fuzzy Logics.

=head2 Fuzzy stuff

The L<AI::FuzzyEngine> object defines and provides
the elementary operations for fuzzy sets.
All membership degrees of sets are values from 0 to 1.
Up to now there is no choice with regard to how to operate on sets:

=over 2

=item C<< $fe->or( ... ) >> (Disjunction)

is I<Maximum> of membership degrees

=item C<< $fe->and( ... ) >> (Conjunction)

is I<Minimum> of membership degrees

=item C<< $fe->not( $var->$set ) >> (Negation)

is I<1-degree> of membership degree

=item Aggregation of rules (Disjunction)

is I<Maximum>

=item True C<< $fe->true() >> and false C<< $fe->false() >>

are provided for convenience.

=back

Defuzzification is based on

=over 2

=item Implication

I<Clip> membership function of a set according to membership degree,
before the implicated memberships of all sets of a variable are taken for defuzzification:

=item Defuzzification

I<Centroid> of aggregated (and clipped) membership functions

=back

=head2 Public functions

Creation of an C<AI::FuzzyEngine> object by

    my $fe = AI::FuzzyEngine->new();

This function has no parameters. It provides the fuzzy methods
C<or>, C<and> and C<not>, as listed above.
If needed, I will introduce alternative fuzzy operations,
they will be configured as arguments to C<new>. 

Once built, the engine can create fuzzy variables by C<new_variable>:

    my $var = $fe->new_variable( $from => $to,
                        $name_of_set1 => [$x11, $y11, $x12, $y12, ... ],
                        $name_of_set2 => [$x21, $y21, $x22, $y22, ... ],
                        ...
                   );

Result is an L<AI::FuzzyEngine::Variable>.
The name_of_set strings are taken to assign corresponding methods
for the respective fuzzy variables.
They must be valid function identifiers.
Same name_of_set can used for different variables without conflict.
Take care:
There is no check for conflicts with predefined class methods. 

Fuzzy variables provide a method to fuzzify input values:

    $var->fuzzify( $val );

according to the defined sets and their membership functions.

The memberships of the sets of C<$var> are accessible
by the respective functions:

    my $membership_degree = $var->$name_of_set();

Membership degrees can be assigned directly (within rules for example):

    $var->$name_of_set( $membership_degree );

If multiple membership_degrees are given, they are "anded":

    $var->$name_of_set( $degree1, $degree2, ... ); # "and"

By this, simple rules can be coded directly:

    my $var_3->zzz( $var_1->xxx, $var_2->yyy, ... ); # "and"

this implements the fuzzy implication

    if $var_1->xxx and $var_2->yyy and ... then $var_3->zzz

The membership degrees of a variable's sets can be reset to undef:

    $var->reset(); # resets a variable
    $fe->reset();  # resets all variables

The fuzzy engine C<$fe> has all variables registered
that have been created by its C<new_variable> method.

A variable can be defuzzified:

    my $out_value = $var->defuzzify();

Membership functions can be replaced via a set's variable:

    $var->change_set( $name_of_set => [$x11n, $y11n, $x12n, $y12n, ... ] );

The variable will be reset when replacing a membership function
of any of its sets.
Interdependencies with other variables are not checked
(it might happen that the results of any rules are no longer valid,
so it needs some recalculations).

Sometimes internal variables are used that need neither fuzzification
nor defuzzification.
They can be created by a simplified call to C<new_variable>:

    my $var_int = $fe->new_variable( $name_of_set1 => [],
                                     $name_of_set2 => [],
                                     ...
                       );

Hence, they can not use the methods C<fuzzify> or C<defuzzify>.

Fuzzy operations are simple operations on floating values between 0 and 1:

    my $conjunction = $fe->and( $var1->xxx, $var2->yyy, ... );
    my $disjunction = $fe->or(  $var1->xxx, $var2->yyy, ... );
    my $negated     = $fe->not( $var1->zzz );

There is no magic.

A sequence of rules for the same set can be implemented as follows: 

    $var_3->zzz( $var_1->xxx, $var_2->yyy, ... );
    $var_3->zzz( $var_4->aaa, $var_5->bbb, ... );

The subsequent application of C<< $var_3->zzz(...) >>
corresponds to "or" operations (aggregation of rules).

Only a reset can reset C<$var_3>. 

=head2 PDL awareness

Membership degrees of sets might be either scalars or piddles now.

    $var_a->memb_fun_a(        5  ); # degree of memb_fun_a is a scalar
    $var_a->memb_fun_b( pdl(7, 8) ); # degree of memb_fun_b is a piddle

Empty piddles are not allowed, behaviour with bad values is not tested.

Fuzzification (hence calculating degrees) accepts piddles:

    $var_b->fuzzify( pdl([1, 2], [3, 4]) );

Defuzzification returns a piddle if any of the membership
degrees of the function's sets is a piddle:

    my $val = $var_a->defuzzify(); # $var_a returns a 1dim piddle with two elements

So do the fuzzy operations as provided by the fuzzy engine C<$fe> itself.

Any operation on more then one piddle expands those to common
dimensions, if possible, or throws a PDL error otherwise. 

The way expansion is done is best explained by code
(see C<< AI::FuzzyEngine->_cat_array_of_piddles(@pdls) >>).
Assuming all piddles are in C<@pdls>,
calculation goes as follows:

    # Get the common dimensions
    my $zeros = PDL->pdl(0);
    # Note: $zeros += $_->zeros() for @pdls does not work here
    $zeros = $zeros + $_->zeros() for @pdls;

    # Expand all piddles
    @pdls = map {$_ + $zeros} @pdls;

Defuzzification uses some heavy non-threading code,
so there might be a performance penalty for big piddles. 

=head2 Todos

=over 2

=item Add optional alternative implementations of fuzzy operations

=item More checks on input arguments and allowed method calls

=item PDL awareness: Use threading in C<< $variable->defuzzify >>

=item Divide tests into API tests and test of internal functions

=back

=head1 CAVEATS / BUGS

This is my first module.
I'm happy about feedback that helps me to learn
and improve my contributions to the Perl ecosystem.

Please report any bugs or feature requests to
C<bug-ai-fuzzyengine at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-FuzzyEngine>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::FuzzyEngine

=head1 AUTHOR

Juergen Mueck, jmueck@cpan.org

=head1 COPYRIGHT

Copyright (c) Juergen Mueck 2013.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
