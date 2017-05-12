#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Data::DPath::Context;
use List::Util 'min';

BEGIN {
        if ($] < 5.010) {
                plan skip_all => "Perl 5.010 required for the smartmatch overloaded tests. This is ".$];
        }
}

ok (1, "dummy");

my $chunks;
my $threadcount;

# ==================== 2 cpus ====================

local $Data::DPath::Context::THREADCOUNT = 2;
my $nr_chunks;
my $expected;

$chunks = Data::DPath::Context::_splice_threads([1..6]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

$chunks = Data::DPath::Context::_splice_threads([1..7]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

$chunks = Data::DPath::Context::_splice_threads([1..8]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

# ==================== 3 cpus ====================

local $Data::DPath::Context::THREADCOUNT = 3;

$chunks = Data::DPath::Context::_splice_threads([1..6]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

$chunks = Data::DPath::Context::_splice_threads([1..7]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

$chunks = Data::DPath::Context::_splice_threads([1..8]);
$nr_chunks = scalar @$chunks;
is($nr_chunks, $Data::DPath::Context::THREADCOUNT, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT);

# ==================== 12 cpus ====================

local $Data::DPath::Context::THREADCOUNT = 12;

my @data24 = (0..24-1);

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = min($Data::DPath::Context::THREADCOUNT, scalar @data24);
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected");

# ==================== mix cpus ====================

local $Data::DPath::Context::THREADCOUNT = 48;

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = min($Data::DPath::Context::THREADCOUNT, scalar @data24);
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected");

local $Data::DPath::Context::THREADCOUNT = 7;

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = 6;
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected (sic, under-utilized)");

my @data32 = (0..32-1);

local $Data::DPath::Context::THREADCOUNT = 10;

$chunks    = Data::DPath::Context::_splice_threads(\@data32);
$nr_chunks = scalar @$chunks;
$expected  = 8;
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected (sic, under-utilized)");

local $Data::DPath::Context::THREADCOUNT = 5;

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = min($Data::DPath::Context::THREADCOUNT, scalar @data24);
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected");

local $Data::DPath::Context::THREADCOUNT = 1;

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = min($Data::DPath::Context::THREADCOUNT, scalar @data24);
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected");

local $Data::DPath::Context::THREADCOUNT = 0;

$chunks    = Data::DPath::Context::_splice_threads(\@data24);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected (0 cpus)");

my @data1 = (0);

local $Data::DPath::Context::THREADCOUNT = 0;
$chunks = Data::DPath::Context::_splice_threads(\@data1);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected (0 cpus)");

local $Data::DPath::Context::THREADCOUNT = 1;
$chunks = Data::DPath::Context::_splice_threads(\@data1);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "threads/chunks == ". $Data::DPath::Context::THREADCOUNT . " / $expected");

my @data0 = ();

local $Data::DPath::Context::THREADCOUNT = 0;
$chunks = Data::DPath::Context::_splice_threads(\@data0);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "no multi threads on empty set (". $Data::DPath::Context::THREADCOUNT." cpus)");

local $Data::DPath::Context::THREADCOUNT = 1;
$chunks = Data::DPath::Context::_splice_threads(\@data0);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "no multi threads on empty set (". $Data::DPath::Context::THREADCOUNT." cpus)");

local $Data::DPath::Context::THREADCOUNT = 12;
$chunks = Data::DPath::Context::_splice_threads(\@data0);
$nr_chunks = scalar @$chunks;
$expected  = 1;
is($nr_chunks, $expected, "no multi threads on empty set (". $Data::DPath::Context::THREADCOUNT." cpus)");

done_testing();
