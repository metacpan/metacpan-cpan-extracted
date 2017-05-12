#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

package t::Does::URI;

use Moose::Role;

requires qw/uri/;

package t::Model::Artist;

use DBICx::Modeler::Model;

extends qw/t::Test::Project::Model::Artist/;
with qw/t::Does::URI/;

sub uri {
    return 'http://example.com/' . shift->name 
}

package t::Model::Artist::Rock;

use DBICx::Modeler::Model;

extends qw/t::Model::Artist/;
with qw/t::Does::URI/;

package t::Model::Alternate::Cd;

use DBICx::Modeler::Model;

extends qw/t::Test::Project::Model::Cd/;

belongs_to( artist => '+t::Test::Project::Model::Artist::Rock' ); # Use the "default" model class

package main;

use t::Test::Project;

my ($modeler);
$modeler = t::Test::Project->modeler( namespace => [qw/ +t::Model +t::Test::Project::Model /] );

ok( $modeler );

ok( my $alice = $modeler->model( 'Artist' )->create({ name => 'alice' }) );
ok( my $bob = $modeler->model( 'Artist' )->create({ name => 'bob' }) );

ok( my $alice_1 = $alice->create_related( cds => { title => 'alice-1' } ) );
ok( my $alice_2 = $alice->create_related( cds => { title => 'alice-2' } ) );
ok( my $bob_1 = $bob->create_related( cds => { title => 'bob-1' } ) );

is( ref $alice, 't::Model::Artist' );
$alice->meta->does_role( 't::Does::URI' );

is( ref $alice_1->artist, 't::Model::Artist::Rock' );

$modeler->model( 'Cd' )->model_class( 't::Model::Alternate::Cd' );
($alice_1) = $modeler->model( 'Cd' )->search( { title => 'alice-1' } )->slice( 0 );

is( ref $alice_1, 't::Model::Alternate::Cd' );
warning_is {
    is( ref $alice_1->artist, 't::Test::Project::Model::Artist::Rock' );
} undef, 'Warning did not occur';
