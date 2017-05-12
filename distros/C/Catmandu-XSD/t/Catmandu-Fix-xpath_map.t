#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use XML::Compile::Cache;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::xpath_map';
    use_ok $pkg;
}

my $schema = XML::Compile::Cache->new(
    [ 't/demo/mets/mets.xsd' ,
      't/demo/mets/xlink.xsd' ,
      't/demo/mods/mods-3-6.xsd' ,
      't/demo/mods/xlink.xsd' ,
      't/demo/mods/xml.xsd' ]
);

my $read  = $schema->compile(
            READER => '{http://www.loc.gov/METS/}mets' ,
            any_element => 'TAKE_ALL' ,
            );

my $data = $read->('t/demo/mets/mets.xml');

my $result = $pkg->new(
    'dmdSec.0.mdWrap.xmlData',
    'mods:titleInfo/mods:title',
    'brol',
    'mods',
    'http://www.loc.gov/mods/v3')->fix($data);

is $data->{brol} , 'Alabama blues';

done_testing 2;
