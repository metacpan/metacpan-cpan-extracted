#!/usr/bin/perl -w
use strict;

use Test::More tests => 4;
use CPAN::Testers::WWW::Statistics::Excel;

ok( my $obj = CPAN::Testers::WWW::Statistics::Excel->new(), "got object" );

eval { $obj->create() };
is($@,"Source file not provided\n");
eval { $obj->create( source => 't/example.html') };
is($@,"Target file not provided\n");
eval { $obj->create( source => 't/non-existent.html', target => 'example.xls') };
is($@,"Source file [t/non-existent.html] not found\n");
