#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Attribute::RecordCallers;

my $calls = 0;
our $l;
sub foo :lvalue :RecordCallers { $calls++; $l }

eval q{ foo = 42 };
TODO: {
    local $TODO = "Propagate lvalue attribute to wrapper";
    is($calls, 1, 'the lvalue sub has been called');
    is($l, 42, '...and returned an lvalue');
    is(scalar keys %Attribute::RecordCallers::callers, 1, 'the call has been registered');
}
