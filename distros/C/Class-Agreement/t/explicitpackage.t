#!perl

use strict;
use warnings;

use Test::More tests => 2;
use Test::Exception;

use Class::Agreement;

# one sould be able to use full symbolic names with the functions

sub Camel::simple { }

precondition 'Camel::simple' => sub { $_[1] > 0 };

lives_ok { Camel->simple(5) } "simple success";
dies_ok  { Camel->simple(-1) } "simple failure";

