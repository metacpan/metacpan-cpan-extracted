#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use JSON::XS ();
use Catmandu;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Exporter::Stat';
    use_ok $pkg;
}
require_ok $pkg;

my $data = [
 {"name"=>"patrick"} ,
 {"name"=>"patrick"} ,
 {"name"=>"patrick"} ,
 {"name"=>undef} ,
 {"age"=>"44"} ,
 {"foo"=>undef} ,
];

my $file = "";

my $exporter = $pkg->new(fields => 'name,age,x,foo' , file => \$file);

isa_ok $exporter, $pkg;

$exporter->add($_) for @$data;
$exporter->commit;

ok $file , "answer ok";

is($exporter->count, 6, "Count ok");

my $importer = Catmandu->importer('JSON', file => 't/big.json');

$file = "";
$exporter = $pkg->new(file => \$file, as => 'JSON');

isa_ok $exporter, $pkg;

$exporter->add_many($importer);
$exporter->commit;

ok $file , "answer ok";

$data = Catmandu->importer('JSON', file => \$file)->to_array;

ok $data , "got json";

my @uniq = grep({ $_->{name} eq 'uniq' }  @$data);

is $uniq[0]->{count}     , 1000;
is $uniq[0]->{'uniq%'}   , "100.0";
like $uniq[0]->{entropy}   , qr{10.0/10.0};

my @half = grep({ $_->{name} eq 'half' }  @$data);

is $half[0]->{count}     , 500;
like $half[0]->{'uniq%'} , qr/^100\./;
like $half[0]->{entropy}   , qr{5.5/10.0};

my @quarter = grep({ $_->{name} eq 'quarter' }  @$data);

is $quarter[0]->{count}     , 250;
like $quarter[0]->{'uniq%'} , qr/^100\./;
like $quarter[0]->{entropy}   , qr{2.8/10.0};

my @double = grep({ $_->{name} eq 'double' }  @$data);

is $double[0]->{count}     , 2000;
like $double[0]->{'uniq%'} , qr/^0\.1/;
like $double[0]->{entropy}   , qr{1.0/11.0};

done_testing 20;
