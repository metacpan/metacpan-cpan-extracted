#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "sum" ), 'sum command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'sum command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'sum command wants output' );

is(
   run_cmd( $cmd, "-f 1", [
      map { [ $_ ] } 1, 2, 3, 4, 5,
   ] ),
   [
      [ 15 ],
   ],
   'sum -f 1' );

is(
   run_cmd( $cmd, "-g 1 -f 2", [
      [ red => 1 ],
      [ red => 2 ],
      [ blue => 3 ],
      [ blue => 4 ],
   ] ),
   [
      [ red => 3 ],
      [ blue => 7 ],
   ],
   'sum -g 1 -f 2' );

done_testing;
