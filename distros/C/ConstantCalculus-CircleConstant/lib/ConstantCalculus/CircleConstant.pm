package ConstantCalculus::CircleConstant;

# Set the VERSION.
our $VERSION = "0.01";

# Load the Perl pragmas.
use 5.008009;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Base class of this (tron_addr) module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutine.
our @EXPORT = qw(
    pi_chudnovsky
    pi_chudnovsky_algorithm
    tau_chudnovsky
    tau_chudnovsky_algorithm
    $CONTROL_OUTPUT
);

# Exporting the multiply and divide  routine on demand basis.
@EXPORT_OK = qw(
    truncate_places
    chudnovsky_terms
    factorial
    pi
    tau
);

# Define the Perl BEGIN block.
BEGIN {
    # Set the subroutine aliases.
    *pi = \&pi_chudnovsky;
    *tau = \&tau_chudnovsky;
};

# Disable a warning.
no warnings 'recursion';

# Load the Perl module.
use bignum;;

# Set the precision for bignum.
bignum -> precision(-14);

# Set the zeros.
my $NEXT_DIGIT = int((log(151931373056000)/log(10))+1);

# Set verbose flag.
our $CONTROL_OUTPUT = 0;

# Flush output immediately to the terminal window.
local $| = 1;

#------------------------------------------------------------------------------# 
# Subroutine is_unsigned_int()                                                 #
#------------------------------------------------------------------------------# 
sub is_unsigned_int {
    # Assign the subroutine argument to the local variable.
    my $arg = (defined $_[0] ? $_[0] : '');
    # Set the Perl conform regex pattern.
    my $re = qr/^(([1-9][0-9]*)|0)$/;
    # Check the argument with the regex pattern.
    my $is_unsigned_int = (($arg =~ $re) ? 1 : 0);
    # Return 0 (false) or 1 (true).
    return $is_unsigned_int; 
};

# ---------------------------------------------------------------------------- #
# Subroutine factorial()                                                       #
# ---------------------------------------------------------------------------- #
sub factorial {
  my $n = $_[0];
  my $fac = ($n == 0 ? 1 : factorial($n-1)*$n);
  return $fac;
};

# ---------------------------------------------------------------------------- #
# Subroutine chudnovsky_terms()                                                #
# ---------------------------------------------------------------------------- #
sub chudnovsky_terms {
    # Assign the subroutine argument to the local variable.
    my $places = (defined $_[0] ? $_[0] : 0);
    # Determine the estimated number of terms.
    my $number_terms = undef;
    if ($places <= 1) {
        $number_terms = $places;
    } elsif ($places <= 14) {
        $number_terms = 1;
    } else {
        $number_terms = int($places / $NEXT_DIGIT) + 2;
        $number_terms += ($number_terms % 2 == 0 ? 1 : 0);
    };
    # Return the estimated number of terms.
    return $number_terms;
};

# ---------------------------------------------------------------------------- #
# Subroutine truncate_places()                                                 #
# ---------------------------------------------------------------------------- #
sub truncate_places {
    my $decimal = $_[0];
    my $places = $_[1];
    my $factor = 10**$places;
    $decimal = int($decimal*$factor) / ($factor);
    $decimal = substr($decimal, 0, $places+2);
    return $decimal;
};

# ---------------------------------------------------------------------------- #
# Subroutine control_output()                                                  #
# ---------------------------------------------------------------------------- #
sub control_output {
    my $places = $_[0];
    my $terms = $_[1];
    my $precision = $_[2];
    my $type = $_[3];
    my $formula = $_[4];
    printf("%s\n", "Calculation Data");
    printf("%s\n", "================");
    printf("%-10s %s\n", "Formula:", $formula);
    printf("%-10s %s\n", "Type:", $type);
    printf("%-10s %s\n", "Precision:", $precision);
    printf("%-10s %s\n", "Places:", $places);
    printf("%-10s %s\n", "Terms:", $terms);
};

# ---------------------------------------------------------------------------- #
# Subroutine pi_chudnovsky_algorithm()                                         #
# ---------------------------------------------------------------------------- #
sub pi_chudnovsky_algorithm {
    # Assign the subroutine arguments to the local variables.
    my $places = (defined $_[0] ? $_[0] : 0);
    my $n = (defined $_[1] ? $_[1] : 0);
    my $p = (defined $_[2] ? $_[2] : 0);
    # Set the precision.
    bignum -> precision(-$p);
    # Initialise the return variable.
    my $pi = 0;
    # Set the local integer constants.
    my $c0 = 545140134;
    my $c1 = 13591409;
    my $c2 = 640320;
    my $c3 = 4270934400;
    my $c4 = 10005;
    # Set the initial values.   
    my $a_k = 0;
    my $a_sum = 0;
    my $numerator = 0;
    my $denominator = 0;
    # Set the sign to 1.
    my $sign = 1;
    # Run index is of type int.
    for (my $k = 0; $k <= $n; $k++) {
        # Calculate numerator and denominator. 
        $numerator = factorial(6*$k)*($c0*$k+$c1);
        $denominator = factorial(3*$k)*(factorial($k)**3)*($c2**(3*$k));
        # Calculate the quotient.
        $a_k = $sign*($numerator/$denominator);
        # Add quotient to total sum.  
        $a_sum += $a_k;
        # Change the sign.
        $sign *= -1;
    };
    # Calculate the value of Pi.
    $pi = $c3 / (sqrt($c4)*$a_sum);
    # Return the value of Pi.
    return "$pi";
};

# ---------------------------------------------------------------------------- #
# Subroutine pi_chudnovsky()                                                   #
# ---------------------------------------------------------------------------- #
sub pi_chudnovsky {
    # Assign the subroutine arguments to the local variables.
    my $places = (defined $_[0] ? $_[0] : 0);
    # Check if places are valid numbers.
    if (is_unsigned_int($places) != 1) {
        print "The given number of places is not valid. Terminating processing. Bye!\n";
        exit;
    };
    # Calculate the number of needed terms.
    my $terms = chudnovsky_terms($places);
    # Set the precision for the calculation.
    my $precision = $places + $NEXT_DIGIT;
    # Print control output to the terminal window.
    if ($CONTROL_OUTPUT == 1) {
        my $formula = "Chudnovsky (Pi)";
        my $type = "decimal";
        control_output($places, $terms, $precision, $type, $formula);
    };
    # Get value of Pi from calculation.
    my $pi = pi_chudnovsky_algorithm($places, $terms, $precision);
    # Cut the decimal number to the needed places.
    $pi = truncate_places($pi, $places);
    # Return the value of pi.
    return "$pi";
};

# ---------------------------------------------------------------------------- #
# Subroutine tau_chudnovsky_algorithm()                                        #
# ---------------------------------------------------------------------------- #
sub tau_chudnovsky_algorithm {
    # Assign the subroutine arguments to the local variables.
    my $places = (defined $_[0] ? $_[0] : 0);
    my $n = (defined $_[1] ? $_[1] : 0);
    my $p = (defined $_[2] ? $_[2] : 0);
    # Set the precision.
    bignum -> precision(-$p);
    # Initialise the return variable.
    my $tau = 0;
    # Set the local integer constants.
    my $c0 = 545140134;
    my $c1 = 13591409;
    my $c2 = 640320;
    my $c3 = 4270934400;
    my $c4 = 10005;
    # Set the initial values.   
    my $a_k = 0;
    my $a_sum = 0;
    my $numerator = 0;
    my $denominator = 0;
    # Set the sign to 1.
    my $sign = 1;
    # Run index is of type int.
    for (my $k = 0; $k <= $n; $k++) {
        # Calculate numerator and denominator. 
        $numerator = factorial(6*$k)*($c0*$k+$c1);
        $denominator = factorial(3*$k)*(factorial($k)**3)*($c2**(3*$k));
        # Calculate the quotient.
        $a_k = $sign*($numerator/$denominator);
        # Add quotient to total sum.  
        $a_sum += $a_k;
        # Change the sign.
        $sign *= -1;
    };
    # Calculate the value of Tau.
    $tau = (2*$c3) / (sqrt($c4)*$a_sum);
    # Return the value of Tau.
    return "$tau";
};

# ---------------------------------------------------------------------------- #
# Subroutine tau_chudnovsky()                                                  #
# ---------------------------------------------------------------------------- #
sub tau_chudnovsky {
    # Assign the subroutine arguments to the local variables.
    my $places = (defined $_[0] ? $_[0] : 0);
    # Check if places are valid numbers.
    if (is_unsigned_int($places) != 1) {
        print "The given number of places is not valid. Terminating processing. Bye!\n";
        exit;
    };
    # Calculate the number of needed terms.
    my $terms = chudnovsky_terms($places);
    # Set the precision for the calculation.
    my $precision = $places + $NEXT_DIGIT;
    # Print control output to the terminal window.
    if ($CONTROL_OUTPUT == 1) {
        my $formula = "Chudnovsky (Tau)";
        my $type = "decimal";
        control_output($places, $terms, $precision, $type, $formula);
    };
    # Get value of Pi from calculation.
    my $tau = tau_chudnovsky_algorithm($places, $terms, $precision);
    # Cut the decimal number to the needed places.
    $tau = truncate_places($tau, $places);
    # Return the value of pi.
    return "$tau";
};

1;
__END__
# Below is the documentation for this module. 

=encoding utf8

=head1 NAME

ConstantCalculus::CircleConstant - Perl extension for the calculation of circle constants.

=head1 SYNOPSIS

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Set the global control output variable to 0 or 1.
  [$CONTROL_OUTPUT = 0|1];

  # Call the calculation method for Pi.
  my $pi = pi_chudnovsky($places);

  # Call the calculation algorithm for Pi directly.
  my $pi = pi_chudnovsky($PLACES[, $TERMS, $PRECISION]);

  # Call the calculation method for Tau.
  my $tau = tau_chudnovsky($places);

  # Call the calculation algorithm for Tau directly.
  my $tau = tau_chudnovsky($PLACES[, $TERMS, $PRECISION]);

=head1 DESCRIPTION

The circle constant is a mathematical constant. There are two variants of the
circle constant. Most common is the use of Pi (π) for the circle constant. More
uncommon is the use of Tau (τ) for the circle constant. The relation between 
them is τ = 2 π. There can be found other denotations for the well known name
Pi. The names are Archimedes's constant or Ludolph's constant. The circle constant
is used in formulas across mathematics and physics.

The circle constant is the ratio of the circumference U of a circle to its
diameter d, which is π = U/d or τ = 2 U/d. It is an irrational number, which
means that it cannot be expressed exactly as a ratio of two integers. Fractions
such as 22/7 or 355/113 can be used to approximate the circle constant Pi, whereas
44/7 or 710/113 represent the approximation of the circle constant Tau. In
consequence of this, the decimal representation of a circle constant never ends in
there decimal places having a infinite number of places, nor enters a permanently
repeating pattern in the decimal places. The circle constant is also a not algebraic
transcendental number.

Over the centuries scientists developed formulas for approximating the circle
constant Pi. Chudnovsky's formula is one of them. A algorithm based on Chudnovsky's
formula can be used to calculate an approximation for Pi and also for Tau. The
advantage of the Chudnovsky formula is the good convergence. In contradiction 
the convergence of the Leibniz formula is quit bad.      

The challenge in providing an algorithm for the circle constant is that all decimal
places must be correct in terms of the formula. Based on the desired decimal place
number or precision, the number of places must be correct. The provided algorithm 
takes care of this. At the moment the result of the implemented algorithm was checkt
against the known decimal places of Pi up to 10000 places.

=head1 IMPLEMENTATION

To be able to deal with large numbers pre decimal point and after the decimal point
as needed, the Perl module C<bignum> is used. The main subroutine argument is the 
number of places, which should be calculated for the circle constant.        

If terms and precision is not given, both are estimated from the given number of
places. This will result in a value of Pi, which is accurate to the requested 
places. If places, terms and/or precision is given, the behaviour of the algorithm
can be studied with respect to terms and/or precision.  

The number of iterations is calculated using the knowledge, that each iteration
should result in 14 new digits after the decimal point. So the value for the 
calculation of the number of terms is set to 14. To make sure that reverse as less
as possible digits are changed, the number of terms to calculated is uneven. So the
sign of the term to add is negative after the decimal point.

To prevent rounding errors in the last digit, the precision is a factor of 14 higher
than the requested number of places. The correct number of places is realised by truncating
the calculated and possibly rounded value of Pi to the requested number of places.      

=head1 EXAMPLES

=head2 Pi

=head3 Example 1

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate Pi.
  $pi = pi_chudnovsky($places);
  print $pi . "\n";

=head3 Example 2

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 100;  

  # Set the number of terms.
  my $terms = 50;  

  # Set the precision.
  my $precision = 115;  

  # Calculate Pi.
  $pi = pi_chudnovsky($places, $terms, $precision);
  print $pi . "\n";

=head3 Example 3

Load the Alias C<pi> of the method C<pi_chudnovsky> and set the flag for the 
control output to 1. Default is 0.  

  # Load the Perl module and import the method pi.
  use ConstantCalculus::CircleConstant qw(pi);

  # Set the control output flag.
  $CONTROL_OUTPUT = 1;

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 64;  

  # Calculate Pi.
  $pi = pi($places);
  print $pi . "\n";

=head2 Tau

=head3 Example 1

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Tau.
  my $tau = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate Tau.
  $tau = tau_chudnovsky($places);
  print $tau . "\n";

=head3 Example 2

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Tau.
  my $tau = undef;

  # Set the number of places.
  my $places = 100;  

  # Set the number of terms.
  my $terms = 50;  

  # Set the precision.
  my $precision = 115;  

  # Calculate Tau.
  $tau = tau_chudnovsky($places, $terms, $precision);
  print $tau . "\n";

=head3 Example 3

Load the Alias C<tau> of the method C<tau_chudnovsky> and set the flag for the 
control output to 1. Default is 0.  

  # Load the Perl module and import the method pi.
  use ConstantCalculus::CircleConstant qw(tau);

  # Set the control output flag.
  $CONTROL_OUTPUT = 1;

  # Declare the variable for Pi.
  my $tau = undef;

  # Set the number of places.
  my $places = 64;  

  # Calculate Tau.
  $tau = tau($places);
  print $tau . "\n";

=head1 MODULE METHODS

=head2 Main Methods

   pi_chudnovsky()   

   pi_chudnovsky_algorithm()

   tau_chudnovsky()   

   tau_chudnovsky_algorithm()

=head2 Other Methods

    truncate_places()

    chudnovsky_terms()

    factorial()

    pi() (Alias)

    tau() (Alias)

=head1 MODULE EXPORT

    pi_chudnovsky_algorithm

    pi_chudnovsky   

    truncate_places

    chudnovsky_terms

    factorial

    pi (Alias)

    tau (Alias)

=head1 LIMITATIONS

Limitations are not known at the moment.

=head1 BUGS

Bugs are not known yet.

=head1 NOTES

The implemented chudnovsky algorithm is used in a representation where the
well known terms are optimised for calculation. 

=head1 OPEN ISSUE

Further calculations with higher precision are outstanding to check the accuracy of
the correctness of the last digits of the calculated circle constant.

It has to be checked, if the Perl module bignum can be used for the calculation of the
required really large numbers after the decimal point.

It has also be checked, if there can be possibly a accuracy problem in using the needed
square root algorithm C<sqrt()> provided by Perl. 

=head1 SEE ALSO

L<CPAN bignum|https://metacpan.org/dist/bignum>

L<Perldoc bignum|https://perldoc.perl.org/bignum>

Circle Constant Pi

Circle Constant Tau

Leibniz formula

Chudnovsky formula

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify it
under the same terms of The MIT License. For more details, see the full
text of the license in the attached file LICENSE in the main module folder.
This program is distributed in the hope that it will be useful, but without
any warranty; without even the implied warranty of merchantability or fitness
for a particular purpose.

=cut
