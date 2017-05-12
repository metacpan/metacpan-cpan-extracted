use strict;
use warnings;

use Test::More tests => 11;
use Path::Tiny qw( path );
use Test::TempDir::Tiny qw( tempdir );

# ABSTRACT: Test find_and_pack works

# Prepare the layout

my $temp = tempdir('scratch_tree');
path( $temp, 'assets' )->mkpath;
path( $temp, 'lib' )->mkpath;
path( $temp, 'assets', 'example.js' )->spew_raw(<<'EOF');
( function() {
  alert("this is javascript!");
} )();
EOF

use Asset::Pack qw( find_and_pack );

my $layout = find_and_pack( path( $temp, 'assets' ), 'Test::X::FindAndPack', path( $temp, 'lib' ), );

cmp_ok( scalar @{ $layout->{ok} },        '==', 2, "One file + 1 index found and packed" );
cmp_ok( scalar @{ $layout->{fail} },      '==', 0, "No errors found" );
cmp_ok( scalar @{ $layout->{unchanged} }, '==', 0, "No unchanged files" );
is( $layout->{ok}->[0]->{module}, 'Test::X::FindAndPack::examplejs', "asset package renamed correctly" );

unshift @INC, path( $temp, 'lib' )->stringify;

use_ok('Test::X::FindAndPack::examplejs');
use_ok('Test::X::FindAndPack');

my $index = do { no warnings 'once'; $Test::X::FindAndPack::index };

is( $index->{'Test::X::FindAndPack::examplejs'}, 'example.js', 'Index contains map' );

$layout = find_and_pack( path( $temp, 'assets' ), 'Test::X::FindAndPack', path( $temp, 'lib' ), );

cmp_ok( scalar @{ $layout->{ok} },        '==', 0, "No new packs" );
cmp_ok( scalar @{ $layout->{fail} },      '==', 0, "No errors found" );
cmp_ok( scalar @{ $layout->{unchanged} }, '==', 2, "One unchanged files" );

is( $layout->{unchanged}->[0]->{module}, 'Test::X::FindAndPack::examplejs', "unchanged package renamed correctly" );
