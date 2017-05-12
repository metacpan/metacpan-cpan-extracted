package AI::FuzzyEngine::Variable;

use 5.008009;
use version 0.77; our $VERSION = version->declare('v0.2.2');

use strict;
use warnings;
use Scalar::Util qw( blessed looks_like_number );
use List::MoreUtils;
use Carp;

use AI::FuzzyEngine::Set;

my $set_class = _class_of_set();

sub new {
    my ($class, $fuzzyEngine, @pars) = @_;
    my $self = bless {}, $class;

    # check and store the assigned fuzzyEngine
    my $fe_class = 'AI::FuzzyEngine';
    croak "fuzzyEngine is not a $fe_class"
        unless blessed $fuzzyEngine && $fuzzyEngine->isa($fe_class);
    $self->{fuzzyEngine} = $fuzzyEngine;

    # load pars, create sets etc.
    $self->_init(@pars);

    return $self;
};

sub is_internal {   shift->{is_internal} }
sub from        {   shift->{from}        };
sub to          {   shift->{to}          };
sub sets        {   shift->{sets}        };
sub set_names   { @{shift->{set_names}}  };
sub set {
    my ($self, $set_name) = @_;
    return $self->{sets}{$set_name};
};
sub fuzzyEngine { shift->{fuzzyEngine} };

sub is_valid_set {
    my ($self, $set_name) = @_;
    # Should be simplified to exists $self->{sets}{$set_name}
    return List::MoreUtils::any { $_ eq $set_name } keys %{ $self->sets };
}

sub fuzzify {
    my ($self, $val) = @_;
    croak "Fuzzification not allowed for internal variables"
        if $self->is_internal;
    for my $set (values %{ $self->sets } ) {
        $set->fuzzify( $val );
    };
    return;
}

sub defuzzify {
    my ($self)  = @_;
    croak "Defuzzification not allowed for internal variables"
        if $self->is_internal;

    my @sets    = values %{$self->sets};
    my @funs    = map { $_->memb_fun } @sets;
    my @degrees = map { $_->degree   } @sets;

    # If all degrees are real scalars a shortcut is possible
    if (_non_is_a_piddle(@degrees)) {
        my $funs    = _clipped_funs( \@funs, \@degrees);
        my $fun_agg = $set_class->max_of_funs( @$funs );
        my $c       = $set_class->centroid( $fun_agg );
        return $c;
    };

    # Need a function of my FuzzyEngine
    my $fe = $self->fuzzyEngine;
    die 'Internal: fuzzy_engine is lost' unless $fe;

    # Unify dimensions of all @degrees (at least one is a pdl)
    my @synched_degrees = $fe->_cat_array_of_piddles(@degrees)->dog;
    my @dims_to_reshape = $synched_degrees[0]->dims;

    # Make degrees flat to proceed them as lists
    my @flat_degrees    = map {$_->flat} @synched_degrees;
    my $flat_degrees    = PDL::cat( @flat_degrees );

    # Proceed degrees of @sets as synchronized lists
    my @degrees_per_el  = $flat_degrees->transpose->dog;
    my @defuzzified;
    for my $ix (reverse 0..$#degrees_per_el) {
        my $el_degrees = $degrees_per_el[$ix];
        # The next two lines cost much (75% of defuzzify)
        my $funs       = _clipped_funs( \@funs, [$el_degrees->list] );
        my $fun_agg    = $set_class->max_of_funs( @$funs );

        my $c          = $set_class->centroid( $fun_agg );
        $defuzzified[$ix] = $c;
    };

    # Build result in shape of unified membership degrees
    my $flat_defuzzified = PDL->pdl( @defuzzified );
    my $defuzzified      = $flat_defuzzified->reshape(@dims_to_reshape);
    return $defuzzified;
}

sub _clipped_funs {
    # Clip all membership functions of a variable
    # according to the respective membership degree (array of scalar)
    my ($funs, $degrees) = @_;
    my @funs    = @$funs;    # Dereferencing here saves some time
    my @degrees = @$degrees;
    my @clipped = List::MoreUtils::pairwise {
                     $set_class->clip_fun($a => $b)
                  } @funs, @degrees;
    return \@clipped;
}

sub reset {
    my ($self) = @_;
    $_->reset() for values %{$self->sets};
    return $self;
}

sub change_set {
    my ($self, $setname, $new_memb_fun) = @_;
    my $set = $self->set( $setname );

    # Some checks
    croak "Set $setname does not exist" unless defined $set;
    croak 'Variable is internal' if $self->is_internal;

    # Convert to internal representation
    my $fun = $self->_curve_to_fun( $new_memb_fun );

    # clip membership function to borders
    $set->set_x_limits( $fun, $self->from => $self->to );

    # Hand the new function over to the set
    $set->replace_memb_fun( $fun );

    # and reset the variable
    $self->reset;
    return;
}

sub _init {
    my ($self, @pars) = @_;

    croak "Too few arguments" unless @pars >= 2;

    # Test for internal variable
    my ($from, $to, @sets);
    if (looks_like_number $pars[0]) {
        # $from => $to is given
        $self->{is_internal} = '';
        ($from, $to, @sets)  = @pars;
    }
    else {
        $self->{is_internal} = 1;
        ($from, $to, @sets)  = (undef, undef, @pars);
    };

    # Store $from, $to ( undef if is_internal)
    $self->{from} = $from;
    $self->{to  } = $to;

    # Provide names of sets in correct order by attribute set_names
    my $ix = 1;
    $self->{set_names} = [ grep {$ix++ % 2} @sets ];


    # Build sets of the variable
    my %sets = @sets;
    SET_TO_BUILD:
    for my $set_name (keys %sets) {

        my $fun = [ [] => [] ]; # default membership function

        if (not $self->is_internal) {
            # Convert from set of points to [ \@x, \@y ] format
            my $curve = $sets{$set_name};
            $fun   = $self->_curve_to_fun( $curve );

            # clip membership function to borders
            $set_class->set_x_limits( $fun, $self->from => $self->to );
        };

        # create a set and store it
        my $set_class = $self->_class_of_set();
        my $set = $set_class
            ->new( fuzzyEngine => $self->fuzzyEngine,
                   variable    => $self,
                   name        => $set_name,
                   memb_fun    => $fun, # [ [] => [] ] if is_internal
              );
        $self->{sets}{$set_name} = $set;

        # build membership function if necessary
        next SET_TO_BUILD if $self->can( $set_name );
        my $method = sub {
            my ($variable, @vals) = @_; # Variable, fuzzy values
            my $set = $variable->{sets}{$set_name};
            return $set->degree( @vals );
        };

        # register the new method to $self (the fuzzy variable)
        no strict 'refs';
        *{ $set_name } = $method;
    };
}

sub _non_is_a_piddle {
    return List::MoreUtils::none {ref $_ eq 'PDL'} @_;
}

# Might change for Variables inherited from AI::FuzzyEngine::Variable:
sub _class_of_set { 'AI::FuzzyEngine::Set' }

sub _curve_to_fun {
    # Convert input format for membership functions
    # to internal representation:
    # [$x11, $y11, $x12, $y12, ... ]
    # --> [ $x11, $x12,  ... ] => [$y11, $y12, ... ] ]
    my ($class, $curve) = @_;
    my %points = @$curve;
    my @x      = sort {$a<=>$b} keys %points;
    my @y      = @points{ @x };
    return [ \@x, \@y ];
}



1;

=pod

=head1 NAME

AI::FuzzyEngine::Variable - Class used by AI::FuzzyEngine.

=head1 DESCRIPTION

Please see L<AI::FuzzyEngine> for a description.

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

