# Carp::Assert::More

[![Build Status](https://travis-ci.org/petdance/carp-assert-more.svg?branch=dev)](https://travis-ci.org/petdance/carp-assert-more)

Carp::Assert::More is a set of handy assertion functions for Perl.

For example, instead of writing

    assert( defined($foo), '$foo cannot be undefined' );
    assert( $foo ne '', '$foo cannot be blank' );

you can write

    assert_nonblank( $foo, '$foo cannot be blank' );
