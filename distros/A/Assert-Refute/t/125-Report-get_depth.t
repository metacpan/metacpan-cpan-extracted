#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Report;

my $main = Assert::Refute::Report->new;
my $outer = Assert::Refute::Report->new;
my $inner = Assert::Refute::Report->new;

$outer->set_parent( $main );
$inner->set_parent( $outer );

is $main->get_depth, 0, "depth default";
is $inner->get_depth, 2, "depth recursive";

done_testing;
