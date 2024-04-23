# -*- encoding: utf-8; indent-tabs-mode: nil -*-


use 5.38.0;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;

class Arithmetic::PaperAndPencil::Number 0.01;

use Carp;
use Exporter 'import';
use POSIX qw/floor/;

our @EXPORT_OK = qw/max_unit adjust_sub/;

field $value :param;
field $radix :param = 10;

method value { $value }
method radix { $radix }

my $digits = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
my @digits = split('', $digits);
my %digit_value;
my $val = 0;
for (@digits) {
  $digit_value{$_} = $val++;
}

ADJUST {
  if ($radix < 2 or $radix > 36) {
    croak("Radix $radix should be between 2 and 36");
  }
  my $valid_digits = substr($digits, 0, $radix);
  unless ($value =~ /^[$valid_digits]+$/) {
    croak("Invalid digit in value '$value' for radix $radix");
  }
  $value =~ s/^0*//g;
  if ($value eq '') {
    $value = '0';
  }
}

method chars {
  return length($value);
}

method is_odd {
  my $even_digits = '02468ACEGIKMOQSUWY';
  if ($radix % 2 == 0) {
    my $last = substr($value, -1, 1);
    my $pos  = index($even_digits, $last);
    return $pos == -1;
  }
  my $val = $value;
  $val =~ tr/02468ACEGIKMOQSUWY//d;
  return 1 == length($val) % 2;
}

method unit($len = 1) {
  if ($len > $self->chars) {
    $len = $self->chars;
  }
  return Arithmetic::PaperAndPencil::Number->new(
        radix => $radix
      , value => substr($value, $self->chars - $len)
      );
}

method carry($len = 1) {
  if ($len >= $self->chars) {
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '0');
  }
  else {
    return Arithmetic::PaperAndPencil::Number->new(
          radix => $radix
        , value => substr($value, 0, $self->chars - $len)
        );
  }
}

sub max_unit($radix) {
  if ($radix < 2 or $radix > 36) {
    croak("Radix $radix should be between 2 and 36");
  }
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$radix - 1]);
}

method _native_int {
  if ($self->chars > 2) {
    croak("Conversion to native allowed only for 1-digit numbers or 2-digit numbers");
  }
  my $tens  = $digit_value{$self->carry->value};
  my $units = $digit_value{$self->unit ->value};
  return $tens * $self->radix + $units;
}

sub add($x, $y, $invert) {
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Addition not allowed with different bases: $radix @{[$y->radix]}");
  }
  if ($x->chars != 1 and $y->chars != 1) {
    croak("Addition allowed only if at least one number has a single digit");
  }

  my @long_op;
  my $short_op;
  if ($x->chars == 1) {
    $short_op = $x->value;
    @long_op  = reverse(split '', $y->value);
  }
  else {
    $short_op = $y->value;
    @long_op  = reverse(split '', $x->value);
  }
  my $digit_nine = $digits[$radix - 1];  # '9' for radix 10, 'F' for radix 16, and so on
  my $a = $digit_value{$short_op};
  my $b = $digit_value{$long_op[0]};

  if ($a + $b < $radix) {
    $long_op[0] = $digits[$a + $b];
    return Arithmetic::PaperAndPencil::Number->new(
          radix => $radix
        , value => join('', reverse(@long_op)));
  }

  push @long_op, '0';
  $long_op[0] = $digits[$a + $b - $radix];
  for my $i (1 .. 0 + @long_op) {
    if ($long_op[$i] ne $digit_nine) {
      $long_op[$i] = $digits[1 + $digit_value{$long_op[$i]}];
      last;
    }
    $long_op[$i] = '0';
  }

  return Arithmetic::PaperAndPencil::Number->new(
        radix => $radix
      , value => join('', reverse(@long_op)));
}

sub minus($x, $y, $invert) {
  if ($invert) {
    ($x, $y) = ($y, $x);
  }
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Subtraction not allowed with different bases: $radix @{[$y->radix]}");
  }
  if ($x->chars != 1 or $y->chars != 1) {
    croak("Subtraction allowed only for single-digit numbers");
  }
  if ($x->value lt $y->value) {
    croak("The first number must be greater or equal to the second number");
  }
  my $x10 = $x->_native_int;
  my $y10 = $y->_native_int;
  my $z10 = $x10 - $y10;
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$z10]);
}

sub times($x, $y, $invert) {
  if ($invert) {
    ($x, $y) = ($y, $x);
  }
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Multiplication not allowed with different bases: $radix @{[$y->radix]}");
  }
  if ($x->chars != 1 or $y->chars != 1) {
    croak("Multiplication allowed only for single-digit numbers");
  }
  my $x10 = $x->_native_int;
  my $y10 = $y->_native_int;
  my $z10 = $x10 * $y10;
  my $zu  = $z10 % $radix;
  my $zt  = floor($z10 / $radix);
  return Arithmetic::PaperAndPencil::Number->new(value => $digits[$zt] . $digits[$zu]
                                               , radix => $radix);
}

sub divide($x, $y, $invert) {
  if ($invert) {
    ($x, $y) = ($y, $x);
  }
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Division not allowed with different bases: $radix @{[$y->radix]}");
  }
  if ($x->chars > 2) {
    croak("The dividend must be a 1- or 2-digit number");
  }
  if ($y->chars > 1) {
    croak("The divisor must be a single-digit number");
  }
  if ($y->value eq '0') {
    croak("Division by 0 not allowed");
  }
  my $xx = $x->_native_int;
  my $yy = $y->_native_int;
  my $qq = floor($xx / $yy);
  if ($qq >= $radix) {
    my $q0 = $qq % $radix;
    my $q1 = floor($qq / $radix);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$q1] . $digits[$q0]);
  }
  else {
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$qq]);
  }
}

sub num_cmp($x, $y, $invert) {
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Comparison not allowed with different bases: $radix @{[$y->radix]}");
  }
  return $x->chars <=> $y->chars
                   ||
         $x->value cmp $y->value;
}

sub alpha_cmp($x, $y, $invert) {
  my $radix = $x->radix;
  if ($radix != $y->radix) {
    croak("Comparison not allowed with different bases: $radix @{[$y->radix]}");
  }
  return $x->value cmp $y->value;
}

use overload '+' => \&add
           , '-' => \&minus
           , '*' => \&times
           , '/' => \&divide
           , '<=>' => \&num_cmp
           , 'cmp' => \&alpha_cmp
    ;

method complement($len) {
  my $s = $value;
  if (length($s) > $len) {
    croak("Parameter length $len should be greater than or equal to number's length @{[length($s)]}");
  }
  my $before = substr($digits, 0, $radix);
  my $after  = reverse($before);
  $_ = '0' x ($len - length($s)) . $s;
  eval "tr/$before/$after/";
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $_)
       + Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '1');
}

sub adjust_sub ($high, $low) {
  my $radix = $high->radix;
  if ($low->radix != $radix) {
    die "Subtraction not allowed with different bases: $radix @{[$low->radix]}";
  }
  if ($high->chars != 1) {
    die "The high number must be a single-digit number";
  }
  if ($low->chars > 2) {
    die "The low number must be a single-digit number or a 2-digit number";
  }
  my $adjusted_carry = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $low->carry->value);
  my $low_unit       = $low->unit;
  my $native_high     = $high->_native_int;
  my $native_low_unit = $low_unit->_native_int;
  if ($high < $low_unit) {
    $adjusted_carry +=  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => "1");
    $native_high    += $radix;
  }
  my $adjusted_high = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $adjusted_carry->value . $high->value);
  my $result        = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$native_high - $native_low_unit]);
  return ($adjusted_high, $result);
}

method square_root {
  if ($self->chars > 2) {
    croak("The number must be a single-digit number or a 2-digit number");
  }
  my $root = floor(sqrt($self->_native_int));
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $digits[$root])
}
'355/113'; # End of Arithmetic::PaperAndPencil

=encoding utf8

=head1 NAME

Arithmetic::PaperAndPencil::Number - integer, with elementary operations

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Arithmetic::PaperAndPencil::Number;

    my $x = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9');
    my $y = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '6');
    my $sum = $x + $y;
    my $pdt = $x * $y;

=head1 DESCRIPTION

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Number>  is  a   class  storing  integer
numbers and  simulating elementary operations  that a pupil  learns at
school. The simulated  operations are the operations  an average human
being can do in  his head, without outside help such as  a paper and a
pencil.

So,  operations are  implemented with  only very  simple numbers.  For
example, when adding two numbers, at  least one of them must have only
one  digit. And  when multiplying  numbers, both  numbers must  have a
single  digit.  Attempting  to  multiply, or  add,  two  numbers  with
multiple digits triggers an exception.

An important difference with the  average human being: most humans can
compute in  radix 10 only. Some  gifted humans may add  or subtract in
radix  8 and  in radix  16, but  they are  very few.  This module  can
compute in any radix from 2 to 36.

Another  difference  with normal  human  beings:  a  human can  add  a
single-digit   number  with   a  multi-digit   number,  provided   the
multi-digit number is not too long. E.g. a human can compute C<15678 +
6> and get C<15684>, but  when asked to compute C<18456957562365416378
+  6>, this  human will  fail to  remember all  necessary digits.  The
module has  no such limitations.  Or rather, the  module's limitations
are those of the Perl interpreter and of the host machine.

=head1 METHODS

=head2 new

An  instance  of  C<Arithmetic::PaperAndPencil::Number>  is  built  by
calling method C<new>  with two parameters, C<value>  and C<radix>. If
omitted, C<radix> defaults to 10.

=head2 radix

The numerical base, or radix, in which the number is defined.

=head2 value

The digits of the number.

=head2 chars

The number of chars in the C<value> attribute.

=head2 unit

Builds a  number (instance  of C<Arithmetic::PaperAndPencil::Number>),
using the last digit of the input number. For example, when applied to
number C<1234>, the C<unit> method gives C<4>.

Extended  usage:  given  a C<$len>  parameter  (positional,  optional,
default 1), builds a number using the last C<$len> digits of the input
number. For  example, when  applied to  number C<1234>  with parameter
C<2>, the C<unit>  method gives C<34>. When applied  to number C<1234>
with parameter C<3>, the C<unit> method gives C<234>.

=head2 carry

Builds a  number (instance  of C<Arithmetic::PaperAndPencil::Number>),
using  the input  number without  its  last digit.  For example,  when
applied to number C<1234>, the C<carry> method gives C<123>.

Extended  usage:  given  a C<$len>  parameter  (positional,  optional,
default 1), builds  a number, using the input number  without its last
C<$len>  digits. For  example,  when applied  to  number C<1234>  with
parameter C<2>, the C<carry> method  gives C<12> by removing 2 digits,
C<34>.  When  applied  to  number C<1234>  with  parameter  C<3>,  the
C<carry> method gives C<1>.

=head2 complement

Returns the  10-complement, 2-complement, 16-complement,  whatever, of
the number. Which complement is returned is determined by the number's
radix. The method requires another  parameter, to choose the number of
digits  in  the  computed  complement.  This  length  parameter  is  a
positional parameter.

Example

  radix  = 16     |
  number = BABE   | → complement = FFFF5652
  length = 8      |

=head2 square_root

Returns the square root of the objet, rounded down to an integer.

The  object must  be  a  single-digit or  a  double-digit instance  of
C<Arithmetic::PaperAndPencil::Number>.

=head2 is_odd

Returns an integer used as a boolean,  C<1> if the number is odd, C<0>
if the number is even.

=head1 FUNCTIONS

=head2 C<max_unit>

The input  parameter is the  radix (positional). The  function returns
the  highest   single-digit  number  for  this   radix.  For  example,
C<max-unit(10)> returns C<9> and C<max-unit(16)> returns C<F>.

The returned value is an instance  of C<Arithmetic::PaperAndPencil::Number>).

=head2 Addition C<add>

Adding two numbers with the same  radix. At least one argument must be
a single-digit number. This function is used to overload C<+>.

=head2 Subtraction C<minus>

Subtracting two  numbers with the  same radix. Both arguments  must be
single-digit numbers. This function is used to overload C<->.

=head2 Subtraction C<adjust_sub>

Actually, this is not the  plain subtraction. This function receives a
1-digit high number and  a 1- or 2-digit low number.  It sends back an
adjusted   high-number  and   a  subtraction   result.  The   adjusted
high-number is  the first number  greater than  the low number  and in
which the unit is the parameter high number.

For example (radix 10):

  high = 1, low = 54 → adjusted-high = 61, result = 7
  high = 8, low = 54 → adjusted-high = 58, result = 4

The parameters are positional.

=head2 Multiplication C<times>

Multiplying two  numbers with the  same radix. Both arguments  must be
single-digit numbers. This function is used to overload C<*>.

=head2 Division C<divide>

Dividing two numbers with the same radix. The first argument must be a
single-digit or double-digit number and  the second argument must be a
single-digit number (and greater than zero, of course).

=head2 Numeric Comparison C<num_cmp>

This  function interprets  the arguments  as numbers  and returns  the
3-way comparison of these numbers. This function overloads C<< <=> >>,
which means that  all other numeric comparisons (C<==>, C<<  < >>,
C<< <= >>, etc) are overloaded too.

=head2 Alphabetic Comparison C<alpha_cmp>

This  function interprets  the arguments  as strings  and returns  the
3-way  comparison of  these strings.  This function  overloads C<cmp>,
which means that  all other numeric comparisons  (C<eq>, C<lt>, C<le>,
etc) are overloaded too.

=head1 EXPORT

Functions C<max_unit> and C<adjust_sub> are exported.

=head1 AUTHOR

Jean Forget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

