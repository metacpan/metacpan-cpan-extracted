#!perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Importer::MARC;
use Catmandu::Fix;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::marc_append';
    use_ok $pkg;
}

require_ok $pkg;

my $fixer = Catmandu::Fix->new(fixes => [q|marc_append('100','.')|,q|marc_map('100','test')|]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
my $record = $fixer->fix($importer->first);

like $record->{test}, qr/^Martinsson, Tobias,1976-\.$/, q|fix: marc_append('100','.')|;

done_testing;
