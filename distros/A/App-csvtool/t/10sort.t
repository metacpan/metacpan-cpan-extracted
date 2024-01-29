#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "sort" ), 'sort command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'sort command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'sort command wants output' );

my @DATA = (
   [ 1, "one" ],
   [ 50, "fifty" ],
   [ 5, "five" ],
   [ 10, "ten" ]
);

is(
   run_cmd( $cmd, "", \@DATA ),
   [
      [ 1, "one" ], [ 10, "ten" ], [ 5, "five" ], [ 50, "fifty" ],
   ],
   'sort (default)' );

is(
   run_cmd( $cmd, "-n", \@DATA ),
   [
      [ 1, "one" ], [ 5, "five" ], [ 10, "ten" ], [ 50, "fifty" ],
   ],
   'sort -n' );

is(
   run_cmd( $cmd, "-r", \@DATA ),
   [
      [ 50, "fifty" ], [ 5, "five" ], [ 10, "ten" ], [ 1, "one" ],
   ],
   'sort -r' );

is(
   run_cmd( $cmd, "-rn", \@DATA ),
   [
      [ 50, "fifty" ], [ 10, "ten" ], [ 5, "five" ], [ 1, "one" ],
   ],
   'sort -rn' );

is(
   run_cmd( $cmd, "-f2", \@DATA ),
   [
      [ 50, "fifty" ], [ 5, "five" ], [ 1, "one" ], [ 10, "ten" ],
   ],
   'sort -rn' );

done_testing;
