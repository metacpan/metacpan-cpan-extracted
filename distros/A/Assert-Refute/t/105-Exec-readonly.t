#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Exec;

my $c = Assert::Refute::Exec->new;
$c->done_testing;

foreach my $method (qw( refute note diag done_testing )) {
    is eval { $c->$method(0); "$method shall not pass" }, undef, "$method locked";
    like $@, qr/done_testing.*no more/, "Error message as expected";
};

done_testing;
