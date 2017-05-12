#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use DBICx::Modeler;

package t::Model::Web::Artist;

use DBICx::Modeler::Model;

extends qw/t::Test::Project::Model::Artist/;

sub uri {
    return 'http://example.com/' . shift->name 
}

package main;

use t::Test::Project;

my ($modeler, $artist, $cd);
$modeler = t::Test::Project->modeler( namespace => [qw/ +t::Model::Web +t::Test::Project::Model /] );

ok( $artist = $modeler->create( 'Artist' => { name => 'apple' } ) );
is( ref $artist, 't::Model::Web::Artist' );
is( $artist->name, 'apple' );
is( $artist->uri, 'http://example.com/apple' );

ok( $cd = $artist->create_related( cds => { title => 'banana' } ) );
is( ref $cd, 't::Test::Project::Model::Cd' );
is( $cd->title, 'banana' );
ok( $cd->insert_datetime );
