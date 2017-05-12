#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $fixer = Catmandu::Fix->new(fixes => [
		q|marc_decode_dollar_subfields()|,
		q|marc_map('200e','test')|
]);

# t/dollar_subfields.mrc a special prepared marc file containing $subfields als values
my $importer = Catmandu::Importer::MARC->new( file => 't/dollar_subfields.mrc', type => "RAW" );
my $record = $fixer->fix($importer->first);

like $record->{test}, qr/: Ermoupolis, Syros Island, Greece/, q|fix: marc_decode_dollar_subfields()|;

done_testing 1;
