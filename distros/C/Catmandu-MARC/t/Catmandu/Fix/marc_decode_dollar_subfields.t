#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_decode_dollar_subfields';
    use_ok $pkg;
}

require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => [
		q|marc_decode_dollar_subfields()|,
		q|marc_map('200e','test')|
]);

# t/dollar_subfields.mrc a special prepared marc file containing $subfields als values
my $importer = Catmandu::Importer::MARC->new( file => 't/dollar_subfields.mrc', type => "RAW" );
my $record = $fixer->fix($importer->first);

like $record->{test}, qr/: Ermoupolis, Syros Island, Greece/, q|fix: marc_decode_dollar_subfields()|;

done_testing;
