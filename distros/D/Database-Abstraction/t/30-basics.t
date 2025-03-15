#!/usr/bin/env perl

use strict;
use warnings;

use File::Temp qw(tempdir);
use File::Spec;
use FindBin qw($Bin);
use Test::Most tests => 20;

use constant	DEFAULT_MAX_SLURP_SIZE => 16 * 1024;	# CSV files <= than this size are read into memory

use lib 't/lib';

use_ok('Database::test1');

# Test handling of HASH or HASHREF arguments
{
	my $directory = File::Spec->catfile($Bin, File::Spec->updir(), 'data');

	my $obj = Database::test1->new({ key1 => 'value1', key2 => 'value2', directory => $directory });
	is($obj->{key1}, 'value1', 'HASHREF argument unpacked correctly');
	is($obj->{key2}, 'value2', 'HASHREF argument unpacked correctly');

	$obj = Database::test1->new(key1 => 'value1', key2 => 'value2', directory => $directory);
	is($obj->{key1}, 'value1', 'Key-value arguments processed correctly');
	is($obj->{key2}, 'value2', 'Key-value arguments processed correctly');

	$obj = Database::test1->new($directory);
	is($obj->{directory}, $directory, 'Single argument assigned to directory');
}

# Test class and object validation
{
	my $tempdir = tempdir(CLEANUP => 1);

	# Abstract class instantiation
	dies_ok { Database::test1->new() } 'Abstract class instantiation croaks';

	# Valid class instantiation
	my $obj = Database::test1->new(directory => $tempdir);
	isa_ok($obj, 'Database::test1');

	# Object cloning
	my $clone = $obj->new(key1 => 'value1');
	is($clone->{key1}, 'value1', 'Cloned object merged arguments correctly');
}

# Test directory validation
{
	dies_ok { Database::test1->new(directory => '/invalid/dir') } 'Invalid directory croaks';

	my $tempdir = tempdir(CLEANUP => 1);
	my $obj = Database::test1->new(directory => $tempdir);
	is($obj->{directory}, $tempdir, 'Valid directory creates object');
}

# Test defaults
{
	my $tmpdir = File::Spec->tmpdir();

	Database::Abstraction::init(directory => $tmpdir);
	my $obj = Database::test1->new();
	cmp_ok($obj->{directory}, 'eq', $tmpdir, 'Default directory used when no argument is given');
	is($obj->{no_entry}, 0, 'Default no_entry is set');
	is($obj->{cache_duration}, '1 hour', 'Default cache_duration is set');
	is($obj->{max_slurp_size}, DEFAULT_MAX_SLURP_SIZE, 'Default max_slurp_size is set');
}

# Test cache duraction
{
	my $tmpdir = File::Spec->tmpdir();

	Database::Abstraction::init(directory => $tmpdir, expires_in => '5 days');
	my $obj = Database::test1->new();
	cmp_ok($obj->{directory}, 'eq', $tmpdir, 'Default directory used when no argument is given');
	is($obj->{no_entry}, 0, 'Default no_entry is set');
	is($obj->{cache_duration}, '5 days', 'cache_duration is set');
	is($obj->{max_slurp_size}, DEFAULT_MAX_SLURP_SIZE, 'Default max_slurp_size is set');
}


# Test loading configuration from a file
{
	my $config_file = File::Spec->catfile($Bin, File::Spec->updir(), 'config.yaml');

	my $obj = Database::test1->new(config_file => $config_file);

	cmp_ok($obj->{'directory'}, 'eq', '/', 'Can read configuration in from a file');
}
