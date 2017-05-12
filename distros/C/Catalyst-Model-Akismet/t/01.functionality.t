#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use lib qw( t/lib );


# Make sure the Catalyst app loads ok...
use_ok('TestApp');


my $amazon = TestApp->model('Akismet');
isa_ok( $amazon, 'Catalyst::Model::Akismet' );
can_ok( $amazon, 'akismet' );


1;
