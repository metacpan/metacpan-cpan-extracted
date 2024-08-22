#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "smudge" ), 'smudge command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'smudge command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'smudge command wants output' );

is(
   # No filters just passes data
   run_cmd( $cmd, "", [
      [ "one",   "1", "1.0" ],
      [ "two",   "2", "1.1" ],
      [ "three", "3", "1.2" ],
   ] ),
   [
      [ "one",   "1", "1.0" ],
      [ "two",   "2", "1.1" ],
      [ "three", "3", "1.2" ],
   ],
   'smudge (empty)' );

is(
   run_cmd( $cmd, "-F 1:avg2", [
      map { [ $_ ] } 1 .. 5
   ] ),
   [
      map { [ $_ ] } 1, 1.5, 2.5, 3.5, 4.5,
   ],
   'smudge -F 1:avg2' );

is(
   run_cmd( $cmd, "-F 1:mid3", [
      map { [ $_ ] } ( 1, 3, 5 ) x 4,
   ] ),
   [
      map { [ $_ ] } 1, 1, ( 3 ) x 10,
   ],
   'smudge -F 1:mid3' );

is(
   run_cmd( $cmd, "-F 1:ravg5", [
      map { [ $_ ] } 1, ( 2 ) x 10,
   ] ),
   [
      # numbers are approximate but should be good enough
      map { [ Test2::Tools::Compare::within($_, 0.001) ] }
         1, 1.031, 1.061, 1.091, 1.119, 1.147, 1.173, 1.199, 1.224, 1.249, 1.272,
   ],
   'smudge -F 1:ravg5' );

is(
   run_cmd( $cmd, "-F 1,2:avg3", [
      map { [ $_, $_+1 ] } 1 .. 5
   ] ),
   [
      map { [ $_, $_+1 ] } 1, 1.5, 2, 3, 4,
   ],
   'smudge -F 1,2:avg3' );

done_testing;
