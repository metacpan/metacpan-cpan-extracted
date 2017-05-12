#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Person;
use Test::More tests => 2;
my $person = Person->new;
my $name   = $person->name;
isa_ok($name, 'Person::SimpleName');
my $address = $person->address;
isa_ok($address, 'Person::SimpleAddress');
