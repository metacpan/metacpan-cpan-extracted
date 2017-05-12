#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 14;
use File::Spec::Functions ':ALL';
use File::Remove 'clear';
use CPAN::Indexer::Mirror ();

my $root = catdir( 't', 'data' );
my $yaml = catfile( $root, 'mirror.yml'  );
my $json = catfile( $root, 'mirror.json' );
clear( $yaml, $json );
ok(   -d $root, 'Found the root dir' );
ok( ! -e $yaml, 'mirror.yaml does not exist' );
ok( ! -e $json, 'mirror.json does not exist' );

my $indexer = CPAN::Indexer::Mirror->new( root => $root );
isa_ok( $indexer, 'CPAN::Indexer::Mirror' );
ok( $indexer->run, '->run ok' );
ok( -f $yaml, 'Created mirror.yml'  );
ok( -f $json, 'Created mirror.json' );

# Check the contents of the YAML file
my $yamldata = YAML::Tiny::LoadFile( $yaml );
is( ref($yamldata), 'HASH', 'File is a hash' );
is(
	$yamldata->{version},
	'1.0',
	'version: correct',
);
is(
	$yamldata->{name},
	'Comprehensive Perl Archive Network',
	'name: correct',
);
is(
	$yamldata->{master},
	'http://www.cpan.org/',
	'master: correct',
);
like(
	$yamldata->{timestamp},
	qr/^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\dZ$/,
	'timestamp: correct',
);
is(
	ref($yamldata->{mirrors}),
	'ARRAY',
	'mirrors: ARRAY',
);

# Check that the URIs are canonicalized
is(
	scalar( grep { $_ eq 'http://cpan.mirror.ac.za/Foo/' } @{$yamldata->{mirrors}}),
	1,
	'Mirrors are normalized',
);
