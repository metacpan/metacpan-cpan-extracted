#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Person;
use MyFactory;
use Test::More tests => 2;
MyFactory->register_factory_type(
    person_name    => 'Person::ComplexName',
    person_address => 'Person::ComplexAddress',
);
my $person = Person->new;
my $name   = $person->name;
isa_ok($name, 'Person::ComplexName');
my $address = $person->address;
isa_ok($address, 'Person::ComplexAddress');
