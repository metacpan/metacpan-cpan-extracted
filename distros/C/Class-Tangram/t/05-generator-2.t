#!/usr/bin/perl -w

use strict;

use lib "t";
use Test::More tests => 8;

use Class::Tangram;

use_ok("Class::Tangram::Generator");
use vars qw($schema);

require 'springfield.pl';

my $generator = Class::Tangram::Generator->new($schema);

isa_ok($generator, "Class::Tangram::Generator",
       "Class::Tangram::Generator->new");

my $NP = new NaturalPerson(name => "muldoon");

isa_ok($NP, "NaturalPerson", "Generated class");
can_ok($NP, "get_firstName");
is($NP->firstName, "bob",
   "Everyone is known as bob unless otherwise stated");

ok($NP->set_brains("stimulated"), "Accessors work");
like($NP->brains, qr/bork bork/, "Overridden accessors still work");

eval {
	my $credit = new Credit;
};

isnt ($@, "", "Using a module that fails to load another module fails");

