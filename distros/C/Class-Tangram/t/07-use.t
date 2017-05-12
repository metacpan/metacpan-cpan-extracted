#!/usr/bin/perl -w

use strict;

use lib "t";
use Test::More tests => 4;

use Class::Tangram;

use_ok("Class::Tangram::Generator");
use vars qw($schema);

require 'springfield.pl';

my $generator = Class::Tangram::Generator->new($schema);

eval "use 'NuclearPlant'";
isnt($@, "", "use NuclearPlant didn't die");

my $plant;
eval {
    $plant = new NuclearPlant;
};
isa_ok($plant, 'NuclearPlant',
       "Bypassing Generator still calls generator hooks");

$plant->set_curies(6*9);
is($plant->curies, 42, "Extra methods were defined");

