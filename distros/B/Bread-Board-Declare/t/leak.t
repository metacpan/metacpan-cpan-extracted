#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

my $demolished;
{
    package Foo;
    use Moose;
    use Bread::Board::Declare;

    has controller => (is  => 'ro');

    sub DEMOLISH { $demolished++ }
}

{
    my $foo = Foo->new;
}
is($demolished, 1);

done_testing;
