#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;
use Catmandu::Importer::OAI;
use Test::More;
use TestParser;
use Data::Dumper;

my $handler = TestParser->new;

ok $handler;

if ($ENV{RELEASE_TESTING}) {
	my $importer = Catmandu::Importer::OAI->new(
	    url => 'http://lib.ugent.be/oai',
	    metadataPrefix => 'marcxml',
	    set => "eu",
	    handler => $handler,
	);

	my $record = $importer->first;

	ok $record , 'listrecords';

	is $record->{test}, 'ok' , 'got correct data';

    #---

	$importer = Catmandu::Importer::OAI->new(
	    url => 'http://lib.ugent.be/oai',
	    metadataPrefix => 'marcxml',
	    set => "eu",
	    handler => '+TestParser',
	);

	$record = $importer->first;

	ok $record , 'listrecords';

	is $record->{test}, 'ok' , 'got correct data';

    #---
    $importer = Catmandu::Importer::OAI->new(
	    url => 'http://lib.ugent.be/oai',
	    metadataPrefix => 'marcxml',
	    set => "eu",
	    handler => sub {
	    	return { test => 123 };
	    },
	);

	$record = $importer->first;

	ok $record , 'listrecords';

	is $record->{test}, '123' , 'got correct data';
}

done_testing;