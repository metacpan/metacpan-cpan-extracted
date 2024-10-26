# Carp::Assert::More

[![Build Status](https://github.com/petdance/carp-assert-more/workflows/testsuite/badge.svg?branch=dev)](https://github.com/petdance/carp-assert-more/actions?query=workflow%3Atestsuite+branch%3Adev)

# NAME

Carp::Assert::More - Convenience assertions for common situations

# VERSION

Version 2.4.0

# SYNOPSIS

A set of convenience functions for common assertions.

    use Carp::Assert::More;

    my $obj = My::Object;
    assert_isa( $obj, 'My::Object', 'Got back a correct object' );

# DESCRIPTION

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

# SIMPLE ASSERTIONS

## assert\_is( $string, $match \[,$name\] )

Asserts that _$string_ is the same string value as _$match_.

`undef` is not converted to an empty string. If both strings are
`undef`, they match. If only one string is `undef`, they don't match.

## assert\_isnt( $string, $unmatch \[,$name\] )

Asserts that _$string_ does NOT have the same string value as _$unmatch_.

`undef` is not converted to an empty string.

## assert\_cmp( $x, $op, $y \[,$name\] )

Asserts that the relation `$x $op $y` is true. It lets you know why
the comparsison failed, rather than simply that it did fail, by giving
better diagnostics than a plain `assert()`, as well as showing the
operands in the stacktrace.

Plain `assert()`:

    assert( $nitems <= 10, 'Ten items or fewer in the express lane' );

    Assertion (Ten items or fewer in the express lane) failed!
    Carp::Assert::assert("", "Ten items or fewer in the express lane") called at foo.pl line 12

With `assert_cmp()`:

    assert_cmp( $nitems, '<=', 10, 'Ten items or fewer in the express lane' );

    Assertion (Ten items or fewer in the express lane) failed!
    Failed: 14 <= 10
    Carp::Assert::More::assert_cmp(14, "<=", 10, "Ten items or fewer in the express lane") called at foo.pl line 11

The following operators are supported:

- == numeric equal
- != numeric not equal
- > numeric greater than
- >= numeric greater than or equal
- < numeric less than
- <= numeric less than or equal
- lt string less than
- le string less than or equal
- gt string less than
- ge string less than or equal

There is no support for `eq` or `ne` because those already have
`assert_is` and `assert_isnt`, respectively.

If either `$x` or `$y` is undef, the assertion will fail.

If the operator is numeric, and `$x` or `$y` are not numbers, the assertion will fail.

## assert\_like( $string, qr/regex/ \[,$name\] )

Asserts that _$string_ matches _qr/regex/_.

The assertion fails either the string or the regex are undef.

## assert\_unlike( $string, qr/regex/ \[,$name\] )

Asserts that _$string_ matches _qr/regex/_.

The assertion fails if the regex is undef.

## assert\_defined( $this \[, $name\] )

Asserts that _$this_ is defined.

## assert\_undefined( $this \[, $name\] )

Asserts that _$this_ is not defined.

## assert\_nonblank( $this \[, $name\] )

Asserts that _$this_ is not a reference and is not an empty string.

# NUMERIC ASSERTIONS

## assert\_numeric( $n \[, $name\] )

Asserts that `$n` looks like a number, according to `Scalar::Util::looks_like_number`.
`undef` will always fail.

## assert\_integer( $this \[, $name \] )

Asserts that _$this_ is an integer, which may be zero or negative.

    assert_integer( 0 );      # pass
    assert_integer( 14 );     # pass
    assert_integer( -14 );    # pass
    assert_integer( '14.' );  # FAIL

## assert\_nonzero( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined and is not zero.

    assert_nonzero( 0 );    # FAIL
    assert_nonzero( -14 );  # pass
    assert_nonzero( '14.' );  # pass

## assert\_positive( $this \[, $name \] )

Asserts that _$this_ is defined, numeric and greater than zero.

    assert_positive( 0 );    # FAIL
    assert_positive( -14 );  # FAIL
    assert_positive( '14.' );  # pass

## assert\_nonnegative( $this \[, $name \] )

Asserts that _$this_ is defined, numeric and greater than or equal
to zero.

    assert_nonnegative( 0 );      # pass
    assert_nonnegative( -14 );    # FAIL
    assert_nonnegative( '14.' );  # pass
    assert_nonnegative( 'dog' );  # pass

## assert\_negative( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined and less than zero.

    assert_negative( 0 );       # FAIL
    assert_negative( -14 );     # pass
    assert_negative( '14.' );   # FAIL

## assert\_nonzero\_integer( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined, an integer, and not zero.

    assert_nonzero_integer( 0 );      # FAIL
    assert_nonzero_integer( -14 );    # pass
    assert_nonzero_integer( '14.' );  # FAIL

## assert\_positive\_integer( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined, an integer and greater than zero.

    assert_positive_integer( 0 );     # FAIL
    assert_positive_integer( -14 );   # FAIL
    assert_positive_integer( '14.' ); # FAIL
    assert_positive_integer( '14' );  # pass

## assert\_nonnegative\_integer( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined, an integer, and not less than zero.

    assert_nonnegative_integer( 0 );      # pass
    assert_nonnegative_integer( -14 );    # FAIL
    assert_nonnegative_integer( '14.' );  # FAIL

## assert\_negative\_integer( $this \[, $name \] )

Asserts that the numeric value of _$this_ is defined, an integer, and less than zero.

    assert_negative_integer( 0 );      # FAIL
    assert_negative_integer( -14 );    # pass
    assert_negative_integer( '14.' );  # FAIL

# REFERENCE ASSERTIONS

## assert\_isa( $this, $type \[, $name \] )

Asserts that _$this_ is an object of type _$type_.

## assert\_isa\_in( $obj, \\@types \[, $description\] )

Assert that the blessed `$obj` isa one of the types in `\@types`.

    assert_isa_in( $obj, [ 'My::Foo', 'My::Bar' ], 'Must pass either a Foo or Bar object' );

## assert\_empty( $this \[, $name \] )

_$this_ must be a ref to either a hash or an array.  Asserts that that
collection contains no elements.  Will assert (with its own message,
not _$name_) unless given a hash or array ref.   It is OK if _$this_ has
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

## assert\_nonempty( $this \[, $name \] )

_$this_ must be a ref to either a hash or an array.  Asserts that that
collection contains at least 1 element.  Will assert (with its own message,
not _$name_) unless given a hash or array ref.   It is OK if _$this_ has
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

## assert\_nonref( $this \[, $name \] )

Asserts that _$this_ is not undef and not a reference.

## assert\_hashref( $ref \[,$name\] )

Asserts that _$ref_ is defined, and is a reference to a (possibly empty) hash.

**NB:** This method returns _false_ for objects, even those whose underlying
data is a hashref. This is as it should be, under the assumptions that:

- (a)

    you shouldn't rely on the underlying data structure of a particular class, and

- (b)

    you should use `assert_isa` instead.

## assert\_hashref\_nonempty( $ref \[,$name\] )

Asserts that _$ref_ is defined and is a reference to a hash with at
least one key/value pair.

## assert\_arrayref( $ref \[, $name\] )

## assert\_listref( $ref \[,$name\] )

Asserts that _$ref_ is defined, and is a reference to an array, which
may or may not be empty.

**NB:** The same caveat about objects whose underlying structure is a
hash (see `assert_hashref`) applies here; this method returns false
even for objects whose underlying structure is an array.

`assert_listref` is an alias for `assert_arrayref` and may go away in
the future.  Use `assert_arrayref` instead.

## assert\_arrayref\_nonempty( $ref \[, $name\] )

Asserts that _$ref_ is reference to an array that has at least one element in it.

## assert\_arrayref\_of( $ref, $type \[, $name\] )

Asserts that _$ref_ is reference to an array that has at least one
element in it, and every one of those elements is of type _$type_.

For example:

    my @users = get_users();
    assert_arrayref_of( \@users, 'My::User' );

## assert\_arrayref\_all( $aref, $sub \[, $name\] )

Asserts that _$aref_ is reference to an array that has at least one
element in it. Each element of the array is passed to subroutine _$sub_
which is assumed to be an assertion.

For example:

    my $aref_of_counts = get_counts();
    assert_arrayref_all( $aref, \&assert_positive_integer, 'Counts are positive' );

Whatever is passed as _$name_, a string saying "Element #N" will be
appended, where N is the zero-based index of the array.

## assert\_aoh( $ref \[, $name \] )

Verifies that `$array` is an arrayref, and that every element is a hashref.

The array `$array` can be an empty arraref and the assertion will pass.

## assert\_coderef( $ref \[,$name\] )

Asserts that _$ref_ is defined, and is a reference to a closure.

# TYPE-SPECIFIC ASSERTIONS

## assert\_datetime( $date )

Asserts that `$date` is a DateTime object.

# SET AND HASH MEMBERSHIP

## assert\_in( $string, \\@inlist \[,$name\] );

Asserts that _$string_ matches one of the elements of _\\@inlist_.
_$string_ may be undef.

_\\@inlist_ must be an array reference of non-ref strings.  If any
element is a reference, the assertion fails.

## assert\_exists( \\%hash, $key \[,$name\] )

## assert\_exists( \\%hash, \\@keylist \[,$name\] )

Asserts that _%hash_ is indeed a hash, and that _$key_ exists in
_%hash_, or that all of the keys in _@keylist_ exist in _%hash_.

    assert_exists( \%custinfo, 'name', 'Customer has a name field' );

    assert_exists( \%custinfo, [qw( name addr phone )],
                            'Customer has name, address and phone' );

## assert\_lacks( \\%hash, $key \[,$name\] )

## assert\_lacks( \\%hash, \\@keylist \[,$name\] )

Asserts that _%hash_ is indeed a hash, and that _$key_ does NOT exist
in _%hash_, or that none of the keys in _@keylist_ exist in _%hash_.
The list `@keylist` cannot be empty.

    assert_lacks( \%users, 'root', 'Root is not in the user table' );

    assert_lacks( \%users, [qw( root admin nobody )], 'No bad usernames found' );

## assert\_all\_keys\_in( \\%hash, \\@names \[, $name \] )

Asserts that each key in `%hash` is in the list of `@names`.

This is used to ensure that there are no extra keys in a given hash.

    assert_all_keys_in( $obj, [qw( height width depth )], '$obj can only contain height, width and depth keys' );

You can pass an empty list of `@names`.

## assert\_keys\_are( \\%hash, \\@keys \[, $name \] )

Asserts that the keys for `%hash` are exactly `@keys`, no more and no less.

# CONTEXT ASSERTIONS

## assert\_context\_nonvoid( \[$name\] )

Verifies that the function currently being executed has not been called
in void context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return $important_value;
    }

These calls to `something` will pass:

    my $val = something();
    my @things = something();

but this will fail:

    something();

If the `$name` argument is not passed, a default message of "&lt;funcname>
must not be called in void context" is provided.

## assert\_context\_scalar( \[$name\] )

Verifies that the function currently being executed has been called in
scalar context.  This is to ensure the calling function is not ignoring
the return value of the executing function.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return $important_value;
    }

This call to `something` will pass:

    my $val = something();

but these will fail:

    something();
    my @things = something();

If the `$name` argument is not passed, a default message of "&lt;funcname>
must be called in scalar context" is provided.

## assert\_context\_list( \[$name\] )

Verifies that the function currently being executed has been called in
list context.

Given this function:

    sub something {
        ...

        assert_context_scalar();

        return @values;
    }

This call to `something` will pass:

    my @vals = something();

but these will fail:

    something();
    my $thing = something();

If the `$name` argument is not passed, a default message of "&lt;funcname>
must be called in list context" is provided.

# UTILITY ASSERTIONS

## assert\_fail( \[$name\] )

Assertion that always fails.  `assert_fail($msg)` is exactly the same
as calling `assert(0,$msg)`, but it eliminates that case where you
accidentally use `assert($msg)`, which of course never fires.

# COPYRIGHT & LICENSE

Copyright 2005-2024 Andy Lester

This program is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

# ACKNOWLEDGEMENTS

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
