#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the Data::SExpression::Symbol class

=cut

use Test::More q(no_plan);

use Data::SExpression::Symbol;
use Scalar::Util qw(refaddr);


my $symbol = Data::SExpression::Symbol->new('foo');

isa_ok($symbol, 'Data::SExpression::Symbol');

is("$symbol", "foo", "stringifies properly");
ok($symbol eq "foo", "compares properly");

is($symbol->name, 'foo', 'Name is correct');

my $other_symbol = Data::SExpression::Symbol->new('foo');

ok(refaddr($symbol) == refaddr($other_symbol), "Symbols are interned appropriately");

ok($symbol eq $other_symbol, "Symbols compare correctly");

my $uninterned = Data::SExpression::Symbol->uninterned('foo');

is($uninterned->name, 'foo');
is("$uninterned", "#:foo", "Uninterned symbols stringify correctly");

ok($uninterned ne $symbol, "Uninterned symbols are not eq to interned ones");
ok($uninterned ne "foo",   "Uninterned symbols are not eq to strings");
ok($uninterned ne "$uninterned", "Uninterned symbols are not equal to their stringification");
ok($uninterned eq $uninterned, "Uninterned symbols are eq to themself");

my $unint2 = Data::SExpression::Symbol->uninterned('foo');

ok($uninterned ne $unint2, "Two uninterned symbols are not eq");

