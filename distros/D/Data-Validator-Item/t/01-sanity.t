#01-sanity.t
#Basic tests Data::Validator::Item
#
use strict;
use warnings;
use Test::More 'no_plan';
use Data::Validator::Item;

#Make a new (blank) Validator
my $Validator = Data::Validator::Item->new();

#Can we make it?
ok(defined $Validator, "new() returned something");
ok($Validator->isa('Data::Validator::Item'), "and its the right class");

#Test zap()
ok($Validator->zap(),"We can zap it");
