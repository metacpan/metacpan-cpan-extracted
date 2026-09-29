#!/usr/bin/perl -w

use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 4;

use_ok('Data::Identifier::Wellknown');
use_ok('Data::Identifier');

Data::Identifier::Wellknown->import(':all');

my @all = Data::Identifier::Wellknown->known(':all', as => 'Data::Identifier');
ok(scalar(@all) > 100, 'We got plenty of identifiers');

foreach my $id (@all) {
    $id->uuid;
    $id->displayname;
}

pass('Still alive');

exit 0;
