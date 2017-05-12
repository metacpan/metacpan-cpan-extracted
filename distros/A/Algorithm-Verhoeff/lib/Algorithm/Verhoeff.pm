package Algorithm::Verhoeff;

use 5.0;
use strict;
use warnings;
#use bignum; # Needed so large numbers don't get turned into standard form

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::Verhoeff ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
    verhoeff_get verhoeff_check
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
    verhoeff_get verhoeff_check
);

our $VERSION = '0.3';


# Preloaded methods go here.

our $di; #Dihedral matrix
our @inverted =  (0, 4, 3, 2, 1, 5, 6, 7, 8, 9 );
our $f;

# First, build $f according to a simple(?) equation
BEGIN{
$f->[0] = [(0 .. 9)];
$f->[1] = [( 1, 5, 7, 6, 2, 8, 3, 0, 9, 4 )];
my $i=2;
my $j=0;
while($i < 8)
{
    while($j < 10)
    {
        $f->[$i]->[$j] = $f->[$i - 1]->[$f->[1]->[$j]];
        $j++;
    }
    $j = 0;
    $i++;
}

# This is defined
$di->[0] = [( 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 )];
$di->[1] = [( 1, 2, 3, 4, 0, 6, 7, 8, 9, 5 )];
$di->[2] = [( 2, 3, 4, 0, 1, 7, 8, 9, 5, 6 )];
$di->[3] = [( 3, 4, 0, 1, 2, 8, 9, 5, 6, 7 )];
$di->[4] = [( 4, 0, 1, 2, 3, 9, 5, 6, 7, 8 )];
$di->[5] = [( 5, 9, 8, 7, 6, 0, 4, 3, 2, 1 )];
$di->[6] = [( 6, 5, 9, 8, 7, 1, 0, 4, 3, 2 )];
$di->[7] = [( 7, 6, 5, 9, 8, 2, 1, 0, 4, 3 )];
$di->[8] = [( 8, 7, 6, 5, 9, 3, 2, 1, 0, 4 )];
$di->[9] = [( 9, 8, 7, 6, 5, 4, 3, 2, 1, 0 )];

}

# Now that's all set up, we can actually do stuff.

sub verhoeff_check
{
    my $input = shift;
    my $c = 0; # initialize check at 0
    my $digit;
    my $i = 0;
    foreach $digit (reverse split(//, $input))
    {
        $c = $di->[$c]->[$f->[$i % 8]->[$digit]]; # did you catch that?
        $i++;
    }
    if($c)
    {
        return 0; # a non-zero value of $c is a check failure
    }
    return 1;
}

sub verhoeff_get
{
    my $input = shift;
    my $c = 0; # initialize check at 0
    my $digit = 0;
    my $i = 0; my $r;
    foreach $digit (reverse split(//, $input))
    {
        $c = $di->[$c]->[$f->[($i+1) % 8]->[$digit]]; # not quite the same...
        $i++;
    }
    return $inverted[$c];
}
1;
__END__


=head1 NAME

Algorithm::Verhoeff - Perl extension for checking and computing Verhoeff
check digits

=head1 SYNOPSIS

  use Algorithm::Verhoeff;
  my $long_number = 1456789;
  # add a check digit to that to catch typos!
  
  $long_number .= verhoeff_get($long_number); # note - append don't add!
  print $long_number; #prints 14567894
  
  # Lets see if I can re-type that accurately
  my $test = '14657894'; # oops!
  unless (verhoeff_check($test))
  {
    print "Failed check - typo?";
  }

=head1 DESCRIPTION

This implements the Verhoeff check digit algorithm. It's a single digit checksum
designed specifically for catching data entry mistakes in number sequences. It
catches the vast majority of common mistakes such as transposed digits, ommitted
digits, double entered digits and so on.

=head2 EXPORT

By default, this module will export
verhoeff_check()
verhoeff_get()

Into the current package.

=head1 USAGE

Using numbers that pass the verhoeff check is useful for things like product codes.
This is because such numbers almost never pass the verhoeff check if they as mis-typed.
This includes common typos such as ommitted or repeated digits, transposed digits and so on.
Since it only adds a single digit onto what might already be a longish number, it's
a good algorithm for use where humans need to enter or read the numbers.

When we say 'number' we really mean 'string of digits' since that is what the Verhoeff
algorithm works on.

To generate such a number, pick a starting number, call verhoeff_check() to get a check digit,
and then APPEND that digit to the end of the original number. Do NOT add the digit arithmetically
to the original number.

The new number will how pass the verhoeff_check(). In other words, if verhoeff_check()
is called with the new number as its argument, it will return 1. If it is called with
a mistyped version of the original number it will (very probably) return 0. For common
forms of typo such as ommitted digits, accuracy is over 99%.

=head2 verhoeff_get($number)

verhoeff_get accepts a number or string as an argument, and returns a check digit between 0 and 9.


=head2 verhoeff_check($number)

verhoeff_check accepts a number of string as an argument, and returns 1 if it passes the check, or 0 otherwise.

=head1 WARNING

Both functions convert their argument to a string internally. This will break for large (<32 bit)numbers
due to Perl representing them in standard form when stringified. To get round this, either pass the number as a string to
begin with, or use the bignum module in your program.

Thus:

    my $num = 57382957482395748329574923; # Big number!
    verhoeff_get($num); # Fatal error unless program uses bignum module.

But:

    my $num = '57382957482395748329574923'; # Long string!
    verhoeff_get($num); # Works fine.

=head1 SEE ALSO

L<bignum>

=head1 AUTHOR

Jon Peterson (jon -at- snowdrift.org)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jon Peterson

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
