#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Path::Class 'file', 'dir';

use_ok( 'DataStore::CAS::FS::Importer' ) || BAIL_OUT;
use_ok( 'DataStore::CAS::Virtual' ) || BAIL_OUT;
use_ok( 'DataStore::CAS::FS' ) || BAIL_OUT;

my $scn= new_ok( 'DataStore::CAS::FS::Importer', [] );

chdir('t') if -d 't';
-d 'cas_tmp' or BAIL_OUT('missing cas_tmp directory for testing directory scanner');

subtest simple => sub {
	my $tree= dir('cas_tmp','tree1');
	$tree->rmtree(0,0);
	$tree->mkpath();
	$tree->file('file1')->touch;
	$tree->file('file2')->touch;

	my $cas= DataStore::CAS::Virtual->new();
	my $fs= DataStore::CAS::FS->new(store => $cas, root => {});
	
	my $importer= DataStore::CAS::FS::Importer->new();
	ok( my $attrs= $importer->collect_dirent_metadata($tree->file('file1')), 'scan file1' );
	is( $attrs->{name}, 'file1', 'name' );
	is( $attrs->{type}, 'file', 'type' );
	is( $attrs->{size}, 0, 'size' );
	is( $attrs->{ref}, undef, 'ref' );

	ok( my $ent= $importer->import_directory_entry($cas, $tree->file('file1')), 'import file1' );
	is( $ent->ref, $cas->hash_of_null, 'ref' );
	
	ok( my $digest= $importer->import_directory($cas, $tree), 'import directory' );
	isa_ok( $fs->get_dir($digest), 'DataStore::CAS::FS::Dir', 'read imported directory' );
	
	ok( $importer->import_tree($tree, $fs->path('/')), 'import tree to virtual path' );
	is_deeply( [ $fs->readdir('/') ], [ 'file1', 'file2' ], 'virtual path readdir' );

	done_testing;
};

done_testing;