package Data::Object::Number;

use Try::Tiny;
use Role::Tiny::With;

use Data::Object::Export qw(
  cast
  croak
  load
);

map with($_), my @roles = qw(
  Data::Object::Role::Detract
  Data::Object::Role::Dumper
  Data::Object::Role::Output
  Data::Object::Role::Throwable
);

map with($_), my @rules = qw(
  Data::Object::Rule::Comparison
  Data::Object::Rule::Defined
);

use overload (
  '""'     => 'data',
  '~~'     => 'data',
  fallback => 1
);

use parent 'Data::Object::Base::Number';

our $VERSION = '0.96'; # VERSION

# BUILD
# METHODS

sub roles {
  return cast([@roles]);
}

sub rules {
  return cast([@rules]);
}

# DISPATCHERS

sub abs {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Abs';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub atan2 {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Atan2';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub cos {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Cos';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub decr {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Decr';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub defined {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Defined';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub downto {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Downto';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub eq {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Eq';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub exp {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Exp';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ge {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Ge';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub gt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Gt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub hex {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Hex';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub incr {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Incr';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub int {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Int';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub log {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Log';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub le {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Le';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub lt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Lt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub mod {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Mod';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub ne {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Ne';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub neg {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Neg';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub pow {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Pow';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub sin {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Sin';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub sqrt {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Sqrt';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub to {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::To';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

sub upto {
  my ($self, @args) = @_;

  try {
    my $func = 'Data::Object::Func::Number::Upto';

    return cast(load($func)->new($self, @args)->execute);
  }
  catch {
    my $error = $_;

    $self->throw(ref($error) ? $error->message : "$error");
  };
}

1;

=encoding utf8

=head1 NAME

Data::Object::Number

=cut

=head1 ABSTRACT

Data-Object Number Class

=cut

=head1 SYNOPSIS

  use Data::Object::Number;

  my $number = Data::Object::Number->new(1_000_000);

=cut

=head1 DESCRIPTION

Data::Object::Number provides routines for operating on Perl 5 numeric
data. Number methods work on data that meets the criteria for being a number. A
number holds and manipulates an arbitrary sequence of bytes, typically
representing numberic characters (0-9). Users of numbers should be aware of the
methods that modify the number itself as opposed to returning a new number.
Unless stated, it may be safe to assume that the following methods copy, modify
and return new numbers based on their function.

=cut

=head1 METHODS

This package implements the following methods.

=cut

=head2 abs

  abs() : Any

The abs method returns the absolute value of the number. This method returns a
L<Data::Object::Number> object.

=over 4

=item abs example

  # given 12

  $number->abs; # 12

  # given -12

  $number->abs; # 12

=back

=cut

=head2 atan2

  atan2(Num $arg1) : NumObject

The atan2 method returns the arctangent of Y/X in the range -PI to PI This
method returns a L<Data::Object::Float> object.

=over 4

=item atan2 example

  # given 1

  $number->atan2(1); # 0.785398163397448

=back

=cut

=head2 cos

  cos() : NumObject

The cos method computes the cosine of the number (expressed in radians). This
method returns a L<Data::Object::Float> object.

=over 4

=item cos example

  # given 12

  $number->cos; # 0.843853958732492

=back

=cut

=head2 decr

  decr(Num $arg1) : NumObject

The decr method returns the numeric number decremented by 1. This method returns
a data type object to be determined after execution.

=over 4

=item decr example

  # given 123456789

  $number->decr; # 123456788

=back

=cut

=head2 defined

  defined() : NumObject

The defined method returns true if the object represents a value that meets the
criteria for being defined, otherwise it returns false. This method returns a
L<Data::Object::Number> object.

=over 4

=item defined example

  # given $number

  $number->defined; # 1

=back

=cut

=head2 downto

  downto(Int $arg1) : ArrayObject

The downto method returns an array reference containing integer decreasing
values down to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item downto example

  # given 10

  $number->downto(5); # [10,9,8,7,6,5]

=back

=cut

=head2 eq

  eq(Any $arg1) : NumObject

The eq method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item eq example

  # given 12345

  $number->eq(12346); # 0

=back

=cut

=head2 exp

  exp() : NumObject

The exp method returns e (the natural logarithm base) to the power of the
number. This method returns a L<Data::Object::Float> object.

=over 4

=item exp example

  # given 0

  $number->exp; # 1

  # given 1

  $number->exp; # 2.71828182845905

  # given 1.5

  $number->exp; # 4.48168907033806

=back

=cut

=head2 ge

  ge(Any $arg1) : NumObject

The ge method returns true if the argument provided is greater-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item ge example

  # given 0

  $number->ge(0); # 1

=back

=cut

=head2 gt

  gt(Any $arg1) : NumObject

The gt method performs a numeric greater-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item gt example

  # given 99

  $number->gt(50); # 1

=back

=cut

=head2 hex

  hex() : Str

The hex method returns a hex string representing the value of the number. This
method returns a L<Data::Object::String> object.

=over 4

=item hex example

  # given 175

  $number->hex; # 0xaf

=back

=cut

=head2 incr

  incr(Num $arg1) : NumObject

The incr method returns the numeric number incremented by 1. This method returns
a data type object to be determined after execution.

=over 4

=item incr example

  # given 123456789

  $number->incr; # 123456790

=back

=cut

=head2 int

  int() : IntObject

The int method returns the integer portion of the number. Do not use this
method for rounding. This method returns a L<Data::Object::Number> object.

=over 4

=item int example

  # given 12.5

  $number->int; # 12

=back

=cut

=head2 le

  le(Any $arg1) : NumObject

The le method returns true if the argument provided is less-than or equal-to
the value represented by the object. This method returns a Data::Object::Number
object.

=over 4

=item le example

  # given 0

  $number->le; # 0

=back

=cut

=head2 log

  log() : FloatObject

The log method returns the natural logarithm (base e) of the number. This method
returns a L<Data::Object::Float> object.

=over 4

=item log example

  # given 12345

  $number->log; # 9.42100640177928

=back

=cut

=head2 lt

  lt(Any $arg1) : NumObject

The lt method performs a numeric less-than comparison. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item lt example

  # given 86

  $number->lt(88); # 1

=back

=cut

=head2 mod

  mod() : NumObject

The mod method returns the division remainder of the number divided by the
argment. This method returns a L<Data::Object::Number> object.

=over 4

=item mod example

  # given 12

  $number->mod(1); # 0
  $number->mod(2); # 0
  $number->mod(3); # 0
  $number->mod(4); # 0
  $number->mod(5); # 2

=back

=cut

=head2 ne

  ne(Any $arg1) : NumObject

The ne method performs a numeric equality operation. This method returns a
L<Data::Object::Number> object representing a boolean.

=over 4

=item ne example

  # given -100

  $number->ne(100); # 1

=back

=cut

=head2 neg

  neg() : IntObject

The neg method returns a negative version of the number. This method returns a
L<Data::Object::Integer> object.

=over 4

=item neg example

  # given 12345

  $number->neg; # -12345

=back

=cut

=head2 pow

  pow() : NumObject

The pow method returns a number, the result of a math operation, which is the
number to the power of the argument. This method returns a
L<Data::Object::Number> object.

=over 4

=item pow example

  # given 12345

  $number->pow(3); # 1881365963625

=back

=cut

=head2 roles

  roles() : ArrayRef

The roles method returns the list of roles attached to object. This method
returns a L<Data::Object::Array> object.

=over 4

=item roles example

  # given $number

  $number->roles;

=back

=cut

=head2 rules

  rules() : ArrayRef

The rules method returns consumed rules.

=over 4

=item rules example

  my $rules = $number->rules();

=back

=cut

=head2 sin

  sin() : IntObject

The sin method returns the sine of the number (expressed in radians). This
method returns a data type object to be determined after execution.

=over 4

=item sin example

  # given 12345

  $number->sin; # -0.993771636455681

=back

=cut

=head2 sqrt

  sqrt(Int $arg1) : IntObject

The sqrt method returns the positive square root of the number. This method
returns a data type object to be determined after execution.

=over 4

=item sqrt example

  # given 12345

  $number->sqrt; # 111.108055513541

=back

=cut

=head2 to

  to(Int $arg1) : ArrayObject

The to method returns an array reference containing integer increasing or
decreasing values to and including the limit in ascending or descending order
based on the value of the floating-point object. This method returns a
L<Data::Object::Array> object.

=over 4

=item to example

  # given 5

  $number->to(9); # [5,6,7,8,9]
  $number->to(1); # [5,4,3,2,1]

=back

=cut

=head2 upto

  upto(Int $arg1) : Any

The upto method returns an array reference containing integer increasing
values up to and including the limit. This method returns a
L<Data::Object::Array> object.

=over 4

=item upto example

  # given 23

  $number->upto(25); # [23,24,25]

=back

=cut

=head1 ROLES

This package inherits all behavior from the folowing role(s):

=cut

=over 4

=item *

L<Data::Object::Role::Detract>

=item *

L<Data::Object::Role::Dumper>

=item *

L<Data::Object::Role::Output>

=item *

L<Data::Object::Role::Throwable>

=back

=head1 RULES

This package adheres to the requirements in the folowing rule(s):

=cut

=over 4

=item *

L<Data::Object::Rule::Comparison>

=item *

L<Data::Object::Rule::Defined>

=back
