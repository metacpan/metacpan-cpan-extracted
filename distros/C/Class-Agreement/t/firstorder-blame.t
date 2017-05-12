#!perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;

local $TODO = 'higher-order is unfinished';

#
# Examples from "Contracts for Higher-Order Functions" by Robert Bruce Findler
# and Matthias Felleisen
#
# http://www.ccs.neu.edu/scheme/pubs/icfp2002-ff.pdf 
#

use Class::Agreement;

# helpers for the purposes of example
sub is_greater_than_nine            { $_[0] > 9 }
sub is_between_zero_and_ninety_nine { $_[0] > 0 and $_[0] < 99 }

# g : (integer -> integer) -> integer
# (define/contract g
#   ((greater-than-nine? -> between-zero-and-ninety-nine?)
#     -> #     between-zero-and-ninety-nine?)
#   (lambda (f) (f 0)))

my @lines = map { __LINE__ + $_ } 4, 5, 6, 9;

sub make_contract {
    my ($name) = @_;
    precondition $name => sub {    # $lines[0]
        precondition $_[0] => sub { is_greater_than_nine( $_[0] ) };    # $lines[1]
        postcondition $_[0] =>                                          # $lines[2]
            sub { is_between_zero_and_ninety_nine( $_[0] ) };
    };
    postcondition $name =>
        sub { is_between_zero_and_ninety_nine(result) };                # $lines[3]
}

# "At the point when g invokes f, the is_greater_than_nine portion of g's
# contract fails. According to the even-odd rule, this must be g's fault. In
# fact, g does supply the bad value, so g must be blamed."

make_contract('g');

sub g {
    my ($f) = @_;
    $f->(0);
}

eval {
    g( sub {0} );
};
like $@, qr/function main::g provided invalid input/,
    "g()'s implementation is at fault";
like $@, qr/line $lines[1]/, "contract 1 was broken";

# "Imagine a variation of the above example where g applies f to 10 instead of
# 0. Further, imagine that f returns −10. This is a violation of the result
# portion of g's argument's contract [number 2 above] and, following the
# even-odd rule, the fault lies with g's caller. 

make_contract('g2');

sub g2 {
    my ($f) = @_;
    $f->(10);
}

my $caller_line = __LINE__ + 2;
eval {
    g2( sub { -10 } );
};
like $@, qr/caller of main::g2 provided invalid/, "g()'s caller is at fault";
like $@, qr/line $lines[2]/, "contract 2 was broken";

