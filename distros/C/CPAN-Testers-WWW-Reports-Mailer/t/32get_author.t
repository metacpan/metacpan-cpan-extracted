#!/usr/bin/perl -w
use strict;

# -------------------------------------------------------------------
# Library Modules

use lib qw(t/lib);
use Test::More tests => 6;

use CPAN::Testers::WWW::Reports::Mailer;

use TestObject;

# -------------------------------------------------------------------
# Variables

my $CONFIG = 't/_DBDIR/preferences.ini';

# -------------------------------------------------------------------
# Tests

SKIP: {
    skip "No supported databases available", 6  unless(-f $CONFIG);

    ok( my $obj = TestObject->load(), "got object" );

    is($obj->_get_author('Abstract-Meta-Class','0.11'),'ADRIANWIT','found author ADRIANWIT');
    is($obj->_get_author('Acme-CPANAuthors-French','0.07'),'SAPER','found author SAPER');
    is($obj->_get_author('Acme-Buffy','1.5'),'LBROCARD','found author LBROCARD');
    is($obj->_get_author('AI-NeuralNet-Mesh','0.44'),'JBRYAN','found author JBRYAN');

    is($obj->_get_author('Fake-Distro','0.01'),undef,'Fake Distro author not found');
}