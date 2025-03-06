package Carp::Assert::More;

use 5.010;
use strict;
use warnings;

use parent 'Exporter';
use Scalar::Util qw( looks_like_number );

use vars qw( $VERSION @ISA @EXPORT );

=head1 NAME

Carp::Assert::More - Convenience assertions for common situations

=head1 VERSION

Version 2.9.0

=cut

our $VERSION = '2.9.0';
our @EXPORT = qw(
    assert
    assert_all_keys_in
    assert_and
    assert_aoh
    assert_arrayref
    assert_arrayref_nonempty
    assert_arrayref_nonempty_of
    assert_arrayref_of
    assert_arrayref_all
    assert_cmp
    assert_coderef
    assert_context_list
    assert_context_nonvoid
    assert_context_scalar
    assert_context_void
    assert_datetime
    assert_defined
    assert_empty
    assert_exists
    assert_fail
    assert_hashref
    assert_hashref_nonempty
    assert_in
    assert_integer
    assert_integer_between
    assert_is
    assert_isa
    assert_isa_in
    assert_isnt
    assert_keys_are
    assert_lacks
    assert_like
    assert_listref
    assert_negative
    assert_negative_integer
    assert_nonblank
    assert_nonempty
    assert_nonnegative
    assert_nonnegative_integer
    assert_nonref
    assert_nonzero
    assert_nonzero_integer
    assert_numeric
    assert_numeric_between
    assert_or
    assert_positive
    assert_positive_integer
    assert_regex
    assert_undefined
    assert_unlike
    assert_xor
);

my $INTEGER = qr/^-?\d+$/;

=head1 SYNOPSIS

A set of convenience functions for common assertions.

    use Carp::Assert::More;

    my $obj = My::Object;
    assert_isa( $obj, 'My::Object', 'Got back a correct object' );

=head1 DESCRIPTION

Carp::Assert::More is a convenient set of assertions to make the habit
of writing assertions even easier.

Everything in here is effectively syntactic sugar.  There's no technical
difference between calling one of these functions:

    assert_datetime( $foo );
    assert_isa( $foo, 'DateTime' );

that are provided by Carp::Assert::More and calling these assertions
from Carp::Assert

    assert( defined $foo );
    assert( ref($foo) eq 'DateTime' );

My intent here is to make common assertions easy so that we as programmers
have no excuse to not use them.

=head1 SIMPLE ASSERTIONS

=head2 assert( $condition [, $name] )

Asserts that C<$condition> is a true value.  This is the same as C<assert>
in C<Carp::Assert>, provided as a convenience.

=cut

sub assert($;$) {
    my $condition = shift;
    my $name = shift;

    return if $condition;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_is( $string, $match [,$name] )

Asserts that I<$string> is the same string value as I<$match>.

C<undef> is not converted to an empty string. If both strings are
C<undef>, they match. If only one string is C<undef>, they don't match.

=cut

sub assert_is($$;$) {
    my $string = shift;
    my $match = shift;
    my $name = shift;

    if ( defined($string) ) {
        return if defined($match) && ($string eq $match);
    }
    else {
        return if !defined($match);
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_isnt( $string, $unmatch [,$name] )

Asserts that I<$string> does NOT have the same string value as I<$unmatch>.

C<undef> is not converted to an empty string.

=cut

sub assert_isnt($$;$) {
    my $string = shift;
    my $unmatch = shift;
    my $name = shift;

    # undef only matches undef
    return if defined($string) xor defined($unmatch);

    return if defined($string) && defined($unmatch) && ($string ne $unmatch);

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_cmp( $x, $op, $y [,$name] )

Asserts that the relation C<$x $op $y> is true. It lets you know why
the comparsison failed, rather than simply that it did fail, by giving
better diagnostics than a plain C<assert()>, as well as showing the
operands in the stacktrace.

Plain C<assert()>:

    assert( $nitems <= 10, 'Ten items or fewer in the express lane' );

    Assertion (Ten items or fewer in the express lane) failed!
    Carp::Assert::assert("", "Ten items or fewer in the express lane") called at foo.pl line 12

With C<assert_cmp()>:

    assert_cmp( $nitems, '<=', 10, 'Ten items or fewer in the express lane' );

    Assertion (Ten items or fewer in the express lane) failed!
    Failed: 14 <= 10
    Carp::Assert::More::assert_cmp(14, "<=", 10, "Ten items or fewer in the express lane") called at foo.pl line 11

The following operators are supported:

=over 4

=item * == numeric equal

=item * != numeric not equal

=item * > numeric greater than

=item * >= numeric greater than or equal

=item * < numeric less than

=item * <= numeric less than or equal

=item * lt string less than

=item * le string less than or equal

=item * gt string less than

=item * ge string less than or equal

=back

There is no support for C<eq> or C<ne> because those already have
C<assert_is> and C<assert_isnt>, respectively.

If either C<$x> or C<$y> is undef, the assertion will fail.

If the operator is numeric, and C<$x> or C<$y> are not numbers, the assertion will fail.

=cut

sub assert_cmp($$$;$) {
    my $x    = shift;
    my $op   = shift;
    my $y    = shift;
    my $name = shift;

    my $why;

    if ( !defined($op) ) {
        $why = 'Invalid operator <undef>';
    }
    elsif ( $op eq '==' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x == $y);
    }
    elsif ( $op eq '!=' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x != $y);
    }
    elsif ( $op eq '<' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x < $y);
    }
    elsif ( $op eq '<=' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x <= $y);
    }
    elsif ( $op eq '>' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x > $y);
    }
    elsif ( $op eq '>=' ) {
        return if looks_like_number($x) && looks_like_number($y) && ($x >= $y);
    }
    elsif ( $op eq 'lt' ) {
        return if defined($x) && defined($y) && ($x lt $y);
    }
    elsif ( $op eq 'le' ) {
        return if defined($x) && defined($y) && ($x le $y);
    }
    elsif ( $op eq 'gt' ) {
        return if defined($x) && defined($y) && ($x gt $y);
    }
    elsif ( $op eq 'ge' ) {
        return if defined($x) && defined($y) && ($x ge $y);
    }
    else {
        $why = qq{Invalid operator "$op"};
    }

    $why //= "Failed: " . ($x // 'undef') . ' ' . $op . ' ' . ($y // 'undef');

    require Carp;
    &Carp::confess( _failure_msg($name, $why) );
}


=head2 assert_like( $string, qr/regex/ [,$name] )

Asserts that I<$string> matches I<qr/regex/>.

The assertion fails either the string or the regex are undef.

=cut

sub assert_like($$;$) {
    my $string = shift;
    my $regex = shift;
    my $name = shift;

    if ( defined($string) && !ref($string) ) {
        if ( ref($regex) ) {
            return if $string =~ $regex;
        }
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_unlike( $string, qr/regex/ [,$name] )

Asserts that I<$string> matches I<qr/regex/>.

The assertion fails if the regex is undef.

=cut

sub assert_unlike($$;$) {
    my $string = shift;
    my $regex  = shift;
    my $name   = shift;

    return if !defined($string);

    if ( ref($regex) eq 'Regexp' ) {
        return if $string !~ $regex;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_defined( $this [, $name] )

Asserts that I<$this> is defined.

=cut

sub assert_defined($;$) {
    return if defined( $_[0] );

    require Carp;
    &Carp::confess( _failure_msg($_[1]) );
}


=head2 assert_undefined( $this [, $name] )

Asserts that I<$this> is not defined.

=cut

sub assert_undefined($;$) {
    return unless defined( $_[0] );

    require Carp;
    &Carp::confess( _failure_msg($_[1]) );
}

=head2 assert_nonblank( $this [, $name] )

Asserts that I<$this> is not a reference and is not an empty string.

=cut

sub assert_nonblank($;$) {
    my $this = shift;
    my $name = shift;

    my $why;
    if ( !defined($this) ) {
        $why = 'Value is undef.';
    }
    else {
        if ( ref($this) ) {
            $why = 'Value is a reference to ' . ref($this) . '.';
        }
        else {
            return if $this ne '';
            $why = 'Value is blank.';
        }
    }

    require Carp;
    &Carp::confess( _failure_msg($name, $why) );
}


=head1 BOOLEAN ASSERTIONS

These boolean assertions help make diagnostics more useful.

If you use C<assert> with a boolean condition:

    assert( $x && $y, 'Both X and Y should be true' );

you can't tell why it failed:

    Assertion (Both X and Y should be true) failed!
     at .../Carp/Assert/More.pm line 123
            Carp::Assert::More::assert(undef, 'Both X and Y should be true') called at foo.pl line 16

But if you use C<assert_and>:

    assert_and( $x, $y, 'Both X and Y should be true' );

the stacktrace tells you which half of the expression failed.

    Assertion (Both X and Y should be true) failed!
     at .../Carp/Assert/More.pm line 123
            Carp::Assert::More::assert_and('thing', undef, 'Both X and Y should be true') called at foo.pl line 16

=head2 assert_and( $x, $y [, $name] )

Asserts that both C<$x> and C<$y> are true.

=cut

sub assert_and($$;$) {
    my $x    = shift;
    my $y    = shift;
    my $name = shift;

    return if $x && $y;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_or( $x, $y [, $name] )

Asserts that at least one of C<$x> or C<$y> are true.

=cut

sub assert_or($$;$) {
    my $x    = shift;
    my $y    = shift;
    my $name = shift;

    return if $x || $y;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}

=head2 assert_xor( $x, $y [, $name] )

Asserts that C<$x> is true, or C<$y> is true, but not both.

=cut

sub assert_xor($$;$) {
    my $x    = shift;
    my $y    = shift;
    my $name = shift;

    return if $x && !$y;
    return if $y && !$x;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head1 NUMERIC ASSERTIONS

=head2 assert_numeric( $n [, $name] )

Asserts that C<$n> looks like a number, according to C<Scalar::Util::looks_like_number>.
C<undef> will always fail.

=cut

sub assert_numeric {
    my $n    = shift;
    my $name = shift;

    return if Scalar::Util::looks_like_number( $n );

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_integer( $this [, $name ] )

Asserts that I<$this> is an integer, which may be zero or negative.

    assert_integer( 0 );      # pass
    assert_integer( 14 );     # pass
    assert_integer( -14 );    # pass
    assert_integer( '14.' );  # FAIL

=cut

sub assert_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) ) {
        return if $this =~ $INTEGER;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_nonzero( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined and is not zero.

    assert_nonzero( 0 );    # FAIL
    assert_nonzero( -14 );  # pass
    assert_nonzero( '14.' );  # pass

=cut

sub assert_nonzero($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number($this) ) {
        return if $this != 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_positive( $this [, $name ] )

Asserts that I<$this> is defined, numeric and greater than zero.

    assert_positive( 0 );    # FAIL
    assert_positive( -14 );  # FAIL
    assert_positive( '14.' );  # pass

=cut

sub assert_positive($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number($this) ) {
        return if ($this+0 > 0);
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_nonnegative( $this [, $name ] )

Asserts that I<$this> is defined, numeric and greater than or equal
to zero.

    assert_nonnegative( 0 );      # pass
    assert_nonnegative( -14 );    # FAIL
    assert_nonnegative( '14.' );  # pass
    assert_nonnegative( 'dog' );  # pass

=cut

sub assert_nonnegative($;$) {
    my $this = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number( $this ) ) {
        return if $this >= 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_negative( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined and less than zero.

    assert_negative( 0 );       # FAIL
    assert_negative( -14 );     # pass
    assert_negative( '14.' );   # FAIL

=cut

sub assert_negative($;$) {
    my $this = shift;
    my $name = shift;

    no warnings;
    return if defined($this) && ($this+0 < 0);

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_nonzero_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and not zero.

    assert_nonzero_integer( 0 );      # FAIL
    assert_nonzero_integer( -14 );    # pass
    assert_nonzero_integer( '14.' );  # FAIL

=cut

sub assert_nonzero_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this != 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_positive_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer and greater than zero.

    assert_positive_integer( 0 );     # FAIL
    assert_positive_integer( -14 );   # FAIL
    assert_positive_integer( '14.' ); # FAIL
    assert_positive_integer( '14' );  # pass

=cut

sub assert_positive_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this > 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_nonnegative_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and not less than zero.

    assert_nonnegative_integer( 0 );      # pass
    assert_nonnegative_integer( -14 );    # FAIL
    assert_nonnegative_integer( '14.' );  # FAIL

=cut

sub assert_nonnegative_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this >= 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_negative_integer( $this [, $name ] )

Asserts that the numeric value of I<$this> is defined, an integer, and less than zero.

    assert_negative_integer( 0 );      # FAIL
    assert_negative_integer( -14 );    # pass
    assert_negative_integer( '14.' );  # FAIL

=cut

sub assert_negative_integer($;$) {
    my $this = shift;
    my $name = shift;

    if ( defined($this) && ($this =~ $INTEGER) ) {
        return if $this < 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_numeric_between( $n, $lo, $hi [, $name ] )

Asserts that the value of I<$this> is defined, numeric and between C<$lo>
and C<$hi>, inclusive.

    assert_numeric_between( 15, 10, 100 );  # pass
    assert_numeric_between( 10, 15, 100 );  # FAIL
    assert_numeric_between( 3.14, 1, 10 );  # pass

=cut

sub assert_numeric_between($$$;$) {
    my $n    = shift;
    my $lo   = shift;
    my $hi   = shift;
    my $name = shift;

    if ( Scalar::Util::looks_like_number( $n ) ) {
        return if $lo <= $n && $n <= $hi;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_integer_between( $n, $lo, $hi [, $name ] )

Asserts that the value of I<$this> is defined, an integer, and between C<$lo>
and C<$hi>, inclusive.

    assert_integer_between( 15, 10, 100 );  # pass
    assert_integer_between( 10, 15, 100 );  # FAIL
    assert_integer_between( 3.14, 1, 10 );  # FAIL

=cut

sub assert_integer_between($$$;$) {
    my $n    = shift;
    my $lo   = shift;
    my $hi   = shift;
    my $name = shift;

    if ( defined($n) && $n =~ $INTEGER ) {
        return if $lo <= $n && $n <= $hi;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head1 REFERENCE ASSERTIONS

=head2 assert_isa( $this, $type [, $name ] )

Asserts that I<$this> is an object of type I<$type>.

=cut

sub assert_isa($$;$) {
    my $this = shift;
    my $type = shift;
    my $name = shift;

    # The assertion is true if
    # 1) For objects, $this is of class $type or of a subclass of $type
    # 2) For non-objects, $this is a reference to a HASH, SCALAR, ARRAY, etc.

    return if Scalar::Util::blessed( $this ) && $this->isa( $type );
    return if ref($this) eq $type;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_isa_in( $obj, \@types [, $description] )

Assert that the blessed C<$obj> isa one of the types in C<\@types>.

    assert_isa_in( $obj, [ 'My::Foo', 'My::Bar' ], 'Must pass either a Foo or Bar object' );

=cut

sub assert_isa_in($$;$) {
    my $obj   = shift;
    my $types = shift;
    my $name  = shift;

    if ( Scalar::Util::blessed($obj) ) {
        for ( @{$types} ) {
            return if $obj->isa($_);
        }
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_empty( $this [, $name ] )

I<$this> must be a ref to either a hash or an array.  Asserts that that
collection contains no elements.  Will assert (with its own message,
not I<$name>) unless given a hash or array ref.   It is OK if I<$this> has
been blessed into objecthood, but the semantics of checking an object to see
if it does not have keys (for a hashref) or returns 0 in scalar context (for
an array ref) may not be what you want.

    assert_empty( 0 );       # FAIL
    assert_empty( 'foo' );   # FAIL
    assert_empty( undef );   # FAIL
    assert_empty( {} );      # pass
    assert_empty( [] );      # pass
    assert_empty( {foo=>1} );# FAIL
    assert_empty( [1,2,3] ); # FAIL

=cut

sub assert_empty($;$) {
    my $ref = shift;
    my $name = shift;

    my $underlying_type;
    if ( Scalar::Util::blessed( $ref ) ) {
        $underlying_type = Scalar::Util::reftype( $ref );
    }
    else {
        $underlying_type = ref( $ref );
    }

    my $why;
    my $n;
    if ( $underlying_type eq 'HASH' ) {
        return if scalar keys %{$ref} == 0;
        $n = scalar keys %{$ref};
        $why = "Hash contains $n key";
    }
    elsif ( $underlying_type eq 'ARRAY' ) {
        return if @{$ref} == 0;
        $n = scalar @{$ref};
        $why = "Array contains $n element";
    }
    else {
        $why = 'Argument is not a hash or array.';
    }

    $why .= 's' if $n && ($n>1);
    $why .= '.';

    require Carp;
    &Carp::confess( _failure_msg($name, $why) );
}


=head2 assert_nonempty( $this [, $name ] )

I<$this> must be a ref to either a hash or an array.  Asserts that that
collection contains at least 1 element.  Will assert (with its own message,
not I<$name>) unless given a hash or array ref.   It is OK if I<$this> has
been blessed into objecthood, but the semantics of checking an object to see
if it has keys (for a hashref) or returns >0 in scalar context (for an array
ref) may not be what you want.

    assert_nonempty( 0 );       # FAIL
    assert_nonempty( 'foo' );   # FAIL
    assert_nonempty( undef );   # FAIL
    assert_nonempty( {} );      # FAIL
    assert_nonempty( [] );      # FAIL
    assert_nonempty( {foo=>1} );# pass
    assert_nonempty( [1,2,3] ); # pass

=cut

sub assert_nonempty($;$) {
    my $ref = shift;
    my $name = shift;

    my $underlying_type;
    if ( Scalar::Util::blessed( $ref ) ) {
        $underlying_type = Scalar::Util::reftype( $ref );
    }
    else {
        $underlying_type = ref( $ref );
    }

    my $why;
    my $n;
    if ( $underlying_type eq 'HASH' ) {
        return if scalar keys %{$ref} > 0;
        $why = "Hash contains 0 keys.";
    }
    elsif ( $underlying_type eq 'ARRAY' ) {
        return if scalar @{$ref} > 0;
        $why = "Array contains 0 elements.";
    }
    else {
        $why = 'Argument is not a hash or array.';
    }

    require Carp;
    &Carp::confess( _failure_msg($name, $why) );
}


=head2 assert_nonref( $this [, $name ] )

Asserts that I<$this> is not undef and not a reference.

=cut

sub assert_nonref($;$) {
    my $this = shift;
    my $name = shift;

    assert_defined( $this, $name );
    return unless ref( $this );

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_hashref( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to a (possibly empty) hash.

B<NB:> This method returns I<false> for objects, even those whose underlying
data is a hashref. This is as it should be, under the assumptions that:

=over 4

=item (a)

you shouldn't rely on the underlying data structure of a particular class, and

=item (b)

you should use C<assert_isa> instead.

=back

=cut

sub assert_hashref($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'HASH' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'HASH' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_hashref_nonempty( $ref [,$name] )

Asserts that I<$ref> is defined and is a reference to a hash with at
least one key/value pair.

=cut

sub assert_hashref_nonempty($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'HASH' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'HASH' )) ) {
        return if scalar keys %{$ref} > 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_arrayref( $ref [, $name] )

=head2 assert_listref( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to an array, which
may or may not be empty.

B<NB:> The same caveat about objects whose underlying structure is a
hash (see C<assert_hashref>) applies here; this method returns false
even for objects whose underlying structure is an array.

C<assert_listref> is an alias for C<assert_arrayref> and may go away in
the future.  Use C<assert_arrayref> instead.

=cut

sub assert_arrayref($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}
*assert_listref = *assert_arrayref;


=head2 assert_arrayref_nonempty( $ref [, $name] )

Asserts that I<$ref> is reference to an array that has at least one element in it.

=cut

sub assert_arrayref_nonempty($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        return if scalar @{$ref} > 0;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_arrayref_of( $ref, $type [, $name] )

Asserts that I<$ref> is reference to an array, and any/all elements are
of type I<$type>.

For example:

    my @users = get_users();
    assert_arrayref_of( \@users, 'My::User' );

=cut

sub assert_arrayref_of($$;$) {
    my $ref  = shift;
    my $type = shift;
    my $name = shift;

    my $ok;
    my @why;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        my $n = 0;
        for my $i ( @{$ref} ) {
            if ( !( ( Scalar::Util::blessed( $i ) && $i->isa( $type ) ) || (ref($i) eq $type) ) ) {
                push @why, "Element #$n is not of type $type";
            }
            ++$n;
        }
        $ok = !@why;
    }

    if ( !$ok ) {
        require Carp;
        &Carp::confess( _failure_msg($name), @why );
    }

    return;
}


=head2 assert_arrayref_nonempty_of( $ref, $type [, $name] )

Asserts that I<$ref> is reference to an array, that it has at least one
element, and that all elements are of type I<$type>.

This is the same function as C<assert_arrayref_of>, except that it also
requires at least one element.

=cut

sub assert_arrayref_nonempty_of($$;$) {
    my $ref  = shift;
    my $type = shift;
    my $name = shift;

    my $ok;
    my @why;

    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        if ( scalar @{$ref} > 0 ) {
            my $n = 0;
            for my $i ( @{$ref} ) {
                if ( !( ( Scalar::Util::blessed( $i ) && $i->isa( $type ) ) || (ref($i) eq $type) ) ) {
                    push @why, "Element #$n is not of type $type";
                }
                ++$n;
            }
            $ok = !@why;
        }
        else {
            push @why, 'Array contains no elements';
        }
    }

    if ( !$ok ) {
        require Carp;
        &Carp::confess( _failure_msg($name), @why );
    }

    return;
}


=head2 assert_arrayref_all( $aref, $sub [, $name] )

Asserts that I<$aref> is reference to an array that has at least one
element in it. Each element of the array is passed to subroutine I<$sub>
which is assumed to be an assertion.

For example:

    my $aref_of_counts = get_counts();
    assert_arrayref_all( $aref, \&assert_positive_integer, 'Counts are positive' );

Whatever is passed as I<$name>, a string saying "Element #N" will be
appended, where N is the zero-based index of the array.

=cut

sub assert_arrayref_all($$;$) {
    my $aref = shift;
    my $sub  = shift;
    my $name = shift;

    my @why;

    assert_coderef( $sub, 'assert_arrayref_all requires a code reference' );

    if ( ref($aref) eq 'ARRAY' || (Scalar::Util::blessed( $aref ) && $aref->isa( 'ARRAY' )) ) {
        if ( @{$aref} ) {
            my $inner_msg = defined($name) ? "$name: " : 'assert_arrayref_all: ';
            my $n = 0;
            for my $i ( @{$aref} ) {
                $sub->( $i, "${inner_msg}Element #$n" );
                ++$n;
            }
        }
        else {
            push @why, 'Array contains no elements';
        }
    }
    else {
        push @why, 'First argument to assert_arrayref_all was not an array';
    }

    if ( @why ) {
        require Carp;
        &Carp::confess( _failure_msg($name), @why );
    }

    return;
}


=head2 assert_aoh( $ref [, $name ] )

Verifies that C<$array> is an arrayref, and that every element is a hashref.

The array C<$array> can be an empty arraref and the assertion will pass.

=cut

sub assert_aoh {
    my $ref  = shift;
    my $name = shift;

    my $ok = 0;
    if ( ref($ref) eq 'ARRAY' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'ARRAY' )) ) {
        $ok = 1;
        for my $val ( @{$ref} ) {
            if ( not ( ref($val) eq 'HASH' || (Scalar::Util::blessed( $val) && $val->isa( 'HASH' )) ) ) {
                $ok = 0;
                last;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_coderef( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to a closure.

=cut

sub assert_coderef($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'CODE' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'CODE' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_regex( $ref [,$name] )

Asserts that I<$ref> is defined, and is a reference to a regex.

It is functionally the same as C<assert_isa( $ref, 'Regexp' )>.

=cut

sub assert_regex($;$) {
    my $ref = shift;
    my $name = shift;

    if ( ref($ref) eq 'Regexp' ) {
        return;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head1 TYPE-SPECIFIC ASSERTIONS

=head2 assert_datetime( $date )

Asserts that C<$date> is a DateTime object.

=cut

sub assert_datetime($;$) {
    my $ref  = shift;
    my $name = shift;

    if ( ref($ref) eq 'DateTime' || (Scalar::Util::blessed( $ref ) && $ref->isa( 'DateTime' )) ) {
        return;
    }

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head1 SET AND HASH MEMBERSHIP

=head2 assert_in( $string, \@inlist [,$name] );

Asserts that I<$string> matches one of the elements of I<\@inlist>.
I<$string> may be undef.

I<\@inlist> must be an array reference of non-ref strings.  If any
element is a reference, the assertion fails.

=cut

sub assert_in($$;$) {
    my $needle = shift;
    my $haystack = shift;
    my $name = shift;

    my $found = 0;

    # String has to be a non-ref scalar, or undef.
    if ( !ref($needle) ) {

        # Target list has to be an array...
        if ( ref($haystack) eq 'ARRAY' || (Scalar::Util::blessed( $haystack ) && $haystack->isa( 'ARRAY' )) ) {

            # ... and all elements have to be non-refs.
            my $elements_ok = 1;
            foreach my $element (@{$haystack}) {
                if ( ref($element) ) {
                    $elements_ok = 0;
                    last;
                }
            }

            # Now we can actually do the search.
            if ( $elements_ok ) {
                if ( defined($needle) ) {
                    foreach my $element (@{$haystack}) {
                        if ( $needle eq $element ) {
                            $found = 1;
                            last;
                        }
                    }
                }
                else {
                    foreach my $element (@{$haystack}) {
                        if ( !defined($element) ) {
                            $found = 1;
                            last;
                        }
                    }
                }
            }
        }
    }

    return if $found;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_exists( \%hash, $key [,$name] )

=head2 assert_exists( \%hash, \@keylist [,$name] )

Asserts that I<%hash> is indeed a hash, and that I<$key> exists in
I<%hash>, or that all of the keys in I<@keylist> exist in I<%hash>.

    assert_exists( \%custinfo, 'name', 'Customer has a name field' );

    assert_exists( \%custinfo, [qw( name addr phone )],
                            'Customer has name, address and phone' );

=cut

sub assert_exists($$;$) {
    my $hash = shift;
    my $key = shift;
    my $name = shift;

    my $ok = 0;

    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( defined($key) ) {
            if ( ref($key) eq 'ARRAY' ) {
                $ok = (@{$key} > 0);
                for ( @{$key} ) {
                    if ( !exists( $hash->{$_} ) ) {
                        $ok = 0;
                        last;
                    }
                }
            }
            elsif ( !ref($key) ) {
                $ok = exists( $hash->{$key} );
            }
            else {
                $ok = 0;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_lacks( \%hash, $key [,$name] )

=head2 assert_lacks( \%hash, \@keylist [,$name] )

Asserts that I<%hash> is indeed a hash, and that I<$key> does NOT exist
in I<%hash>, or that none of the keys in I<@keylist> exist in I<%hash>.
The list C<@keylist> cannot be empty.

    assert_lacks( \%users, 'root', 'Root is not in the user table' );

    assert_lacks( \%users, [qw( root admin nobody )], 'No bad usernames found' );

=cut

sub assert_lacks($$;$) {
    my $hash = shift;
    my $key = shift;
    my $name = shift;

    my $ok = 0;

    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( defined($key) ) {
            if ( ref($key) eq 'ARRAY' ) {
                $ok = (@{$key} > 0);
                for ( @{$key} ) {
                    if ( exists( $hash->{$_} ) ) {
                        $ok = 0;
                        last;
                    }
                }
            }
            elsif ( !ref($key) ) {
                $ok = !exists( $hash->{$key} );
            }
            else {
                $ok = 0;
            }
        }
    }

    return if $ok;

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_all_keys_in( \%hash, \@names [, $name ] )

Asserts that each key in C<%hash> is in the list of C<@names>.

This is used to ensure that there are no extra keys in a given hash.

    assert_all_keys_in( $obj, [qw( height width depth )], '$obj can only contain height, width and depth keys' );

You can pass an empty list of C<@names>.

=cut

sub assert_all_keys_in($$;$) {
    my $hash = shift;
    my $keys = shift;
    my $name = shift;

    my @why;
    my $ok = 0;
    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( ref($keys) eq 'ARRAY' ) {
            $ok = 1;
            my %keys = map { $_ => 1 } @{$keys};
            for my $key ( keys %{$hash} ) {
                if ( !exists $keys{$key} ) {
                    $ok = 0;
                    push @why, qq{Key "$key" is not a valid key.};
                }
            }
        }
        else {
            push @why, 'Argument for array of keys is not an arrayref.';
        }
    }
    else {
        push @why, 'Argument for hash is not a hashref.';
    }

    return if $ok;

    require Carp;
    &Carp::confess( _failure_msg($name, @why) );
}


=head2 assert_keys_are( \%hash, \@keys [, $name ] )

Asserts that the keys for C<%hash> are exactly C<@keys>, no more and no less.

=cut

sub assert_keys_are($$;$) {
    my $hash = shift;
    my $keys = shift;
    my $name = shift;

    my @why;
    my $ok = 0;
    if ( ref($hash) eq 'HASH' || (Scalar::Util::blessed( $hash ) && $hash->isa( 'HASH' )) ) {
        if ( ref($keys) eq 'ARRAY' ) {
            my %keys = map { $_ => 1 } @{$keys};

            # First check all the keys are allowed.
            $ok = 1;
            for my $key ( keys %{$hash} ) {
                if ( !exists $keys{$key} ) {
                    $ok = 0;
                    push @why, qq{Key "$key" is not a valid key.};
                }
            }

            # Now check that all the valid keys are represented.
            for my $key ( @{$keys} ) {
                if ( !exists $hash->{$key} ) {
                    $ok = 0;
                    push @why, qq{Key "$key" is not in the hash.};
                }
            }
        }
        else {
            push @why, 'Argument for array of keys is not an arrayref.';
        }
    }
    else {
        push @why, 'Argument for hash is not a hashref.';
    }

    return if $ok;

    require Carp;
    &Carp::confess( _failure_msg($name, @why) );
}


=head1 CONTEXT ASSERTIONS

=head2 assert_context_nonvoid( [$name] )

Verifies that the function currently being executed has not been called
in void context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_nonvoid();

        return $important_value;
    }

These calls to C<something> will pass:

    my $val = something();
    my @things = something();

but this will fail:

    something();

If the C<$name> argument is not passed, a default message of "<funcname>
must not be called in void context" is provided.

=cut

sub assert_context_nonvoid(;$) {
    my (undef, undef, undef, $subroutine, undef, $wantarray) = caller(1);

    return if defined($wantarray);

    my $name = $_[0] // "$subroutine must not be called in void context";

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_context_void( [$name] )

Verifies that the function currently being executed has been called
in void context.  This is for functions that do not return anything
meaningful.

Given this function:

    sub something {
        ...

        assert_context_void();

        return; # No meaningful value.
    }

These calls to C<something> will fail:

    my $val = something();
    my @things = something();

but this will pass:

    something();

If the C<$name> argument is not passed, a default message of "<funcname>
must be called in void context" is provided.

=cut

sub assert_context_void(;$) {
    my (undef, undef, undef, $subroutine, undef, $wantarray) = caller(1);

    return if not defined($wantarray);

    my $name = $_[0] // "$subroutine must be called in void context";

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_context_scalar( [$name] )

Verifies that the function currently being executed has been called in
scalar context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return $important_value;
    }

This call to C<something> will pass:

    my $val = something();

but these will fail:

    something();
    my @things = something();

If the C<$name> argument is not passed, a default message of "<funcname>
must be called in scalar context" is provided.

=cut

sub assert_context_scalar(;$) {
    my (undef, undef, undef, $subroutine, undef, $wantarray) = caller(1);

    return if defined($wantarray) && !$wantarray;

    my $name = $_[0] // "$subroutine must be called in scalar context";

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head2 assert_context_list( [$name] )

Verifies that the function currently being executed has been called in
list context.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return @values;
    }

This call to C<something> will pass:

    my @vals = something();

but these will fail:

    something();
    my $thing = something();

If the C<$name> argument is not passed, a default message of "<funcname>
must be called in list context" is provided.

=cut

sub assert_context_list(;$) {
    my (undef, undef, undef, $subroutine, undef, $wantarray) = caller(1);

    return if $wantarray;

    my $name = shift // "$subroutine must be called in list context";

    require Carp;
    &Carp::confess( _failure_msg($name) );
}


=head1 UTILITY ASSERTIONS

=head2 assert_fail( [$name] )

Assertion that always fails.  C<assert_fail($msg)> is exactly the same
as calling C<assert(0,$msg)>, but it eliminates that case where you
accidentally use C<assert($msg)>, which of course never fires.

=cut

sub assert_fail(;$) {
    require Carp;
    &Carp::confess( _failure_msg($_[0]) );
}


# Can't call confess() here or the stack trace will be wrong.
sub _failure_msg {
    my ($name, @why) = @_;

    my $msg = 'Assertion';
    $msg   .= " ($name)" if defined $name;
    $msg   .= " failed!\n";
    $msg   .= "$_\n" for @why;

    return $msg;
}


=head1 COPYRIGHT & LICENSE

Copyright 2005-2025 Andy Lester

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=head1 ACKNOWLEDGEMENTS

Thanks to
Eric A. Zarko,
Bob Diss,
Pete Krawczyk,
David Storrs,
Dan Friedman,
Allard Hoeve,
Thomas L. Shinnick,
and Leland Johnson
for code and fixes.

=cut

1;
