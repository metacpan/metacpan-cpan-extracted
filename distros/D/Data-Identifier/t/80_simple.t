#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 7;

use_ok('Data::Identifier');
use_ok('Data::Identifier::Interface::Simple');

my $identifier = Data::Identifier->new(wellknown => 'uuid');

isa_ok($identifier, 'Data::Identifier');
isa_ok($identifier, 'Data::Identifier::Interface::Simple');
is($identifier->Data::Identifier::Interface::Simple::as('Data::Identifier'), $identifier, 'as() returns self');
is($identifier->Data::Identifier::Interface::Simple::displayname(), $identifier->displayname, 'displayname() match');
is($identifier->Data::Identifier::Interface::Simple::ise(), $identifier->ise, 'ise() match');

exit 0;
