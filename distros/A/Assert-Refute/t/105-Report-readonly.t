#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute::Report;

my $c = Assert::Refute::Report->new;
$c->done_testing;

foreach my $method (qw( refute note diag done_testing )) {
    is eval { $c->$method(undef); "$method shall not pass" }, undef, "$method locked";
    like $@, qr/done_testing.*no more/, "Error message as expected";
};

done_testing;
