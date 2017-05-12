#!/usr/bin/env perl
use warnings;
use strict;
use FindBin '$Bin';
use lib File::Spec->catdir($Bin, 'lib');
use Test::More tests => 4;
use MyFactory;
my $name =
  MyFactory->make_object_for_type(person_name => fullname => 'Shindou Hikaru');
isa_ok($name, 'Person::SimpleName');
is($name->fullname, 'Shindou Hikaru', 'fullname');
MyFactory->register_factory_type(
    person_name    => 'Person::ComplexName',
    person_address => 'Person::ComplexAddress',
);
my $name2 = MyFactory->make_object_for_type(
    person_name => lastname => 'Shindou',
    firstname   => 'Hikaru',
);
isa_ok($name2, 'Person::ComplexName');
is($name2->lastname, 'Shindou', 'last name');
