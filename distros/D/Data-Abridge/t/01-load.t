#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 2;

my @EXPORTABLE = qw( abridge_item abridge_recursive abridge_items abridge_items_recursive );

use_ok( 'Data::Abridge', @EXPORTABLE );

can_ok( __PACKAGE__, @EXPORTABLE );


