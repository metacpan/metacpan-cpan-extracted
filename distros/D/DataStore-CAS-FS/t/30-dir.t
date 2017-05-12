#! /usr/bin/env perl -T
use strict;
use warnings;

use Test::More;
use Digest;
use Data::Dumper;

use_ok('DataStore::CAS::FS::Dir') || BAIL_OUT;
use_ok('DataStore::CAS::FS::DirEnt') || BAIL_OUT;
use_ok('DataStore::CAS') || BAIL_OUT;

package BogusCAS;
sub _file_destroy {}
package main;

my $f= bless { store => bless({}, 'BogusCAS'), hash => 'y', size => 'z' }, 'DataStore::CAS::File';
sub new_dir_ok { new_ok( 'DataStore::CAS::FS::Dir', @_ ) }
sub new_dirent_ok { new_ok( 'DataStore::CAS::FS::DirEnt', @_ ) }

subtest ctor => sub {
	my $d= new_dir_ok( [ file => $f, format => 'Foo', metadata => { hello => 1 }, entries => [] ], 'basic ctor' );
	is( $d->file, $f, 'file' );
	is( $d->size, 'z', 'size' );
	is( $d->hash, 'y', 'hash' );
	is( ref $d->store, 'BogusCAS', 'store' );
	is( $d->format, 'Foo', 'format' );
	is( $d->metadata->{hello}, 1, 'metadata' );

	$d= new_dir_ok( [ file => $f, format => 'Foo' ], 'ctor defaults' );
	is_deeply( $d->metadata, {}, 'metadata' );

	done_testing;
};

subtest get => sub {
	my $d= new_dir_ok( [ file => $f, format => 'Foo' ] );
	is( $d->get_entry('x'), undef );
	is( $d->get_entry('x', { case_insensitive => 1 }), undef );

	my @entries= (
		new_dirent_ok([ type => 'file', name => 'x' ])
	);
	$d= new_dir_ok( [ file => $f, format => 'Foo', entries => \@entries ] );
	is( $d->get_entry('x'), $entries[0], 'get existing' );
	is( $d->get_entry('X', { case_insensitive => 1 }), $entries[0], 'get caseless existing' );
	is( $d->get_entry('X'), undef, 'get case mismatch' );

	done_testing;
};

subtest iterator => sub {
	my $d= new_dir_ok( [ file => $f, format => 'Foo' ] );
	is( ref(my $i= $d->iterator), 'CODE', 'iterator' );
	is( $i->(), undef, 'iterate empty list' );
	is( $i->(), undef, 'past eof' );
	
	my @entries= (
		new_dirent_ok( [ type => 'file', name => 'x' ] )
	);
	$d= new_dir_ok( [ file => $f, format => 'Foo', entries => \@entries ] );
	is( ref($i= $d->iterator), 'CODE', 'iterator' );
	is( $i->(), $entries[0], 'elem 1' );
	is( $i->(), undef, 'eof' );
	is( $i->(), undef, 'past eof' );
	
	done_testing;
};

done_testing;