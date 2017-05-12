#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;
use Test::Memory::Cycle;

BEGIN {
	use_ok('Compress::LZW::Progressive::Dict');
}

use Compress::LZW::Progressive::Dict;

my $dict = Compress::LZW::Progressive::Dict->new();

isa_ok($dict, 'Compress::LZW::Progressive::Dict');

#print "Adding to dict\n";

my $code = $dict->add('stream');
ok( $code == 256, "Adding 'stream' phrase" );
$code = $dict->add('stream:features');
ok( $code == 257, "Adding 'stream:features' phrase" );

#print "Searching for matching code\n";
my $str = 'stream:stream xmlns=';
my @char = split //, $str;

$code = $dict->code_matching_array(\@char);
ok( $code == 256, "Finding code matching string '$str'" );

my $success = $dict->delete_code(256);
ok ( $success, "Deleting 'stream' code");

$code = $dict->code_matching_array(\@char);
ok( $code == ord 's', "Finding code matching string '$str'" );

$success = $dict->delete_code(257);
ok ( $success, "Deleting 'stream:features' code");

$code = $dict->code_matching_array(\@char);
ok( $code == ord 's', "Finding code matching string '$str'" );

$dict->add('A0');
$code = $dict->code_matching_array(['A', 'W']);

ok( $code == ord 'A', "Finding code matching 'AW' with dict containing 'A0'" );

memory_cycle_ok($dict);
