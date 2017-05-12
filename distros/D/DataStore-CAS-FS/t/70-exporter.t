#! /usr/bin/env perl -T
use strict;
use warnings;
use Test::More;
use Path::Class 'file', 'dir';

use_ok( 'DataStore::CAS::FS::Exporter' ) || BAIL_OUT;
use_ok( 'DataStore::CAS::Virtual' ) || BAIL_OUT;
use_ok( 'DataStore::CAS::FS' ) || BAIL_OUT;

chdir('t') if -d 't';
-d 'cas_tmp' or BAIL_OUT('missing cas_tmp directory for testing exporter');

my $tree1= dir('cas_tmp','export1');

subtest simple => sub {
	$tree1->rmtree(0,0);
	my $cas= DataStore::CAS::Virtual->new();
	my $fs= DataStore::CAS::FS->new(store => $cas, root => {});
	$fs->set_path("file1", { ref => $cas->hash_of_null });
	$fs->set_path("file2", { ref => $cas->hash_of_null });

	my $exporter= new_ok( 'DataStore::CAS::FS::Exporter', [] );
	ok( $exporter->export_tree( $fs->path('/'), $tree1 ), 'export tree' );
	ok( -f $tree1->file('file1'), 'file1 exists' );
	is( -s $tree1->file('file1'), 0, 'is empty' );
	ok( -f $tree1->file('file2'), 'file2 exists' );
	is( -s $tree1->file('file2'), 0, 'is empty' );

	done_testing;
};

done_testing;