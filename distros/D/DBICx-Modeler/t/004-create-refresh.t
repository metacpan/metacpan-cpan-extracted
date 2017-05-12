#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test::Project;

my ($modeler, $artist);
$modeler = t::Test::Project->modeler( create_refresh => 1 );

ok( $artist = $modeler->create( 'Artist' => { name => 'apple' } ) );
is( $artist->name, 'apple' );
like( $artist->insert_datetime, qr/^\d{4}-/ ); # Something vaguely date-like

$modeler = t::Test::Project->modeler( create_refresh => 0 );

ok( $artist = $modeler->create( 'Artist' => { name => 'apple' } ) );
is( $artist->name, 'apple' );
is( $artist->insert_datetime, undef );
$artist->_model__storage->discard_changes;
like( $artist->insert_datetime, qr/^\d{4}-/ ); # Something vaguely date-like
