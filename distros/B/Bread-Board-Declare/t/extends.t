#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Fatal;

{
    package Bar;
    use Moose;
}

{
    package Baz;
    use Moose;
    use Bread::Board::Declare;
}

{
    package Quux;
    use Moose;
    use Bread::Board::Declare;
}

{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    ::like(::exception { extends 'Bar' },
           qr/^Cannot inherit from Bar because Bread::Board::Declare classes must inherit from Bread::Board::Container/,
           "error when inheriting from a non-container");
    ::like(::exception { extends 'Baz', 'Quux' },
           qr/^Multiple inheritance is not supported for Bread::Board::Declare classes/,
           "error when inheriting from multiple containers");
}

done_testing;
