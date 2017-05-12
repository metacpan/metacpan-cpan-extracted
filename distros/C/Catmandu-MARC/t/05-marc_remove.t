#!/usr/bin/perl

use strict;
use warnings;
use warnings qw(FATAL utf8);
use utf8;

use Test::More;

use Catmandu::Importer::MARC;
use Catmandu::Fix;
use Catmandu::Fix::Inline::marc_map qw(:all);

my $fixer = Catmandu::Fix->new(fixes => [
                q|marc_remove('245')|,
                q|marc_remove('100a')|,
                q|marc_remove('082[1,1]a')|,
                q|marc_remove('050[,0]ab')|,
                ]);
my $importer = Catmandu::Importer::MARC->new( file => 't/camel.mrc', type => "ISO" );
my $record = $importer->first;

my $title  = marc_map($record,'245');
my $author = marc_map($record,'100');
my $dewey  = marc_map($record,'082');
my $lccn   = marc_map($record,'050');

ok  $title, 'got a title';
like $author , qr/^Martinsson, Tobias,1976-$/ , 'got an author';
ok $dewey, 'got a dewey';
ok $lccn , 'got a lccn';

my $fixed_record = $fixer->fix($record);

my $title2  = marc_map($fixed_record,'245');
my $author2 = marc_map($fixed_record,'100');
my $dewey2  = marc_map($fixed_record,'082');
my $lccn2   = marc_map($fixed_record,'050');

ok (!defined $title2, 'deleted the title');

like $author2 , qr/^1976-$/ , 'removed 100-a';

ok (defined $dewey2, 'didnt delete dewey');

ok (!defined $lccn2, 'deleted lccn');

done_testing 8;
