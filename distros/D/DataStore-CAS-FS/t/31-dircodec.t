#! /usr/bin/env perl -T
use strict;
use warnings;

use Test::More;
use Digest;
use Data::Dumper;

use_ok('DataStore::CAS::FS::DirCodec') || BAIL_OUT;
use_ok('DataStore::CAS::FS::Dir') || BAIL_OUT;
use_ok('DataStore::CAS::FS::DirEnt') || BAIL_OUT;
use_ok('DataStore::CAS::Virtual') || BAIL_OUT;

our $fake_entries= [
	DataStore::CAS::FS::DirEnt->new(type => 'file', name => 'a'),
	DataStore::CAS::FS::DirEnt->new(type => 'file', name => 'b'),
	DataStore::CAS::FS::DirEnt->new(type => 'file', name => 'c'),
];
our $encode_entries;
our $encode_metadata;

package TestCodec;

sub encode {
	my ($self, $entries, $metadata)= @_;
	$encode_entries= $entries;
	$encode_metadata= $metadata;
	return "CAS_Dir 04 test\n";
}

sub decode {
	my ($self, $params)= @_;
	return DataStore::CAS::FS::Dir->new(
		file => 0, format => $params->{format},
		metadata => $params, entries => $fake_entries
	);
}

package main;

DataStore::CAS::FS::DirCodec->register_format('test' => 'TestCodec');

subtest load => sub {
	my $d= DataStore::CAS::FS::DirCodec->load({ file => 0, data => "CAS_Dir 04 test\n" });
	isa_ok( $d, 'DataStore::CAS::FS::Dir', 'load dir' );
	is_deeply( $d->metadata, { file => 0, data => "CAS_Dir 04 test\n", format => 'test' }, '$params was correct' );
	is( $d->get_entry('a'), $fake_entries->[0], 'find dirent' );
	
	my $cas= DataStore::CAS::Virtual->new();
	my $hash= $cas->put_scalar("CAS_Dir 04 test\n");
	$d= DataStore::CAS::FS::DirCodec->load($cas->get($hash));
	isa_ok( $d, 'DataStore::CAS::FS::Dir', 'load dir' );
	is_deeply( [ sort keys %{$d->metadata} ], [ qw( file format handle ) ], '$params was correct' );
	is( $d->get_entry('a'), $fake_entries->[0], 'find dirent' );
	
	done_testing;
};

subtest store => sub {
	my $cas= DataStore::CAS::Virtual->new();
	my $hash= DataStore::CAS::FS::DirCodec->put($cas, 'test', $fake_entries, {});
	is( $encode_entries, $fake_entries, 'entries param' );
	is_deeply( $encode_metadata, {}, 'metadata param' );
	is( $cas->get($hash)->data, "CAS_Dir 04 test\n", 'correct data stored' );
};

done_testing;