#!/usr/bin/perl -w

use strict;
use warnings;
use v5.10;
use lib 'lib', '../lib'; # able to run prove in project dir and .t locally

use Test::More tests => 4;

use_ok('Data::Identifier::Interface::Known');

{
    my @list = Data::Identifier::Interface::Known->known(':all');
    ok(scalar(@list) == 0, 'Default empty :all list');
}

{
    my @list = eval {Data::Identifier::Interface::Known->known('XXX')};
    my $err = $@;
    ok(scalar(@list) == 0, 'Empty unknown list list');
    ok(!!$err, 'Unknown list is error');
}

exit 0;
