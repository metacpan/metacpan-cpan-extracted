package ConstantCalculus::CircleConstant;

# Set the VERSION.
our $VERSION = "0.03";

# Load the Perl pragmas.
use 5.008009;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Base class of this module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutine.
our @EXPORT = qw(
    chudnovsky_algorithm
    borwein25_algorithm
    pi_borwein25
    tau_borwein25
    pi_chudnovsky
    tau_chudnovsky
    bbp_algorithm
    bbp_digits
    bbp_digit
    S
    $PI_DEC
    $PI_HEX
);

# Exporting subroutines on demand basis.
@EXPORT_OK = qw(
    factorial
    sqrtroot
    modexp
    estimate_terms
    truncate_places
);

# Disable a warning.
no warnings 'recursion';

# Load the Perl module.
use bignum;

# Set the precision for bignum.
bignum -> precision(-14);

# Initialise pre-defined values of Pi.
our $PI_DEC = undef;
our $PI_HEX = undef;

# Initialise the array with the hexadecimal numbers.
our @HX = ("0", "1", "2", "3", "4", "5", "6", "7",
           "8", "9", "A", "B", "C", "D", "E", "F");

# ---------------------------------------------------------------------------- #
# Subroutine modexp()                                                          #
#                                                                              #
# Description:                                                                 #
# The subroutine returns the result of a modular exponentiation. A modular     #
# exponentiation is an exponentiation applied over a modulus. The result of    #
# the modular exponentiation is the remainder when an integer b (the base)     #
# is exponentiated by e (the exponent) and divided by a positive integer m     #
# (modulus).                                                                   # 
#                                                                              #
# @params   $b  Value of the base                                              #
#           $e  Value of the exponent                                          # 
#           $m  Value of the modulus                                           #
# @returns  $y  Result of the modular exponentiation                           #
# ---------------------------------------------------------------------------- #
sub modexp {
    # Assign the subroutine arguments to the local variables.
    my($b, $e, $m) = @_;
    # Initialise the return variable.
    my $y = 1;
    # Perfom the modular exponentiation. 
    do {
        ($y *= $b) %= $m if ($e % 2);
        ($b *= $b) %= $m;
    } while ($e = ($e/2) - (($e/2) % 1));
    # Return the result of the modular exponentiation.
    return $y;
};

# ---------------------------------------------------------------------------- #
# Subroutine sqrtroot()                                                        #
#                                                                              #
# Description:                                                                 #
# The subroutine calculates the square root of given number.                   #
#                                                                              #
# @params   $x  Number for which the square root is sought                     #
# @returns  $y  Square root of the given number $x                             #
# ---------------------------------------------------------------------------- #
sub sqrtroot {
    # Assign the subroutine argument to the local variable.
    my $x = $_[0];
    # Set the start values for the iteration.
    my $y = 1;
    my $y0 = 0;
    # Initialise the loop variables.
    my $i = 0;
    my $run = 1; 
    # Run an infinite loop until the exit conditions is reached.
    while ($run == 1) {
        # Calculate the approximation.
        $y -= ($y * $y - $x) / (2 * $y);
        # Check the exit condition.
        $run = ($y0 == $y ? 0 : 1);
        # Save the approximation.
        $y0 = $y;
        # Increment the running variable.
        $i++; 
    };
    # Return the square root.
    return $y;
};

# ---------------------------------------------------------------------------- #
# Subroutine factorial()                                                       #
#                                                                              #
# Description:                                                                 #
# The subroutine calculates the factorial of given number.                     #
#                                                                              #
# @params   $n     Number for which the factorial is sought                    #
# @returns  $fact  Factorial of the given number $n                            #
# ---------------------------------------------------------------------------- #
sub factorial {
    # Assign the subroutine argument to the local variable.
    my $n = $_[0];
    # Calculate the factorial of a number by recursion.
    my $fact = ($n == 0 ? 1 : factorial($n - 1) * $n);
    # Return the value of the factorial.   
    return $fact;
};

# ---------------------------------------------------------------------------- #
# Subroutine truncate_places()                                                 #
# ---------------------------------------------------------------------------- #
sub truncate_places {
    # Assign the subroutine arguments to the local variables.
    my $decimal = $_[0];
    my $places = $_[1];
    # Calculate the multiplication factor.
    my $factor = 10**$places;
    # Truncate the places using the multiplication factor.
    $decimal = int($decimal*$factor) / ($factor);
    # Truncate the decimal using the places plus two chars.
    $decimal = substr($decimal, 0, $places + 2);
    # Return the truncated decimal number.
    return $decimal;
};

# ---------------------------------------------------------------------------- #
# Subroutine estimate_terms()                                                  #
# ---------------------------------------------------------------------------- #
sub estimate_terms {
    # Assign the subroutine arguments to the local variables.
    my $places = (defined $_[0] ? $_[0] : 0);
    my $new_places = (defined $_[1] ? $_[1] : 0);
    # Declare the return variable.
    my $number_terms = undef;
    # Determine the estimated number of terms.
    if ($places <= 1) {
        $number_terms = $places;
    } elsif ($places <= $new_places) {
        $number_terms = 1;
    } else {
        $number_terms = int($places / $new_places) + 1;
    };
    # Return the estimated number of terms.
    return $number_terms;
};

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
# Subroutine check_places()                                                    #
# ---------------------------------------------------------------------------- #
sub check_places {
    # Assign the subroutine argument to the local variable.
    my $places = (defined $_[0] ? $_[0] : 0);
    # Set the string for the farewell message.
    my $msg = "The number of places is not valid. Terminating processing. Bye!";
    # Check if the given places are a valid number.
    if (is_unsigned_int($places) != 1) {
        # Print a message into the terminal window.
        print $msg . "\n";
        # Exit the script.
        exit;
    };
    # Return 1 (true).
    return 1;
};

# ---------------------------------------------------------------------------- #
# Subroutine S()                                                               #
# ---------------------------------------------------------------------------- #
sub S {
    # Assign the subroutine arguments to local variables.
    my ($j, $n, $p) = @_;
    # Set the precision for bignum.
    bignum -> precision(-$p);
    # Initialise the local variables.
    my $sum = 0;
    my $l = 0;
    my $r = 0;
    my $d = 0;
    my $k = 0;
    my $r0 = 0;
    my $run = 1;
    # Calculate the left sum.
    while ($k <= $n) {
        # Calculate the value of the denominator.
        $d = 8*$k+$j;
        # Calculate the left partial sum.
        $l = ($l + modexp(16, $n-$k, $d) / $d) % 1;
        # Increment the loop counter $k.
        $k += 1;
    };
    # Reset the loop counter.
    $k = $n + 1;
    # Calculate the right sum.
    while ($run == 1) {
        # Calculate the value of the denominator.
        $d = 8*$k+$j;
        # Calculate the right partial sum.
        $r = $r0 + (16**($n-$k)) / $d;
        # Check the exit condition of the loop.
        $run = ($r0 == $r ? 0 : 1);
        # Save the old partial sum.
        $r0 = $r;
        # Increment the loop counter $k.
        $k += 1;
    };
    # Calculate the total sum.
    $sum = $l + $r;
    # Return the total sum.
    return $sum;
};

#------------------------------------------------------------------------------# 
# Subroutine bbp_digit()                                                       #
#------------------------------------------------------------------------------# 
sub bbp_digit {
    # Assign the subroutine arguments to the local variables.
    my ($n, $p) = @_;
    # Set the precision for bignum.
    bignum -> precision(-$p);
    # Decrement the value with the digit of interest by 1.
    $n -= 1;
    # Calculate the fraction with the hex numbers from the nth digit upwards.
    my $dec = (4*S(1, $n, $p) - 2*S(4, $n, $p) -
               S(5, $n, $p) - S(6, $n, $p)) % 1;
    # Get the decimal representation of the digit.
    $dec = ($dec * 16) - ($dec * 16) % 1;
    # Get the hexadecimal representation of the digit. 
    my $hex = $HX[$dec];
    # Return the hex number.
    return $hex;
};

#------------------------------------------------------------------------------# 
# Subroutine bbp_digits()                                                      #
#------------------------------------------------------------------------------# 
sub bbp_digits {
    # Assign the subroutine arguments to the local variables.
    my ($n, $digits, $p) = @_;
    # Set the precision for bignum.
    bignum -> precision(-$p);
    # Initialise the local variables.
    my $newdec = undef;
    my $hex_digit = '';
    my $hex_digits = '';
    # Decrement the value with the digit of interest by 1.
    $n -= 1;
    # Calculate the fraction with the hex numbers from the nth digit upwards.
    my $dec = (4*S(1, $n, $p) - 2*S(4, $n, $p) -
               S(5, $n, $p) - S(6, $n, $p)) % 1;
    # Calculate the hexadecimal number.
    for (my $j = 0; $j < length($dec); $j++) {
        $newdec = $dec * 16;
        $dec = $newdec - ($newdec % 1);
        $hex_digit = $HX[$dec];
        $hex_digits = $hex_digits . $hex_digit; 
        $dec = $newdec - $dec;
    }; 
    # Return the hexadecimal number.
    return substr($hex_digits, 0, $digits);
};

#------------------------------------------------------------------------------# 
# Subroutine bbp_algorith()                                                    #
#------------------------------------------------------------------------------# 
sub bbp_algorithm {
    # Assign the subroutine arguments to the local variables.
    my ($places, $p) = @_;
    # Set the precision for bignum.
    bignum -> precision(-$p);
    # Initialise the local variable $pi_hex.
    my $pi_hex = "3.";
    # Declare the local variable $nth_digit.
    my $digits = undef;
    # Determine the hexadecimal places in a loop. 
    for (my $i = 1; $i <= $places; $i++) {
        $digits = bbp_digit($i, $p);
        $pi_hex = $pi_hex . $digits;   
    };
    # Return Pi in hexadecimal representation.
    return $pi_hex;
};

# ---------------------------------------------------------------------------- #
# Subroutine borwein25_algorithm()                                             #
# ---------------------------------------------------------------------------- #
sub borwein25_algorithm {
    # Assign the hash with the subroutine arguments to the local hash.
    my (%params) = @_;
    # Initialise the local variables.
    my $type0 = "pi";
    my $type1 = "tau";
    # Make a reference from the hash.
    my $args = \%params;
    # Initialise the locale variables.
    my $places = $args->{Places};
    my $n = $args->{Terms};
    my $p = $args->{Precision};
    my $trim = $args->{Trim};
    my $type = $args->{Type};
    # Check if the the local variables are defined.
    $places = (defined $places ? $places : 0);
    $n = (defined $n ? $n : 0);
    $p = (defined $p ? $p : $places);
    $trim = (defined $trim ? $trim : $places);
    $type = (defined $type ? $type : $type0);
    # Set the precision.
    bignum -> precision(-$p);
    # Initialise the return variable.
    my $circle_constant = 0;
    # Set the local constants.
    my $sqrt61 = sqrtroot(61);
    my $A = (212175710912 * $sqrt61) + 1657145277365;
    my $B = (13773980892672 * $sqrt61) + 107578229802750;
    my $C = (5280 * (236674 + 30303 * $sqrt61))**3;
    my $factor = sqrtroot($C) / 12;
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
        $numerator = factorial(6*$k)*($A +$k*$B);
        $denominator = (factorial($k)**3)*factorial(3*$k)*($C**($k));
        # Calculate the quotient.
        $a_k = $sign*($numerator / $denominator);
        # Add quotient to total sum.  
        $a_sum += $a_k;
        # Change the sign.
        $sign *= -1;
    };
    # Calculate the value of the circle_constant.
    $circle_constant = $factor / $a_sum;
    # Determine the value for Pi or for Tau.
    if ($type eq $type0) {
        $circle_constant = 1.0 * $circle_constant;
    } elsif ($type eq $type1) {
        $circle_constant = 2.0 * $circle_constant;
    };
    # Cut the decimal number to the needed places.
    $circle_constant = truncate_places($circle_constant, $trim);
    # Return the value of the circle constant.
    return "$circle_constant";
};

# ---------------------------------------------------------------------------- #
# Subroutine chudnovsky_algorithm()                                            #
# ---------------------------------------------------------------------------- #
sub chudnovsky_algorithm {
    # Assign the hash with the subroutine arguments to the local hash.
    my (%params) = @_;
    # Initialise the local variables.
    my $type0 = "pi";
    my $type1 = "tau";
    # Make a reference from the hash.
    my $args = \%params;
    # Initialise the locale variables.
    my $places = $args->{Places};
    my $n = $args->{Terms};
    my $p = $args->{Precision};
    my $trim = $args->{Trim};
    my $type = $args->{Type};
    # Check if the the local variables are defined.
    $places = (defined $places ? $places : 0);
    $n = (defined $n ? $n : 0);
    $p = (defined $p ? $p : $places);
    $trim = (defined $trim ? $trim : $places);
    $type = (defined $type ? $type : $type0);
    # Set the precision.
    bignum -> precision(-$p);
    # Initialise the return variable.
    my $circle_constant = 0;
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
        $a_k = $sign*($numerator / $denominator);
        # Add quotient to total sum.  
        $a_sum += $a_k;
        # Change the sign.
        $sign *= -1;
    };
    # Calculate the value of the circle_constant.
    $circle_constant = $c3 / (sqrt($c4)*$a_sum);
    # Determine Pi or Tau.
    if ($type eq $type0) {
        $circle_constant = 1.0 * $circle_constant;
    } elsif ($type eq $type1) {
        $circle_constant = 2.0 * $circle_constant;
    };
    # Cut the decimal number to the needed places.
    $circle_constant = truncate_places($circle_constant, $trim);
    # Return the value of the circle constant.
    return "$circle_constant";
};

# ---------------------------------------------------------------------------- #
# Subroutine chudnovsky_caller()                                               #
# ---------------------------------------------------------------------------- #
sub chudnovsky_caller {
    # Assign the subroutine arguments to the local variables.
    my $places = $_[0];
    my $method = $_[1];
    # Check if the places are valid. If not exit the script.
    check_places($places);
    # Calculate the required number of terms.
    my $terms = estimate_terms($places, 14);
    # Set the precision for the calculation.
    my $precision = $places + 15;
    # Get the value of the circle constant from the calculation.
    my $circle_constant = chudnovsky_algorithm(
        Places => $places,
        Terms => $terms,
        Precision => $precision,
        Trim => $places,
        Type => $method
    );
    # Return the value of the circle constant Pi or Tau.
    return "$circle_constant";
};

# ---------------------------------------------------------------------------- #
# Subroutine borwein25_caller()                                                #
# ---------------------------------------------------------------------------- #
sub borwein25_caller {
    # Assign the subroutine arguments to the local variables.
    my $places = $_[0];
    my $method = $_[1];
    # Check if the places are valid. If not exit the script.
    check_places($places);
    # Calculate the required number of terms.
    my $terms = estimate_terms($places, 25);
    # Set the precision for the calculation.
    my $precision = $places + 26;
    # Get the value of the circle constant from the calculation.
    my $circle_constant = borwein25_algorithm(
        Places => $places,
        Terms => $terms,
        Precision => $precision,
        Trim => $places,
        Type => $method
    );
    # Return the value of the circle constant Pi or Tau.
    return "$circle_constant";
};

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Call the caller subroutines                                                  #
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
sub pi_chudnovsky { return chudnovsky_caller($_[0], "pi") };
sub tau_chudnovsky { return chudnovsky_caller($_[0], "tau") };
sub pi_borwein25 { return borwein25_caller($_[0], "pi") };
sub tau_borwein25 { return borwein25_caller($_[0], "tau") };

# ============================================================================ #
# Subroutine read_pi()                                                         #
# ============================================================================ #
sub read_pi {
    # Assign the subroutine argument to the local variable.
    my $type = $_[0];
    # Initialise the local variables.
    my $line = "";
    my $pi = "";
    # Assemble the begin and end pattern.
    my $pattern0 = "# Begin Pi ${type}";
    my $pattern1 = "# End Pi ${type}"; 
    # Read the data from the DATA section.
    while (<DATA>) {
        # Read data only between the two given pattern.
        if (/$pattern0/../$pattern1/) {
            next if /$pattern0/ || /$pattern1/;
            $line = $_;
            $line =~ s/^\s+|\s+$//g;
            $pi = $pi . $line;
        };
    };
    # Return Pi.
    return $pi;
};

# ============================================================================ #
# Subroutine read_data()                                                       #
#                                                                              #  
# Description:                                                                 #
# The subroutine reads Pi in decimal and hexadecimal representation from the   #
# DATA section.                                                                #
# ============================================================================ #
sub read_data {
    # Save the position of DATA.
    my $data_start = tell DATA; 
    # Read decimal Pi with 1000 places.
    my $pi_dec = uc(read_pi("dec")); 
    # Reposition the filehandle right past to __DATA__
    seek DATA, $data_start, 0; 
    # Read hexadecimal Pi with 1000 places.
    my $pi_hex = uc(read_pi("hex"));
    # Return PI.
    return $pi_dec, $pi_hex;
};

# Read data from DATA.
($PI_DEC, $PI_HEX) = read_data();

1;

__DATA__

# Begin Pi dec
3.
14159265358979323846264338327950288419716939937510
58209749445923078164062862089986280348253421170679
82148086513282306647093844609550582231725359408128
48111745028410270193852110555964462294895493038196
44288109756659334461284756482337867831652712019091
45648566923460348610454326648213393607260249141273
72458700660631558817488152092096282925409171536436
78925903600113305305488204665213841469519415116094
33057270365759591953092186117381932611793105118548
07446237996274956735188575272489122793818301194912
98336733624406566430860213949463952247371907021798
60943702770539217176293176752384674818467669405132
00056812714526356082778577134275778960917363717872
14684409012249534301465495853710507922796892589235
42019956112129021960864034418159813629774771309960
51870721134999999837297804995105973173281609631859
50244594553469083026425223082533446850352619311881
71010003137838752886587533208381420617177669147303
59825349042875546873115956286388235378759375195778
18577805321712268066130019278766111959092164201989
# End Pi dec

# Begin Pi hex
3.
243f6a8885a308d313198a2e03707344a4093822299f31d008
2efa98ec4e6c89452821e638d01377be5466cf34e90c6cc0ac
29b7c97c50dd3f84d5b5b54709179216d5d98979fb1bd1310b
a698dfb5ac2ffd72dbd01adfb7b8e1afed6a267e96ba7c9045
f12c7f9924a19947b3916cf70801f2e2858efc16636920d871
574e69a458fea3f4933d7e0d95748f728eb658718bcd588215
4aee7b54a41dc25a59b59c30d5392af26013c5d1b023286085
f0ca417918b8db38ef8e79dcb0603a180e6c9e0e8bb01e8a3e
d71577c1bd314b2778af2fda55605c60e65525f3aa55ab9457
48986263e8144055ca396a2aab10b6b4cc5c341141e8cea154
86af7c72e993b3ee1411636fbc2a2ba9c55d741831f6ce5c3e
169b87931eafd6ba336c24cf5c7a325381289586773b8f4898
6b4bb9afc4bfe81b6628219361d809ccfb21a991487cac605d
ec8032ef845d5de98575b1dc262302eb651b8823893e81d396
acc50f6d6ff383f442392e0b4482a484200469c8f04a9e1f9b
5e21c66842f6e96c9a670c9c61abd388f06a51a0d2d8542f68
960fa728ab5133a36eef0b6c137a3be4ba3bf0507efb2a98a1
f1651d39af017666ca593e82430e888cee8619456f9fb47d84
a5c33b8b5ebee06f75d885c12073401a449f56c16aa64ed3aa
62363f77061bfedf72429b023d37d0d724d00a1248db0fead3
# End Pi hex

__END__
=encoding utf8

=head1 NAME

ConstantCalculus::CircleConstant - Perl extension for the high accuracy calculation of circle constants using big numbers.

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

Calculate the value of the circle constant C<Pi>:

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 100;

  # Use the calculation method for Pi.
  $pi = pi_chudnovsky($places);
  print $pi . "\n";

  # Use the calculation method for Pi.
  $pi = pi_borwein25($places);
  print $pi . "\n";

  # Use the calculation algorithm for Pi directly.
  $pi = chudnovsky([
      Places => 100,     # Set the number of places to 100
      Terms => 9,        # Set the number of terms to 9 
      Precision => 115,  # Set the precision to 115
      Trim => 115,       # Trim the value of Pi to 115 places      
      Type => "pi"       # Calculate the value of Pi
  ]);
  print $pi . "\n";

Calculate the value of the circle constant C<Tau>:

  # Declare the variable for Tau.
  my $tau = undef;

  # Set the number of places.
  my $places = 100;

  # Use the calculation method for Tau.
  my $tau = tau_chudnovsky($places);
  print $tau . "\n";

  # Use the calculation method for Tau.
  my $tau = tau_borwein25($places);
  print $tau . "\n";

  # Use the calculation algorithm for Pi directly.
  $tau = chudnovsky([
      Places => 100,     # Set the number of places to 100
      Terms => 9,        # Set the number of terms to 9 
      Precision => 115,  # Set the precision to 115
      Trim => 115,       # Trim the value of Tau to 115 places      
      Type => "tau"      # Calculate the value of Tau
  ]);
  print $tau . "\n";

Use BBP for calculation with respect to C<Pi>:

  # Print the nth hexadecimal digit of Pi.
  my $nth = 1;
  print bbp_digit($nth, 14);  # Use precision 14

  # Print the nth hexadecimal digit of Pi upwards.
  my $nth = 1;
  print bbp_digits($nth, 32, 128);  # Output 32 digits and use precision 128

  # Print Pi using BBP.
  my $places = 1;
  print bbp_algorithm($places, 14); # Use precision 14

Use predefined values of Pi and Tau.

    # Print Pi with 1000 decimal places.
    print $PI_DEC . "\n";

    # Print Pi with 1000 hexadecimal places.
    print $PI_HEX . "\n";

The square brackets in the above subroutine calls means that the named
arguments within the brackets are optional. Every named argument will be
preset in the subroutine if not defined.

=head1 REQUIREMENT

L<CPAN bignum|https://metacpan.org/dist/bignum>

=head1 DESCRIPTION

The circle constant is a mathematical constant. There are two variants of the
circle constant. Most common is the use of Pi (π) for the circle constant. More
uncommon is the use of Tau (τ) for the circle constant. The relation between 
them is τ = 2 π. There can be found other denotations for the well known name
Pi. The names are Archimedes's constant or Ludolph's constant. The circle
constant is used in formulas across mathematics and physics.

The circle constant is the ratio of the circumference C of a circle to its
diameter d, which is π = C/d or τ = 2 C/d. It is an irrational number, which
means that it cannot be expressed exactly as a ratio of two integers.  In
consequence of this, the decimal representation of a circle constant never
ends in there decimal places having a infinite number of places, nor enters
a permanently repeating pattern in the decimal places. The circle constant is
also a not algebraic transcendental number.

Over the centuries scientists developed formulas for approximating the circle
constant Pi. Chudnovsky's formula is one of them. A algorithm based on Chudnovsky's
formula can be used to calculate an approximation for Pi and also for Tau. The
advantage of the Chudnovsky formula is the good convergence. In contradiction 
the convergence of the Leibniz formula is quit bad.      

The challenge in providing an algorithm for the circle constant is that all
decimal places must be correct in terms of the formula. Based on the desired decimal
place number or precision, the number of places must be correct. The provided
algorithm takes care of this. At the moment the result of the implemented algorithm
was checked against the known decimal places of Pi up to 10000 places.

=head1 APPROXIMATIONS OF PI AND TAU

Fractions such as 22/7 or 355/113 can be used to approximate the circle constant
Pi, whereas 44/7 or 710/113 represent the approximation of the circle constant
Tau.

At the moment Chudnovsky's formula is fully implemented in the module to calculate
Pi as well as Tau. The algorithm from Borwein from 1989 is implemented for experimental
purposes. The most popular formula for calculating the circle constant is the Leibniz
formula.

=head1 IMPLEMENTATION

To be able to deal with large numbers pre decimal point and after the decimal point
as needed, the Perl module C<bignum> is used. The main subroutine argument is the 
number of places, which should be calculated for the circle constant.        

If terms and precision is not given, both are estimated from the given number of
places. This will result in a value of Pi, which is accurate to the requested 
places. If places, terms and/or precision is given, the behaviour of the algorithm
can be studied with respect to terms and/or precision.  

The number of iterations is calculated using the knowledge, that each iteration
should result in e.g. 14 new digits after the decimal point. So the value for the 
calculation of the number of terms is set to e.g. 14.  To make sure that reverse as
less as possible digits are changed, the number of terms to calculated is uneven.
So the sign of the term to add is negative after the decimal point.

To prevent rounding errors in the last digit, the precision is a factor of e.g. 14
higher than the requested number of places. The correct number of places is realised
by truncating the calculated and possibly rounded value of Pi to the requested number
of places.      

=head1 EXAMPLES

=head2 Calculation of Pi

=head3 Example 1

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate Pi.
  $pi = chudnovsky($places);
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

  # Set the value for trim.
  my $trim = 115;  

  # Calculate Pi.
  $tau = chudnovsky(
      Places => $places, 
      Terms => $terms,      
      Precision => $precision,
      Trim => $trim, 
      Type => "pi"  
  );
  print $pi . "\n";

=head3 Example 3

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Create an alias for the module method.
  *pi = \&pi_borwein25;

  # Declare the variable for Pi.
  my $pi = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate and print the value Pi.
  $pi = pi($places);
  print $pi . "\n";

=head3 Example 4

  # Print decimal Pi with 100 places.
  my $pi = $PI_DEC;
  $pi = substr($pi, 0, 102); 
  print $pi . "\n";

=head3 Example 5

  # Print hecadecimal Pi with 100 places.
  my $pi = $PI_HEX;
  $pi = substr($pi, 0, 102); 
  print $pi . "\n";

=head2 Calculation of Tau

=head3 Example 1

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Declare the variable for Tau.
  my $tau = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate Tau.
  $tau = chudnovsky($places);
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

  # Set the value for trim.
  my $trim = 115;  

  # Calculate Tau.
  $tau = chudnovsky(
      Places => $places, 
      Terms => $terms,      
      Precision => $precision,
      Trim => $trim, 
      Type => "pi"  
  );
  print $tau . "\n";

=head3 Example 3

  # Load the Perl module.
  use ConstantCalculus::CircleConstant;

  # Create an alias for the module method.
  *tau = \&tau_borwein25;

  # Declare the variable for Pi.
  my $tau = undef;

  # Set the number of places.
  my $places = 100;  

  # Calculate and print the value Pi.
  $tau = tau($places);
  print $tau . "\n";

=head1 MODULE METHODS

=head2 Main Methods
   
=head3 chudnovsky_algorithm()

Implementation of the Chudnovsky formula.

=head3 borwein25_algorithm()

Implementation of the Borwein 25 formula.

=head3 pi_borwein25()

Calculate Pi with the Borwein 25 algorithm.

=head3 tau_borwein25()

Calculate Tau with the Borwein 25 algorithm.

=head3 pi_chudnovsky()

Calculate Pi with the Chudnovsky algorithm.

=head3 tau_chudnovsky()

Calculate Tau with the Chudnovsky algorithm.

=head3 bbp_algorithm()

Apply the BBP algorithm.

=head3 bbp_digits()

Calculate as much as possible hexadecimal digits.

=head3 bbp_digit()

Calculate one hexadecimal digit.

=head3 S()

Calculate the S terms of the BBP algorithm

=head2 Other Methods

=head3 factorial()

The subroutine calculates the factorial of given number.

=head3 sqrtroot()

The subroutine calculates the square root of given number.

=head3 modexp()

The subroutine returns the result of a modular exponentiation. A modular 
exponentiation is an exponentiation applied over a modulus. The result
of the modular exponentiation is the remainder when an integer b (base) 
is exponentiated by e (exponent) and divided by a positive integer m
(modulus).

=head3 estimate_terms()

Estimates the terms or iterations to get the correct number of place.

=head3 truncate_places()

Truncate the number of places to a given value.

=head1 MODULE EXPORT

=head2 Generic export

=over 4

=item * chudnovsky_algorithm

=item * borwein25_algorithm

=item * pi_borwein25

=item * tau_borwein25

=item * pi_chudnovsky

=item * tau_chudnovsky

=item * bbp_algorithm

=item * bbp_digits

=item * bbp_digit

=item * S

=item * $PI_DEC

=item * $PI_HEX

=back

=head2 Export on demand

=over 4

=item * factorial

=item * sqrtroot

=item * modexp

=item * estimate_terms

=item * truncate_places

=back

=head1 LIMITATIONS

Limitations are not known yet.

=head1 BUGS

Bugs are not known yet.

=head1 NOTES

The implemented chudnovsky algorithm is used in a representation where the
well known terms are optimised for calculation. 

It seems that the Perl builtin function C<sqrt()> cannot used in general for
 determining the value of Pi or Tau with respect to some calculation formulas.

Chudnovsky's formula is working using the Perl builtin function C<sqrt()>. In
contradiction Borwein25's formula fails in calculation using the Perl builtin
function C<sqrt()>.

Using a coded user defined subroutine for calculating of a square root,
Borwein25's could be used for the calculation.  

=head1 OPEN ISSUE

Further calculations with higher precision are outstanding to check the
accuracy of the correctness of the last digits of the calculated circle
constant.

=head1 SEE ALSO

=head2 Programming informations

=over 4

=item * L<CPAN bignum|https://metacpan.org/dist/bignum>

=item * L<Perldoc bignum|https://perldoc.perl.org/bignum>

=back

=head2 Mathematical informations

=over 4

=item * Sources w.r.t. the circle constant Pi

=item * Sources w.r.t. the circle constant Tau

=item * Resources about the Leibniz formula

=item * Resources about the Chudnovsky formula

=item * Resources about Borwein's formulas

=back

=head2 Bibliography

=over 4

=item * David H. Bailey, The BBP Algorithm for Pi, September 17, 2006

=item * David H. Bailey, A catalogue of mathematical formulas involving π, with analysis, December 10, 2021

=item * David H. Bailey, Jonathan M. Borwein, Peter B. Borwein and Simon Plouffe, The Quest for Pi, June 25, 1996

=back

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

