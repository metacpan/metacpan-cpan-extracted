#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

BEGIN {
    $ENV{DBIC_MODELER_TRACE} = 1;
}

plan qw/no_plan/;

package t::Model::Web::Artist;

use DBICx::Modeler::Model;

extends qw/t::Test::Project::Model::Artist/;

sub uri {
    return 'http://example.com/' . shift->name 
}

package main;

use t::Test::Project;

my @trace;
$DBICx::Modeler::Carp::TRACE = sub { push @trace, join '', @_ };

my ($modeler1, $modeler2, $artist, $cd);
$modeler1 = t::Test::Project->modeler( namespace => [qw/ +t::Model::Web +t::Test::Project::Model /] );
$modeler2 = t::Test::Project->modeler( namespace => [qw/ +t::Model::Web +t::Test::Project::Model /] );

ok( $modeler1 );
ok( $modeler2 );

cmp_deeply( \@trace, superbagof( 
    re( 'Already initialized t::Test::Project::Model::Track' ),
    re( 'Already initialized t::Test::Project::Model::Cd' ),
    re( 'Already initialized t::Model::Web::Artist' ),
) );
