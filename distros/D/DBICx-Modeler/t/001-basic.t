#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;
use Test::Deep grep { !m/blessed/ } @Test::Deep::EXPORT;

plan qw/no_plan/;

use t::Test::Project;
use t::Test::Project::Modeler;

use t::Test::Project::Model::Artist::Rock;
use t::Test::Project::Model::Artist;
use t::Test::Project::Model::Cd;
use t::Test::Project::Model::Track;

my $schema = t::Test::Project->schema;
my $modeler = t::Test::Project::Modeler->new( schema => $schema );

ok( $modeler );
is( scalar $modeler->model_sources, 3 );

is( t::Test::Project::Model::Artist::Rock->_model__meta->parent->model_class, 't::Test::Project::Model::Artist' );
ok( !t::Test::Project::Model::Artist->_model__meta->parent );

ok( $modeler->model_source_by_model_class( 't::Test::Project::Model::Artist' ) );
warning_is {
    ok( $modeler->model_source_by_model_class( 't::Test::Project::Model::Artist::Rock' ) );
} undef, 'Warning did not occur';
ok( $modeler->model_source_by_model_class( 't::Test::Project::Model::Cd' ) );
ok( $modeler->model_source_by_model_class( 't::Test::Project::Model::Track' ) );

1;
