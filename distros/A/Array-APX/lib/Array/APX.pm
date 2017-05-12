package Array::APX;

=pod 

=head1 NAME

Array::APX - Array Programming eXtensions

=head1 VERSION

This document refers to version 0.6 of Array::APX

=head1 SYNOPSIS

    use strict;
    use warnings;

    use Array::APX qw(:all);

    # Create two vectors [0 1 2] and [3 4 5]:
    my $x = iota(3);
    my $y = iota(3) + 3;

    print "The first vector is  $x";
    print "The second vector is $y\n";

    # Add these vectors and print the result:
    print 'The sum of these two vectors is ', $x + $y, "\n";
    
    # Create a function to multiply two values:
    my $f = sub { $_[0] * $_[1] };

    # Create an outer product and print it:
    print "The outer product of these two vectors is\n", $x |$f| $y;

yields

    The first vector is  [    0    1    2 ]
    The second vector is [    3    4    5 ]

    The sum of these two vectors is [    3    5    7 ]

    The outer product of these two vectors is
    [
      [    0    0    0 ]
      [    3    4    5 ]
      [    6    8   10 ]
    ]

=head1 DESCRIPTION

This module extends Perl-5 with some basic functionality commonly found in
array programming languages like APL, Lang5 etc. It is basically a wrapper
of Array::Deeputils and overloads quite some basic Perl operators in a way
that allows easy manipulation of nested data structures. These data 
structures are basically blessed n-dimensional arrays that can be handled
in a way similar to APL or Lang5.

A nice example is the computation of a list of prime numbers using an
archetypical APL solution. The basic idea is this: Create an outer product
of two vectors [2 3 4 ... ]. The resulting matrix does not contain any 
primes since every number is the product of at least two integers. Then
check for every number in the original vector [2 3 4 ... ] if it is a 
member of this matrix. If not, it must be a prime number. The set 
theoretic method 'in' returns a selection vector consisting of 0 and 1
values which can be used in a second step to select only the prime values
from the original vector. Using Array::APX this can be written in Perl 
like this:

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $f = sub { $_[0] * $_[1] }; # We need an outer product
    my $x;

    print $x->select(!($x = iota(199) + 2)->in($x |$f| $x));

How does this work? First a vector [2 3 4 ... 100] is created:

    $x = iota(99) + 2

This vector is then used to create an outer product (basically a multiplication
table without the 1-column/row:

    my $f = sub { $_[0] * $_[1] }; # We need an outer product
    ... $x |$f| $x ...

The |-operator is used here as the generalized outer-'product'-operator 
(if applied to two APX data structures it would act as the bitwise binary or) 
- it expects a 
function reference like $f in the example above. Thus it is possible to
create any outer 'products' - not necessarily based on multiplication only.
Using the vector stored in $x and this two dimensional matrix, the 
in-method is used to derive a boolean vector that contains a 1 at every 
place corresponding to an element on the left hand operand that is contained
in the right hand operand. This boolean vector is then inverted using the
overloaded !-operator:

  !($x = iota(99) + 2)->in($x |$f| $x)

Using the select-method this boolean vector is used to select the elements
corresponding to places marked with 1 from the original vector $x thus 
yielding a vector of prime numbers between 2 and 100:

    print $x->select(!($x = iota(199) + 2)->in($x |$f| $x));

=cut

use strict;
use warnings;

require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw(dress iota);
our %EXPORT_TAGS = ( 'all' => [ @EXPORT_OK ] );

our $VERSION = 0.6;

use Data::Dumper;
#use Array::DeepUtils qw(:all);
use Array::DeepUtils;
use Carp;

# The following operators will be generated automatically:
my %binary_operators = (
    '+'  => 'add',
    '*'  => 'multiply',
    '-'  => 'subtract',
    '%'  => 'mod',
    '**' => 'power',
    '&'  => 'bitwise_and',
    '^'  => 'bitwise_xor',
);

# Overload everything defined in %binary_operators:
eval "use overload '$_' => '$binary_operators{$_}';" 
    for keys(%binary_operators);

# Binary operators with trick (0 instead of '' or undef) - these will be generated
# automatically, too:
my %special_binary_operators = (
    '==' => 'numeric_equal',
    '!=' => 'numeric_not_equal',
    '<'  => 'numeric_less_than',
    '<=' => 'numeric_less_or_equal',
    '>'  => 'numeric_greater_than',
    '>=' => 'numeric_greater_or_equal',
    'eq' => 'string_equal',
    'ne' => 'string_not_equal',
    'lt' => 'string_less_than',
    'le' => 'string_less_or_equal',
    'gt' => 'string_greater_than',
    'ge' => 'string_greater_or_equal',
);

# Overload everything defined in %special_binary_operatos:
eval "use overload '$_' => '$special_binary_operators{$_}';"
    for keys(%special_binary_operators);

# All other overloads are here:
use overload (
# Unary operators:
    '!' => 'not',
# Non-standard operators:
    '|'  => 'outer',      # This also implements the bitwise binary 'or'!
    '/'  => 'reduce',     # This also implements the binary division operator!
    'x'  => 'scan',
    '""' => '_stringify',
);

###############################################################################
# Overloading unary operators:
###############################################################################

=head1 Overloaded unary operators

Overloaded unary operators are automatically applied to all elements of
a (nested) APX data structure. The following operators are currently
available: !

=cut

sub not # Not, mapped to '!'.
{
    my $data = [@{$_[0]}];
    Array::DeepUtils::unary($data, sub { return 0+ !$_[0] });
    return bless $data;
}

###############################################################################
# Overloading binary operators:
###############################################################################

=head1 Overloaded binary operators

In general all overloaded binary operators are automatically applied in an
element wise fashion to all (corresponding) elements of APX data structures.

The following operators are currently available and do what one would
expect: 

=head2 +, -, *, /, %, **, |, &, ^, ==, !=, <, >, <=, >=, eq, ne, le, lt, ge, gt

These operators implement addition, subtraction, multiplication, division,
modulus, power, bitwise or / and /xor, numerical equal/not equal, numerical
less than, numerical greater than, numerical less or equal, numerical greater
or equal, string equal, string not equal, string less than, string less or 
equal, string greater than, string greater or equal

=cut

# Overload basic binary operators:
eval ('
    sub ' . $binary_operators{$_} . '
    {
        my ($self, $other, $swap) = @_;
        my $result = ref($other) ? [@$other] : [$other];
        ($self, $result) = ($result, [@$self]) if $swap;
        _binary([@$self], $result, sub { $_[0] ' . $_ . ' $_[1] }, 1);
        return bless $result;
    }
') for keys(%binary_operators);

eval ('
    sub ' . $special_binary_operators{$_} . '
    {
        my ($self, $other, $swap) = @_;
        my $result = ref($other) ? [@$other] : [$other];
        ($self, $result) = ($result, [@$self]) if $swap;
        _binary([@$self], $result, sub { 0+ ($_[0] ' . $_ . ' $_[1]) }, 1);
        return bless $result;
    }
') for keys(%special_binary_operators);

=head2 Generalized outer products

A basic function in every array programming language is an operator to create
generalized outer products of two vectors. This generalized outer product
operator consists of a function pointer that is enclosed in two '|' (cf. the
prime number example at the beginning of this documentation). Given two 
APX vectors a traditional outer product can be created like this:

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $f = sub { $_[0] * $_[1] };
    my $x = iota(10) + 1;
    print $x |$f| $x;

This short program yields the following output:

    [
      [    1    2    3    4    5    6    7    8    9   10 ]
      [    2    4    6    8   10   12   14   16   18   20 ]
      [    3    6    9   12   15   18   21   24   27   30 ]
      [    4    8   12   16   20   24   28   32   36   40 ]
      [    5   10   15   20   25   30   35   40   45   50 ]
      [    6   12   18   24   30   36   42   48   54   60 ]
      [    7   14   21   28   35   42   49   56   63   70 ]
      [    8   16   24   32   40   48   56   64   72   80 ]
      [    9   18   27   36   45   54   63   72   81   90 ]
      [   10   20   30   40   50   60   70   80   90  100 ]
    ]

=cut

# Create a generalized outer 'product' based on a function reference.
# In addition to that the |-operator which is overloaded here can also act
# as binary 'or' if applied to two APX structures.
my @_outer_stack;
sub outer 
{
    my ($left, $right) = @_;

    if ((ref($left) eq __PACKAGE__ and ref($right) eq __PACKAGE__) or
        (ref($left) eq __PACKAGE__ and defined($right) and !ref($right))
       ) # Binary or
    {
        my ($self, $other) = @_;
        my $result = ref($right) ? [@$right] : [$right];
        Array::DeepUtils::binary([@$left], $result, sub { $_[0] | $_[1] }, 1);
        return bless $result;
    }
    # If the right side argument is a reference to a subroutine we are at
    # the initial stage of a |...|-operator and have to rememeber the 
    # function to be used as well as the left hand operator:
    elsif (ref($left) eq __PACKAGE__ and ref($right) eq 'CODE')
    {
        my %outer;
        $outer{left}     = $left;  # APX object
        $outer{operator} = $right; # Reference to a subroutine
        push @_outer_stack, \%outer;
        return;
    }
    elsif (ref($left) eq __PACKAGE__ and !defined($right))
    {   # Second phase of applying the |...|-operator:
        my $info = pop @_outer_stack;
        my ($a1, $a2) = ([@{$info->{left}}], [@{$left}]);
        my @result;

        for my $i ( 0 .. @$a1 - 1 )
        {
            for my $j ( 0 .. @$a2 - 1 )
            {
                my $value = $a2->[$j];
                _binary($a1->[$i], $value, $info->{operator});
                $result[$i][$j] = $value;
            }
        }

        return bless \@result;
    }

    croak 'outer: Strange parametertypes: >>', ref($left), 
          '<< and >>', ref($right), '<<';
}

=head2 The reduce operator /

The operator / acts as the reduce operator if applied to a reference to a 
subroutine as its left argument and an APX structure as its right element:

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $x = iota(100) + 1;
    my $f = sub { $_[0] + $_[1] };

   print $f/ $x, "\n";

calculates the sum of all integers between 1 and 100 (without using Gauss'
summation formula just by repeated addition). The combined operator

    $f/

applies the function referenced by $f between each two successive elements 
of the APX structure on the right hand side of the operator.

=cut

sub reduce
{
    my ($left, $right, $swap) = @_;

    if (ref($left) eq __PACKAGE__ and ref($right) ne 'CODE') # Binary division
    {
         my $result = ref($right) ? [@$right] : [$right];
         ($left, $result) = ($result, [@$left]) if $swap;
        _binary([@$left], $result, sub { $_[0] / $_[1] }, 1);
        return bless $result;
    }
    elsif (ref($_[0]) eq __PACKAGE__ and ref($_[1]) eq 'CODE') # reduce operator
    {
        my $result = shift @$left;
        for my $element (@$left)
        {
            eval { _binary($element, $result, $right); };
            croak "reduce: Error while applying reduce: $@\n" if $@;
        }

        return $result;
    }

    croak 'outer: Strange parametertypes: ', ref($_[0]), ' and ', ref($_[0]);
}

=head2 The scan operator x

The scan-operator works like the \-operator in APL - it applies a binary 
function to all successive elements of an array but accumulates the results
gathered along the way. The following example creates a vector of the 
partial sums of 0, 0 and 1, 0 and 1 and 2, 0 and 1 and 2 and 3 etc.:

    $f = sub { $_[0] + $_[1] };
    $x = $f x iota(10);
    print $x;

This code snippet yields the following result:

    [    0    1    3    6   10   15   21   28   36   45 ]

=cut

sub scan
{
    my ($argument, $function, $swap) = @_;

    croak "scan operator: Wrong sequence of function and argument!\n"
        unless $swap;

    croak "scan operator: No function reference found!\n"
        if ref($function) ne 'CODE';

    my @result;
    push @result, (my $last_value = shift @$argument);
    for my $element (@$argument)
    {
        _binary($element, $last_value, $function);
        push @result, $last_value;
    }

    return bless \@result;
}

###############################################################################
# Exported functions:
###############################################################################

=head1 Exported functions

=head2 dress

This function expects an array reference and converts it into an APX objects.
This is useful if nested data structures that have been created outside of
the APX framework are to be processed using the APX array processing 
capabilities. 

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $array = [[1, 2], [3, 4]];
    my $x = dress($array);
    print "Structure:\n$x";

yields the following output:

    Structure:
    [
      [    1    2 ]
      [    3    4 ]
    ]

=cut

sub dress # Transform a plain vanilla Perl array into an APX object.
{
    my ($value) = @_;
    croak "Can't dress a non-reference!" if ref($value) ne 'ARRAY';
    return bless $value;
}

=head2 iota

This function expects a positive integer value as its argument and returns
an APX vector with unit stride, starting with 0 and containing as many 
elements as specified by the argument:

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $x = iota(10);
    print "Structure:\n$x";

yields

    Structure:
    [    0    1    2    3    4    5    6    7    8    9 ]

=cut

# Create a unit stride vector starting at 0:
sub iota 
{
    my ($argument) = @_;

    croak "iota: Argument is not a positive integer >>$argument<<\n"
        if $argument !~ /^[+]?\d+$/;

    return bless [ 0 .. $_[0] - 1 ]; 
}

###############################################################################
# APX-methods:
###############################################################################

=head1 APX-methods

=head2 collapse

To convert an n-dimensional APX-structure into a one dimensional structure,
the collapse-method is used:

    use strict;
    use warnings;

    use Array::APX qw(:all);

    print dress([[1, 2], [3, 4]])->collapse();

yields

    [    1    2    3    4 ]

=cut

sub collapse { return bless Array::DeepUtils::collapse([@{$_[0]}]); }

=head2 grade

The grade-method returns an index vector that can be used to sort the elements
of the object, grade was applied to. For example

    print dress([3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5])->grade();

yields

    [    3    1    6    9    0    2    8    4   10    7    5 ]

So to sort the elements of the original object, the subscript-method could
be applied with this vector as its argument.

=cut

sub grade
{
    my ($data) = @_;

    my %h = map { $_ => $data->[$_] } 0 .. @$data - 1;

    return bless [ sort { $h{$a} <=> $h{$b} } keys %h ];
}

=head2 in

This implements the set theoretic 'in'-function. It checks which elements of
its left operand data structure are elements of the right hand data structure
and returns a boolean vector that contains a 1 at corresponding locations 
of the left side operand that are elements of the right side operand.

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $x = iota(10);
    my $y = dress([5, 11, 3, 17, 2]);
    print "Boolean vector:\n", $y->in($x);

yields

    Boolean vector:
    [    1    0    1    0    1 ]

Please note that the in-method operates on a one dimensional APX-object while
its argument can be of any dimension >= 1.

=cut

# Set function 'in':
sub in
{
    my ($what, $where) = @_;

    croak 'in: argument is not an APX-object: ', ref($where), "\n" 
        unless ref($where) eq __PACKAGE__;

    my @result;
    push (@result, _is_in($_, $where)) for (@$what);
    return bless \@result;
}

sub int 
{
    my $data = [@{$_[0]}];
    Array::DeepUtils::unary($data, sub { return int($_[0]) });
    return bless $data;
}

=head2 index

The index-method returns an index vector containing the indices of the elements
of the object it was applied to with respect to its argument which must be an
APX-object, too. Thus

    print dress([[1, 3], [4, 5]])->index(dress([[1, 2, 3], [4, 5, 6], [7, 8, 9]]));

yields

    [
      [
        [    0    0 ]
        [    0    2 ]
      ]
      [
        [    1    0 ]
        [    1    1 ]
      ]
    ]


=cut

sub index
{
    my ($a, $b) = @_;

    croak 'index: argument is not an APX-object: ', ref($b), "\n" 
        unless ref($b) eq __PACKAGE__;

    return bless Array::DeepUtils::idx([@$a], [@$b]);
}

=head2 remove

The remove-method removes elements from an APX-object controlled by an index 
vector supplied as its argument (which must be an APX-object, too):

    print iota(10)->remove(dress([1, 3, 5]));

yields

    [    0    2    4    6    7    8    9 ]

=cut

sub remove
{
    my ($a, $b) = @_;

    croak 'remove: argument is not an APX-object: ', ref($b), "\n" 
        unless ref($b) eq __PACKAGE__;

    $a = [@$a];
    Array::DeepUtils::remove($a, [@$b]);
    return bless $a;
}

=head2 reverse

The reverse-method reverses the sequence of elements in an APX-object, thus

    print iota(5)->reverse();

yields

    [    4    3    2    1    0 ]

=cut

sub reverse { return bless [reverse(@{$_[0]})]; }

=head2 rho

The reshape-method has fulfills a twofold function: If called without any
argument it returns an APX-object describing the structure of the object it
was applied to. If called with an APX-object as its parameter, the 
rho-method restructures the object it was applied to according to the 
dimension values specified in the parameter (please note that rho will 
reread values from the object it was applied to if there are not enough to
fill the destination structure). The following code example
shows both usages of rho:

    use strict;
    use warnings;

    use Array::APX qw(:all);

    my $x = iota(9);
    my $y = dress([3, 3]);

    print "Data rearranged as 3-times-3-matrix:\n", my $z = $x->rho($y);
    print 'Dimensionvector of this result: ', $z->rho();

This test program yields the following output:

    Data rearranged as 3-times-3-matrix:
    [
      [    0    1    2 ]
      [    3    4    5 ]
      [    6    7    8 ]
    ]
    Dimensionvector of this result: [    3    3 ]

=cut

sub rho
{
    my ($data, $control) = @_;

    if (!defined($control)) # Return a structure object
    {
        return bless Array::DeepUtils::shape([@$data]);
    }
    else
    {
        croak "rho: Control structure is not an APX-object!" 
            if ref($control) ne __PACKAGE__;

        return bless Array::DeepUtils::reshape([@$data], [@$control]);
    }
}

=head2 rotate

rotate rotates an APX-structure along several axes. The following example shows
the rotation of a two dimensional data structure along its x- and y-axes by
+1 and -1 positions respecitively:

    print dress([[1, 2, 3], [4, 5, 6], [7, 8, 9]])->rotate(dress([1, -1]));

The result of this rotation is thus

    [
      [    8    9    7 ]
      [    2    3    1 ]
      [    5    6    4 ]
    ]

=cut

sub rotate
{
    my ($a, $b) = @_;

    croak 'rotate: argument is not an APX-object: ', ref($b), "\n" 
        unless ref($b) eq __PACKAGE__;

    return bless Array::DeepUtils::rotate([@$a], [@$b]);
}

=head2 scatter

The scatter-method is the inverse of subscript. While subscript selects 
values from an APX-object, controlled by an index vector, scatter creates
a new data structure with elements read from the APX-object it was applied 
to and their positions controlled by an index vector. The following example
shows the use of scatter:

    print (iota(7) + 1)->scatter(dress([[0, ,0], [0, 1], [1, 0], [1, 1]]));

yields

    [
      [    1    2 ]
      [    3    4 ]
    ]

=cut

sub scatter
{
    my ($a, $b) = @_;

    croak 'scatter: argument is not an APX-object: ', ref($b), "\n" 
        unless ref($b) eq __PACKAGE__;

    return bless Array::DeepUtils::scatter([@$a], [@$b]);
}

=head2 select

The select-method is applied to a boolean vector and selects those elements
from its argument vector that correspond to places containing a true value
in the boolean vector. Thus

    use strict;
    use warnings;
    use Array::APX qw(:all);

    my $x = iota(10) + 1;
    my $s = dress([0, 1, 1, 0, 1, 0, 1]);

    print $x->select($s);

yields

    [    2    3    5    7 ]

Please note that select works along the first dimension of the APX-object it is
applied to and expects a one dimensional APX-objects as its argument.

=cut

sub select
{
    my ($data, $control) = @_;

    croak 'select: argument is not an APX-object: ', ref($control), "\n" 
        unless ref($control) eq __PACKAGE__;

    my @result;
    for my $i ( 0 .. @$control - 1 )
    {
        push (@result, $data->[$i]) if $control->[$i];
    }

    return bless \@result;
}

=head2 slice

slice extracts part of a nested data structure controlled by a coordinate
vector as the following example shows:

    print (iota(9) + 1)->rho(dress([3, 3]))->slice(dress([[1, 0], [2, 1]]));

yields

    [
      [    4    5 ]
      [    7    8 ]
    ]

=cut

sub slice
{
    my ($data, $control) = @_;

    croak 'slice: argument is not an APX-object: ', ref($control), "\n" 
        unless ref($control) eq __PACKAGE__;

    return bless Array::DeepUtils::dcopy([@$data], [@$control]);
}

=head2 strip

strip is the inverse function to dress() - it is applied to an APX data
structure and returns a plain vanilla Perl array:

    use strict;
    use warnings;
    use Array::APX qw(:all);
    use Data::Dumper;

    my $x = iota(3);
    print Dumper($x->strip);

yields

    $VAR1 = [
              0,
              1,
              2
            ];

=cut

sub strip { return [@{$_[0]}]; }

=head2 subscript

The subscript-method retrieves values from a nested APX-data structure 
controlled by an index vector (an APX-object, too) as the following simple
example shows:

    print (iota(9) + 1)->rho(dress([3, 3]))->subscript(dress([1]));

returns the element with the index 1 from a two dimensional data structure
that contains the values 1 to 9 yielding:

    [
      [    4    5    6 ]
    ]

=cut

sub subscript
{
    my ($data, $control) = @_;

    croak 'subscript: argument is not an APX-object: ', ref($control), "\n" 
        unless ref($control) eq __PACKAGE__;

    return bless Array::DeepUtils::subscript([@$data], [@$control]);
}

=head2 transpose

transpose is used to transpose a nested APX-structure along any of its axes.
In the easiest two dimensional case this corresponds to the traditional 
matrix transposition, thus

    print (iota(9) + 1)->rho(dress([3, 3]))->transpose(1);

yields

    [
      [    1    4    7 ]
      [    2    5    8 ]
      [    3    6    9 ]
    ]

=cut

sub transpose
{
    my ($data, $control) = @_;

    croak "transpose: argument is not an integer: >>$control<<\n" 
        if $control !~ /^[+-]?\d+/;

    return bless Array::DeepUtils::transpose([@$data], $control);
}

###############################################################################
# Support functions - not to be exported (these are mostly lend from Lang5).
###############################################################################

# Apply a binary word to a nested data structure.
sub _binary {
    my $func = $_[2];

    # both operands not array refs -> exec and early return
    if ( ref($_[0]) ne 'ARRAY' and ref($_[1]) ne 'ARRAY' ) {
        $_[1] = $func->($_[0], $_[1]);
        return 1;
    }

    # no eval because _binary will be called in an eval {}
    Array::DeepUtils::binary($_[0], $_[1], $func);

    return 1;
}

# Implements '.'; dump a scalar or structure to text.
sub _stringify {
    my($element) = @_;
    $element = [@$element];

    # shortcut for simple scalars
    if ( !ref($element) or ref($element) eq 'Lang5::String' ) {
        $element = 'undef' unless defined $element;
        $element .= "\n" 
            if $element =~ /^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/;
        return $element;
    }

    my $indent = 2;
    my @estack = ( $element );
    my @istack = ( 0 );

    my $txt = '';

    while ( @estack ) {

        my $e = $estack[-1];
        my $i = $istack[-1];

        # new array: output opening bracket
        if ( $i == 0 ) {
            if ( $txt ) {
                $txt .= "\n";
                $txt .= ' ' x ( $indent * ( @istack - 1 ) );
            }
            $txt .= '[';
        }

        if ( $i <= $#$e  ) {
            # push next reference and a new index onto stacks
            if ( ref($e->[$i]) and ref($e->[$i]) ne 'Lang5::String' ) {
                push @estack, $e->[$i];
                push @istack, 0;
                next;
            }

            # output element
            if ( $txt =~ /\]$/ ) {
                $txt .= "\n";
                $txt .= ' ' x ( $indent * @istack );
            } else {
                $txt .= ' ';
            }
            $txt .= defined($e->[$i]) ? sprintf("%4s", $e->[$i]) : 'undef';
        }

        # after last item, close arrays
        # on an own line and indent next line
        if ( $i >= $#$e ) {

            my($ltxt) = $txt =~ /(?:\A|\n)([^\n]*?)$/;

            #  The current text should not end in a closing bracket as it
            # would if we had typed an array and it should not end in a
            # parenthesis as it would if we typed an array with an object
            # type .
            if ( $ltxt =~ /\[/ and $ltxt !~ /\]|\)$/ ) {
                $txt .= ' ';
            } else {
                $txt .= "\n";
                $txt .= ' ' x ( $indent * ( @istack - 1 ) );
            }
            $txt .= ']';

            # Did we print an element that had an object type set?
            my $last_type = ref(pop @estack);
            $txt .= "($last_type)"
                if $last_type
                   and
                   $last_type ne 'ARRAY'
                   and
                   $last_type ne 'Lang5::String';
            pop @istack;
        }

        $istack[-1]++
            if @istack;
    }

    $txt .= "\n" unless $txt =~ /\n$/;

    return $txt;
}

# Return 1 if a scalar element is found in a structure (set operation in).
sub _is_in 
{
    my($el, $data) = @_;

    for my $d ( @$data ) 
    {
        if ( ref($d) eq 'ARRAY' ) 
        {
            return 1 if _is_in($el, $d);
        } 

        return 1 if $el eq $d;
    }

    return 0;
}

=head1 SEE ALSO

Array::APX relies mainly on Array::Deeputils which, in turn, was developed 
for the interpreter of the array programming language Lang5. The source of 
Array::Deeputils is maintained in the source repository of Lang. In addition
to that Array::APX borrows some basic functions of the Lang5 interpreter
itself, too.

=head2 Links

=over

=item *

L<The lang5 Home Page|http://lang5.sf.net/>.

=back

=head1 AUTHOR

Bernd Ulmann E<lt>ulmann@vaxman.deE<gt>

Thomas Kratz E<lt>tomk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2012 by Bernd Ulmann, Thomas Kratz

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either Perl version
5.8.8 or, at your option, any later version of Perl 5 you may
have available.

=cut

1;
