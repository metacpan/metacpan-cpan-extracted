#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $::loaded;}
require 'dumpvar.pl';
use strict;
use Carp;
use C::Scan;

$::loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

open(FILE,">.test") or die;
select(FILE);

my ($c,$daf,$dnaf,$da,$dna,$t,$td,$tdh,$fi,$fde,$mde,$vde,$fdec,$tdw);
my $test = 2;

#$SIG{__WARN__} = sub {confess @_;};

$c = new C::Scan 'filename' => 'ctest/test.c';

$daf = $c->get('defines_args_full');

$dnaf = $c->get('defines_no_args_full');

dumpValue({defines_no_args_full => $dnaf, defines_args_full => $daf});

print STDOUT "ok $test\n";
$test++;

$c = new C::Scan 'filename' => 'ctest/test.c';
$c->set('Defines' => '-DABC');

print FILE "-DABC includes: @{$c->get('includes')}\n";

print STDOUT "ok $test\n";
$test++;

$c = new C::Scan 'filename' => 'ctest/test.c';
$c->set('Defines' => '-DABCD');

print "-DABCD includes: @{$c->get('includes')}\n";

print STDOUT "ok $test\n";
$test++;

$da = $c->get('defines_args');

print STDOUT "ok $test\n";
$test++;

$dna = $c->get('defines_no_args');

print STDOUT "ok $test\n";
$test++;

$t = $c->get('typedef_texts');

print STDOUT "ok $test\n";
$test++;

$td = $c->get('typedefs_maybe');

print STDOUT "ok $test\n";
$test++;

$tdh = $c->get('typedef_hash');

print STDOUT "ok $test\n";
$test++;

$tdw = $c->get('typedefs_whited');

print STDOUT "ok $test\n";
$test++;

$fi = $c->get('inlines');

print STDOUT "ok $test\n";
$test++;

$fde = $c->get('fdecls');

print STDOUT "ok $test\n";
$test++;

$mde = $c->get('mdecls');

print STDOUT "ok $test\n";
$test++;

$vde = $c->get('vdecls');

print STDOUT "ok $test # vdecl\n";
$test++;

$fdec = $c->get('parsed_fdecls');

print STDOUT "ok $test\n";
$test++;

my $tds = $c->get('typedef_structs');

print STDOUT "ok $test\n";
$test++;

my $vh = $c->get('vdecl_hash');

print STDOUT "ok $test\n";
$test++;

select(FILE);

dumpValue({defines_no_args => $dna, defines_args => $da, 
	   typedef_texts => $t, typedefs_maybe => $td, inlines => $fi, 
	   mdecls => $mde, vdecls => $vde, fdecls => $fde, 
	   parsed_fdecls => $fdec, typedef_hash => $tdh,
	   typedef_whited => $tdw, typedef_structs => $tds,
	   vdecl_hash => $vh});


print STDOUT "ok $test\n";
$test++;

close(FILE);

print STDOUT "See file .test for output ...\n";
