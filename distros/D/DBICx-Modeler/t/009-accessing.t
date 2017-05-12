#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;

plan qw/no_plan/;

use t::Test::Project;

my ($modeler);
$modeler = t::Test::Project->modeler;
ok( $modeler );

my $alice = $modeler->model( 'Artist' )->create({ name => 'alice' });
is( $alice->_model__column_name, 'alice' );
ok( $alice->can( "_model__column_$_" ) ) for qw/id name insert_datetime/;
ok( my $alice_1 = $alice->create_related( cds => { title => 'alice-1' } ) );
ok( my $alice_2 = $alice->create_related( cds => { title => 'alice-2' } ) );
is( $alice->_model__relation_cds, 2 );
is( ref scalar $alice->_model__relation_cds, 'DBIx::Class::ResultSet' );
is( $alice->cds, 2 );
is( ref scalar $alice->cds, 'DBIx::Class::ResultSet' );
ok( $alice_1->artist );
ok( $alice_1->_model__relation_artist );
is( $alice_1->artist, $alice_1->_model__relation_artist );
