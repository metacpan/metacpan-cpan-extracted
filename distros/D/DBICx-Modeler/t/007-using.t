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
my $bob = $modeler->model( 'Artist' )->create({ name => 'bob' });

ok( $alice );
ok( $bob );

ok( my $alice_1 = $alice->create_related( cds => { title => 'alice-1' } ) );
ok( my $alice_2 = $alice->create_related( cds => { title => 'alice-2' } ) );
ok( my $bob_1 = $bob->create_related( cds => { title => 'bob-1' } ) );

ok( $alice_1->artist );
is( $alice_1->artist, $alice_1->artist );
is( ref $alice_1->artist, 't::Test::Project::Model::Artist::Rock' );
is( $alice_1->artist->name, 'alice' );
is( $alice_2->artist->name, 'alice' );
is( $bob_1->artist->name, 'bob' );

cmp_deeply( [ map { $_->title } $alice->cds ], bag( qw/alice-1 alice-2/ ) );
cmp_deeply( [ map { $_->title } $bob->cds ], bag( qw/bob-1/ ) );

cmp_deeply( [ map { $_->title } $alice->search_related( cds => { title => 'alice-2' } ) ], bag( qw/alice-2/ ) );
cmp_deeply( [ map { $_->title } $alice->search_related( 'cds' ) ], bag( qw/alice-1 alice-2/ ) );
cmp_deeply( [ map { $_->title } $bob->search_related( cds => undef ) ], bag( qw/bob-1/ ) );

cmp_deeply( [ map { $_->title } $modeler->model( 'Cd' )->search ], bag( qw/alice-1 alice-2 bob-1/ ) );
cmp_deeply( [ map { $_->title } $modeler->model( 'Cd' )->search( { title => { -like => '%-1' } } ) ], bag( qw/alice-1 bob-1/ ) );

map { memory_cycle_ok $_ } $modeler->model( 'Cd' )->search;
map { is( ref $_, 't::Test::Project::Model::Cd' ) } $modeler->model( 'Cd' )->search;

1;
