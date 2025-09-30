#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Scalar::Util qw( weaken refaddr );

use Assert::Refute::Report;

my $child  = Assert::Refute::Report->new;
my $parent = Assert::Refute::Report->new;

is $child->get_parent, undef, "initial parent is null";

is refaddr( $child->set_parent( $parent ) ), refaddr $child, "set_parent returns self";
is refaddr( $child->get_parent ), refaddr $parent, "get_parent adjusted";

is refaddr( $child->set_parent( undef ) ), refaddr $child, "set_parent returns self";
is $child->get_parent, undef, "initial parent is null";

# poor man's throws_ok
my $nope = eval {
    $child->set_parent(42);
    1;
};
my $err = $@;
is $nope, undef, "can't assign to non-ref";
like $err, qr(parent must be.*Report), "descriptive error message";

done_testing;


