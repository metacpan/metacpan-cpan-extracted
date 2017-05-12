#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Role::Tiny;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Importer::BagIt';
    use_ok $pkg;
}
require_ok $pkg;

my $importer = $pkg->new(
    bags => ['bags/demo01','bags/demo02'] , 
    verify => 1 , 
    include_payloads => 1 ,
    include_manifests => 1
);

isa_ok $importer, $pkg;

my $bags = $importer->to_array;

is(int(@$bags),2,'got two bags');

is($bags->[0]->{_id}, 'bags/demo01','got demo1');
is($bags->[1]->{_id}, 'bags/demo02','got demo2');

is($bags->[0]->{is_valid}, 1,'demo1 is valid');
is($bags->[1]->{is_valid}, 0,'demo2 is invalid');

ok(grep ( {$_ eq 'data/Catmandu-0.9204.tar.gz'} @{$bags->[0]->{payload_files}}),'reading payloads');

is($bags->[0]->{manifest}->{'data/Catmandu-0.9204.tar.gz'},'c8accb44741272d63f6e0d72f34b0fde','reading manifest');

done_testing 10;
