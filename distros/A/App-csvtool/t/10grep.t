#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "grep" ), 'grep command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'grep command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'grep command wants output' );

my @DATA = (
   [ 1, "one" ],
   [ 50, "fifty" ],
   [ 5, "five" ],
   [ 10, "ten" ]
);

is(
   run_cmd( $cmd, "1", \@DATA ),
   [
      [ 1, "one" ], [ 10, "ten" ],
   ],
   'grep (default)' );

is(
   run_cmd( $cmd, "-f2 fi", \@DATA ),
   [
      [ 50, "fifty" ], [ 5, "five" ],
   ],
   'grep -f2' );

is(
   run_cmd( $cmd, "-v 1", \@DATA ),
   [
      [ 50, "fifty" ], [ 5, "five" ],
   ],
   'grep -v' );

is(
   run_cmd( $cmd, "-i -f2 FI", \@DATA ),
   [
      [ 50, "fifty" ], [ 5, "five" ],
   ],
   'grep -i' );

done_testing;
