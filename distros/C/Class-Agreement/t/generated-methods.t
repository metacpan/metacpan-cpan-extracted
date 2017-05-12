#!perl

use strict;
use warnings;

# =head2 What if I generate methods?
# 
# There's no problem as long as you build your subroutines before runtime,
# probably by sticking the generation in a C<BEGIN> block.

use Test::More tests => 6;
use Test::Exception;

{

    package Camel;
    use Class::Agreement;

    my $assertion = sub { $_[1] > 0 };
    precondition foo => $assertion;
    precondition bar => $assertion;
    precondition baz => $assertion;

    BEGIN {
        no strict 'refs';
        *{$_} = sub { }
            for qw( foo bar baz );
    }
}

foreach my $method (qw( foo bar baz )) {
    lives_ok { Camel->$method(5) } "method simple success";
    dies_ok  { Camel->$method(-1) } "method simple failure";
}

