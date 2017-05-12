package AI::FuzzyEngine::Set;

use 5.008009;
use version 0.77; our $VERSION = version->declare('v0.2.2');

use strict;
use warnings;
use Carp;
use Scalar::Util qw(blessed weaken);
use List::MoreUtils;

sub new {
    my ($class, @pars) = @_;
    my $self = bless {}, $class;

    $self->_init(@pars);

    return $self;
}

sub name        { shift->{name}        }
sub variable    { shift->{variable}    }
sub fuzzyEngine { shift->{fuzzyEngine} }
sub memb_fun    { shift->{memb_fun}    }

sub degree {
    my ($self, @vals) = @_;

    if (@vals) {
        # Multiple input degrees are conjuncted: 
        my $and_degree  = $self->fuzzyEngine->and( @vals );

        # Result counts against (up to now) best hit
        my $last_degree = $self->{degree};
        $self->{degree} = $self->fuzzyEngine->or( $last_degree, $and_degree );
    };

    return $self->{degree};
}

# internal helpers, return @x and @y from the membership functions
sub _x_of ($) { return @{shift->[0]} };
sub _y_of ($) { return @{shift->[1]} };

sub _init {
    my ($self, %pars) = @_;
    my %defaults = ( name        => '',
                     value       => 0,
                     memb_fun    => [[]=>[]], # \@x => \@y
                     variable    => undef,
                     fuzzyEngine => undef,
                   );

    my %attrs = ( %defaults, %pars );

    my $class = 'AI::FuzzyEngine';
    croak "fuzzyEngine is not a $class"
        unless blessed $attrs{fuzzyEngine} && $attrs{fuzzyEngine}->isa($class);

    $class = 'AI::FuzzyEngine::Variable';
    croak "variable is not a $class"
        unless blessed $attrs{variable} && $attrs{variable}->isa($class);

    croak 'Membership function is not an array ref'
        unless ref $attrs{memb_fun} eq 'ARRAY';

    $self->{$_}       = $attrs{$_} for qw( variable fuzzyEngine name memb_fun);
    weaken $self->{$_}             for qw( variable fuzzyEngine );

    $self->{degree} = 0;

    my @x = _x_of $self->memb_fun;
    croak 'No double interpolation points allowed'
        if List::MoreUtils::uniq( @x ) < @x;

    $self;
}

sub _copy_fun {
    my ($class, $fun) = @_;
    my @x = @{$fun->[0]}; #    my @x = _x_of $fun;, improve speed
    my @y = @{$fun->[1]};
    return [ \@x => \@y ];
}

sub _interpol {
    my ($class, $fun, $val_x) = @_;

    my @x = @{$fun->[0]}; # speed
    my @y = @{$fun->[1]};

    if (not ref $val_x eq 'PDL') {

        return $y[ 0] if $val_x <= $x[ 0];
        return $y[-1] if $val_x >= $x[-1];

        # find block
        my $ix = 0;
        $ix++ while $val_x > $x[$ix] && $ix < $#x;
        # firstidx takes longer (156ms vs. 125ms with 50_000 calls)
        # my $ix = List::MoreUtils::firstidx { $val_x <= $_ } @x;

        # interpolate
        my $fract  = ($val_x - $x[$ix-1]) / ($x[$ix] - $x[$ix-1]);
        my $val_y  = $y[$ix-1]  +  $fract * ($y[$ix] - $y[$ix-1]);

        return $val_y;
    };

    my ($val_y) = $val_x->interpolate( PDL->pdl(@x), PDL->pdl(@y) );
    return $val_y;
}

# Some functions are not marked private (using leading '_')
# but should be used by AI::FuzzyEngine::Variable only:

sub set_x_limits {
    my ($class, $fun, $from, $to) = @_;

    my @x = _x_of $fun;
    my @y = _y_of $fun;

    return $fun unless @x;

    if (@x == 1) {
        # Explicitly deal with this case to allow recursive removing of points
        $fun->[0] = [$from => $to];
        $fun->[1] = [ @y[0, 0] ];
        return $fun;
    }

    if    ($x[0] > $from) {
        unshift @x, $from;
        unshift @y, $y[0];
    }
    elsif ($x[0] < $from) {

        # Check for @x > 1 allows to use $x[1]
        if ($x[1] <= $from) {
            # Recursive call with removed left border
            shift @{$fun->[0]};
            shift @{$fun->[1]};
            $class->set_x_limits( $fun, $from => $to );

            # update @x and @y for further calculation
            @x = _x_of $fun;
            @y = _y_of $fun;
        }
        else {
            $x[0] = $from;
            $y[0] = $class->_interpol( $fun => $from );
        };

    };

    if    ($x[-1] < $to) {
        push @x, $to;
        push @y, $y[-1];
    }
    elsif ($x[-1] > $to) {

        # Check for @x > 1 allows to use $x[-2]
        if ($x[-2] >= $to) {
            # Recursive call with removed right border
            pop @{$fun->[0]};
            pop @{$fun->[1]};
            $class->set_x_limits( $fun, $from => $to );

            # update @x and @y for further calculation
            @x = _x_of $fun;
            @y = _y_of $fun;
        }
        else {
            $x[-1] = $to;
            $y[-1] = $class->_interpol( $fun => $to );
        };

    };

    $fun->[0] = \@x;
    $fun->[1] = \@y;
    return $fun;
}

sub synchronize_funs {
    my ($class, $funA, $funB) = @_;
    # change $funA, $funB directly, use their references
    # \@x and \@y as part of $fun will be replaced nevertheless

    my @xA = _x_of $funA;
    my @yA = _y_of $funA;
    my @xB = _x_of $funB;
    my @yB = _y_of $funB;

    croak '$funA is empty' unless @xA;
    croak '$funB is empty' unless @xB;

    # Find and add missing points
    my (%yA_of, %yB_of);
    @yA_of{@xA} = @yA;
    @yB_of{@xB} = @yB;

    my (%xA, %xB);
    @xA{@xA} = 1;
    @xB{@xB} = 1;

    MISSING_IN_A:
    for my $x (@xB) {
        next MISSING_IN_A if exists $xA{$x};
        $yA_of{$x} = $class->_interpol( $funA => $x );
    };

    MISSING_IN_B:
    for my $x (@xA) {
        next MISSING_IN_B if exists $xB{$x};
        $yB_of{$x} = $class->_interpol( $funB => $x );
    };

    # Sort them and put them back to the references of $funA and $funB
    # (Sort is necessary even if no crossings exist)
    my @x = sort {$a<=>$b} keys %yA_of;
    @yA = @yA_of{@x};
    @yB = @yB_of{@x};

    # Assign to fun references (needed within CHECK_CROSSING)
    $funA->[0] = \@x;
    $funA->[1] = \@yA;
    $funB->[0] = \@x;
    $funB->[1] = \@yB;

    # Any crossing between interpolation points
    my $found;
    CHECK_CROSSING:
    for my $ix (1..$#xA) {
        my $dy1 = $yB[$ix-1] - $yA[$ix-1];
        my $dy2 = $yB[$ix]   - $yA[$ix];
        next CHECK_CROSSING if $dy1 * $dy2 >= 0;

        $found++;
        my $dx  = $xA[$ix] - $xA[$ix-1];
        my $x   = $xA[$ix-1] + $dx * $dy1 / ($dy1-$dy2);
        my $y   = $class->_interpol( $funA => $x );
        $yA_of{$x} = $y;
        $yB_of{$x} = $y;
    };

    if ($found) {
        # Rest of procedure is known (and necessary)
        @x = sort {$a<=>$b} keys %yA_of;
        @yA = @yA_of{@x};
        @yB = @yB_of{@x};

        $funA->[0] = \@x;
        $funA->[1] = \@yA;
        $funB->[0] = \@x;
        $funB->[1] = \@yB;
    };

    return;
};

sub _max_of {
    my ($factor, $ar, $br) = @_;
    my @y;
    for my $ix ( reverse 0..$#$ar ) {
        my $max = $ar->[$ix] * $factor > $br->[$ix] * $factor ?
                                         $ar->[$ix] : $br->[$ix]; 
        $y[$ix] = $max;
    };
    return @y;
}

sub _minmax_of_pair_of_funs {
    my ($class, $factor, $funA, $funB) = @_;
    # $factor > 0: 'max' operation
    # $factor < 0: 'min' operation

    # synchronize interpolation points (original functions are changed)
    $class->synchronize_funs( $funA, $funB );

    my @x  = _x_of $funA;
    my @yA = _y_of $funA;
    my @yB = _y_of $funB;
    # my @y  = List::MoreUtils::pairwise { $a*$factor > $b*$factor ?
    #                                      $a : $b
    #                                    } @yA, @yB;

    my @y = _max_of( $factor, \@yA, \@yB ); # faster than pairwise

    return [ \@x, \@y ];
}

sub _minmax_of_funs {
    my ($class, $factor, $funA, @moreFuns) = @_;
    return $funA unless @moreFuns;

    my $funB = shift @moreFuns;
    my $fun  = $class->_minmax_of_pair_of_funs( $factor, $funA, $funB );

    # solve recursively
    return $class->_minmax_of_funs( $factor, $fun, @moreFuns );
}

sub min_of_funs {
    my ($class, @funs) = @_;
    # Copy can not moved to _minmax_of_funs (is recursively called)
    my @copied_funs = map { $class->_copy_fun($_) } @funs;
    return $class->_minmax_of_funs( -1, @copied_funs );
}

sub max_of_funs {
    my ($class, @funs) = @_;
    # Copy can not moved to _minmax_of_funs (is recursively called)
    my @copied_funs = map { $class->_copy_fun($_) } @funs;
    return $class->_minmax_of_funs( 1, @copied_funs );
}

sub clip_fun {
    my ($class, $fun, $max_y) = @_;

    # clip by min operation on function $fun
    my @x         = _x_of $fun;
    my @y         = ( $max_y ) x @x;
    my $fun_limit = [ \@x => \@y ];
    return $class->min_of_funs( $fun, $fun_limit );
}

sub centroid {
    my ($class, $fun) = @_;

    # x and y values, check
    my @x = _x_of $fun;
    my @y = _y_of $fun;
    croak "At least two points needed" if @x < 2;

    # using code fragments from Ala Qumsieh (AI::FuzzyInference::Set)

    # Left 
    my $x0 = shift @x;
    my $y0 = shift @y;

    my (@areas, $x1, $y1);

    AREA:
    while (@x) {
        # Right egde of area
        $x1 = shift @x;
        $y1 = shift @y;

        # Each area is build of a rectangle and a top placed triangle
        # Each of them might have a height of zero

        # Area and local centroid of base rectangle
        my $a1 = abs(($x1 - $x0) * ($y0 < $y1 ? $y0 : $y1));
   	my $c1 = $x0 + 0.5 * ($x1 - $x0);

        # Area and local centroid of triangle on top of rectangle
        my $a2 = abs(0.5 * ($x1 - $x0) * ($y1 - $y0));
        my $c2 = (1/3) * ($x0 + $x1 + ($y1 > $y0 ? $x1 : $x0));

        # Total area of block
        my $ta = $a1 + $a2;
   	next AREA if $ta == 0;

        # Total centroid of block
        my $c = ( $c1*$a1 + $c2*$a2 ) / $ta;

        # Store them for final calculation of average
        push @areas, [$c, $ta];
    }
    continue {
        # Left edge of next area
        ($x0, $y0) = ($x1, $y1);
    };

    # Sum of area
    my $ta = 0;
    $ta += $_->[1] for @areas;

    croak "Function has no height --> no centroid" unless $ta;

    # Final Centroid in x direction
    my $c = 0;
    $c += $_->[0] * $_->[1] for @areas;
    return $c / $ta;
}

sub fuzzify {
    my ($self, $val) = @_;

    my $fun = $self->memb_fun;
    croak "No valid membership function"
        unless @{$fun->[0]}; # at least one x

    return $self->{degree} = $self->_interpol( $fun => $val );
}

sub reset {
    my ($self) = @_;
    $self->{degree} = 0;
    $self;
}

# Replace a membership function
# To be called by variable->change_set( 'setname' => $new_fun );
sub replace_memb_fun {
    my ($self, $new_fun) = @_;
    $self->{memb_fun} = $new_fun;
    return;
}

1;

=pod

=head1 NAME

AI::FuzzyEngine::Set - Class used by AI::FuzzyEngine. 

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
