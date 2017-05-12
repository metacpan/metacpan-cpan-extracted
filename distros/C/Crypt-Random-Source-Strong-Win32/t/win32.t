#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 13;
use Test::Exception;

my $class;
BEGIN { $class = 'Crypt::Random::Source::Strong::Win32' };

use ok $class;

our $DATA_SIZE = 1024;

sub test_source {
    my $prefix = shift || '';
    my $source;
    isa_ok($source = $class->new, $class, "${prefix}source");
    my $data1;
    lives_ok { $data1 = $source->get($DATA_SIZE) } "${prefix}get data once";
    cmp_ok(length($data1), '==', $DATA_SIZE, 
           "${prefix}data1 is the right length");
    my $data2;
    lives_ok { $data2 = $source->get($DATA_SIZE) } 
             "${prefix}get data twice";
    cmp_ok(length($data2), '==', $DATA_SIZE, 
           "${prefix}data2 is the right length");
    cmp_ok($data1, 'ne', $data2, "${prefix}data1 and data2 are not equal");
}

test_source();
$Crypt::Random::Source::Strong::Win32::IS_WIN2K = 1;
test_source('Win2K: ');
