package Algorithm::GoldenSection;

use warnings;
use strict;
use Carp;
use Readonly;

use version; our $VERSION = qv('0.0.2');

=head1 NAME

Algorithm::GoldenSection - Golden Section Search Algorithm for one-dimensional minimisation.

=cut
=head1 VERSION

This document describes Algorithm::GoldenSection version 0.0.2

=cut
=head1 DESCRIPTION

This module is an implementation of the Golden Section Search Algorithm for finding minima of a unimodal function. 
In order to isolate a minimum of a univariate functions the minimum must first be isolated. 
Consequently the program first bounds a minimum - i.e. the program initially creates a triplet of points: 
x_low < x_int < x_high, such that f(x_int) is lower than both f(x_low) and f(x_high). Thus we ensure that there 
is a local minimum within the interval: x_low-x_high. The program then uses the Golde Section Search algorithm 
to successively narrow down on the bounded region to find the minimum. 
See http://en.wikipedia.org/wiki/Golden_section_search and
http://www.gnu.org/software/gsl/manual/html_node/One-dimensional-Minimization.html.

The module provides a Perl5OO interface. Simply construct a Algorithm::GoldenSection object with appropriate parameters
- see L</SYNOPSIS>. Then call the minimise C<method>. This returns a LIST of the value of x at the minimum, the value of
f(x) at the minimum and the number of iterations used to isolate the minimum.

=cut
=head1 SYNOPSIS

    use Algorithm::GoldenSection;
    
    # Create a Algorithm::GoldenSection object and pass it a CODE reference to the function to be minimised and initials values for x_low and x_int.
    $gs = Algorithm::GoldenSection->new( { function => sub { my $x = shift; my $b =  $x * sin($x) - 2 * cos($x); return $b },
                                        x_low    => 4,
                                        x_int    => 4.7,} ) ;
    
    # Call minimisation method to bracket and minimise.
    my ($x_min, $f_min, $iterations) = $gs->minimise;

    print qq{\nMinimisation results: x a minimum = $x_min, function value at minimum = $f_min. Calculation took $iterations iterations};

=cut

# package-scoped lexicals
Readonly::Scalar my $ouro => 1.618034 ;
Readonly::Scalar my $glimite => 100.0 ;
Readonly::Scalar my $pequeninho => 1.0e-20 ;
Readonly::Scalar my $tolerancia => 3.0e-8;  # tolerance
Readonly::Scalar my $C => (3-sqrt(5))/2;
Readonly::Scalar my $R => 1-$C;

#/ I had leaving things for operator precedence. you won´t see A+B*(C-D) whe you mean: A+( B*(C-D) ) - i.e. * binds more tightly that +

sub new {
    my ( $class, $h_ref ) = @_;
    croak qq{\nArguments must be passed as HASH reference.} if ( ( $h_ref ) && ( ref $h_ref ne q{HASH} ) );
    my $self = {};
    bless $self, $class;
    $self->_check_options($h_ref);
    return $self;
}

sub _check_options {

    my ( $self, $h_ref ) = @_;

    croak qq{\nOption \x27function\x27 is obrigatory and accepts a CODE reference} 
      if ( ( !exists $h_ref->{function} ) || ( ref $h_ref->{function} ne q{CODE} ) );
    croak qq{\nOption \x27x_low\x27 requirements a numeric value} 
      if ( ( !exists $h_ref->{x_low} ) || ( $h_ref->{x_low} !~ /\A[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\z/xms ) );
    croak qq{\nOption \x27x_low\x27 requirements a numeric value} 
      if ( ( !exists $h_ref->{x_int} ) || ( $h_ref->{x_int} !~ /\A[+-]?\ *(\d+(\.\d*)?|\.\d+)([eE][+-]?\d+)?\z/xms ) );

    $self->{function} = $h_ref->{function};
    $self->{x_low} = $h_ref->{x_low};
    $self->{x_int} = $h_ref->{x_int};

}

sub _switch {
    # twat did you usual of forgetting @_ and then you didn´t even return from it!
    my ( $a, $b, $f_a, $f_b) = @_; 
    my $buf = $a;
    my $f_buf = $f_a;
    $a = $b;
    $f_a = $f_b;
    $b = $buf;
    $f_b = $f_buf;
    return ($a, $b, $f_a, $f_b); 
}

sub minimise {

    my $self = shift;
    
    #y bracket interval
    $self->_bracket;

    my $func = $self->{function};
    my $a = $self->{x_low};
    my $b = $self->{x_int};
    my $c = $self->{x_high};

    my $x1;
    my $x2;
    # this is not efficient code...
    my $x0 = $self->{x_low};
    my $x3 = $self->{x_high};

    if ( abs($c-$b) > abs($b-$a) ) {
        $x1 = $b;
        #y create new point to try
        $x2 = $b + ( $C * ($c-$b) );
    }
    else {
        $x2 = $b;
        #y create new point to try
        $x1 = $b - ( $C * ($b-$a) );
    }
    
    #y initial function evaluations
    my $f1 = $func->($x1);
    my $f2 = $func->($x2);

    my $counter = 0;

    #y start iterating...
    while ( abs($x3-$x0) > ( $tolerancia * ( abs($x1) + abs($x2) ) ) ) {

        #y lets increment here just to make it easier - hence start with 0
        $counter++;

        #y a possible outcome
        if ( $f2 < $f1 ) {

            #########################################
            #y choose one of the two - but why the fuck-up with $R multiplication?!?
            #########################################
            #y the following is identical to:
            $x0 = $x1;
            $x1 = $x2;
            $x2 = ($R*$x2) + ($C*$x3); #
            $f1 = $f2;
            $f2 = $func->($x2);
            #########################################
#            my $x_temp = ($R*$x2) + ($C*$x3);
#            &_shft3(\$x0,\$x1,\$x2,\$x_temp);
#            my $f_x_temp = $func->($x2);
#            &_shft2(\$f1,\$f2,\$f_x_temp);
            #########################################
        }
        #y other possibility
        else {

            #########################################
            $x3 = $x2;
            $x2 = $x1;
            $x1 = ($R*$x1) + ($C*$x0);
            $f2 = $f1;
            $f1 = $func->($x1);
            #########################################
#            my $x_temp = ($R*$x1) + ($C*$x0);
#            &_shft3(\$x3,\$x2,\$x1,\$x_temp);
#            my $f_x_temp = $func->($x1);
#            &_shft2(\$f2,\$f1,\$f_x_temp);
            #########################################
        }
    }

    my $xmin;
    my $fmin;
    
    #y set final values
    if ($f1 < $f2) { 
        $xmin = $x1;
        $fmin = $f1;
    }
    else {
        $xmin = $x2;
        $fmin = $f2;
    }

    return $xmin, $fmin, $counter;
}

sub _bracket {
    
    my $self = shift;
    
    my $function = $self->{function};
    $a = $self->{x_low};
    $b = $self->{x_int};
    
    my $f_u;
    my $f_a = $function->($a);
    my $f_b = $function->($b);

    #y that is downhill
    if ($f_b > $f_a ) { 
        #print qq{\n\n**** in this case fb is higher than fa - thus we are going uphill so we need to swap them****\n};
        print qq{\n\nswitch $a, $b, $f_a and $f_b};
        ( $a, $b, $f_a, $f_b) = _switch( $a, $b, $f_a, $f_b); 
        print qq{\n\nswitch $a, $b, $f_a and $f_b};
    }

    # has higher precedence that + thus: $c = $b+$ouro*($b-$a);  is the same as $c = $b+($gold*($b-$a)); - same in C/C++

    #y WE MAKE A GUESS AT A VALUE OF C
    my $c = $b + ( $ouro * ($b-$a) ); # c 26.18034 and f_c 21.6787847478271

    my $f_c = $function->($c);

    # (1) by SWAPPING we are sure that f(a) > f(b)! - (2) BUT we must also have f(b) < f(c) in order to have _bracketed our MINIMUM

    while ( $f_b > $f_c ) {
    
        #y compute u by parabolic extrapolation - tiny is there just to stop ilegal divisions by 0
        my $r = ($b-$a) * ($f_b-$f_c);
        my $q = ($b-$c) * ($f_b-$f_a);
        my $u = $b - ( ( $b - $c ) * $q - ( $b - $a ) * $r )  / ( 2.0 * &_sign ( &_max ( abs ($q-$r), $pequeninho ), $q-$r ) );
        my $ulim = $b + ( $glimite * ($c-$b) );

        #y test the possibilities!

        if ( ($b-$u)*($u-$c) > 0.0 ) {      #y parabolic u is between b and c 
            $f_u = $function->($u);
            
            #y have a minimium between b and c - i.e. is f(u) < f(c) - if so:
            if ( $f_u  < $f_c ) { 

                $a = $b;
                $b = $u;
                $f_a = $f_b;
                $f_b = $f_u;

                #/ we´re going to return early here so as we aren´t using any package-scoped vars we will need to feed the object here
                $self->{x_low} = $a;
                $self->{x_int} = $b;
                $self->{x_high} = $c;
                
                return
            }
            elsif ( $f_u > $f_b ) {
                $c = $u;
                $f_c = $f_u;
                
                #/ we´re going to return early here so as we aren´t using any package-scoped vars we will need to feed the object here
                $self->{x_low} = $a;
                $self->{x_int} = $b;
                $self->{x_high} = $c;
                
                return
            }

            #y parabolic fit was useless in this case - so we use a default magnification
            $u = $c + ( $ouro * ($c-$b) );
            $f_u = $function->($u);
        }

        #y parabolic fit is between c and is not allowed
        elsif  ( ($c-$u)*($u-$ulim) > 0 ) {

            $f_u = $function->($u);

            if ( $f_u < $f_c ) {

                my $u_other = $u + ( $ouro * ($u-$c) );
                #/ this should make b = c, c = u  and u = u_other
                &_shft3(\$b,\$c,\$u,$u_other); 
                #/ so as u is now u_other this shouldn´t be a prob
                my $f_u_other = $function->($u_other);
                &_shft3(\$f_b,\$f_c,\$f_u, \$f_u_other); 
            }
        }

        #y limit parabolic u to max allowed
        elsif ( ($u-$ulim)*($ulim-$c) >= 0.0 ) {
            $u = $ulim;
            $f_u = $function->($u);
        }

        #y reject parabolic u
        else { 
            $u = $c + ( $ouro * ($c-$b) );
            $f_u = $function->($u);
        }

        #y eliminate oldest points and will continue};

        &_shft3(\$a,\$b,\$c,\$u); 
        &_shft3(\$f_a,\$f_b,\$f_c,\$f_u); 
       
    }

    croak qq{\nThere is a problem - email dsth\@cantab.net.} if ( !$a || !$b || !$c );#|| ( $b > $a ) || ( $b > $c ) ); 
    $self->{x_low} = $a;
    $self->{x_int} = $b;
    $self->{x_high} = $c;
}

sub _sign {
    my ($a, $b) = @_;
    my $val = abs $a;
    my $sig = $b >= 0 ? q{+} : q{-};
    my $final = $sig.$val;
    # force numeric context - no real reason
    return 0+$final;
}

sub _max {
    my ($a, $b) = @_;
    my $ret = $a >= $b ? $a : $b;
    return $ret;
}

sub _shft3 {
    my ($a, $b, $c, $d) = @_;
    $$a = $$b;
    $$b = $$c;
    $$c = $$d;
    return;
}

sub _shft2 {
    my ($a, $b, $c) = @_;
    $$a = $$b;
    $$b = $$c;
    return;
}

1; # Magic true value required at end of module

__END__

=head1 DEPENDENCIES

Carp                => "1.08",
Readonly            => "1.03",

=cut
=head1 AUTHOR

Daniel S. T. Hughes  C<< <dsth@cantab.net> >>

=cut
=head1 SEE ALSO

L<Math::Amoeba>.

=cut
=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010, Daniel S. T. Hughes C<< <dsth@cantab.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify and/or
redistribute the software as permitted by the above licence, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
