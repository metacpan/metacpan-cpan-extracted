#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "head" ), 'head command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'head command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'head command wants output' );

my @DATA = (
   [ 1, "one" ],
   [ 2, "two" ],
   [ 3, "three" ],
   [ 4, "four" ],
   [ 5, "five" ],
);

is(
   run_cmd( $cmd, "-n1", \@DATA ),
   [
      [ 1, "one" ],
   ],
   'head -n1' );

is(
   run_cmd( $cmd, "-n3", \@DATA ),
   [
      [ 1, "one" ], [ 2, "two" ], [ 3, "three" ],
   ],
   'head -n3' );

is(
   run_cmd( $cmd, "-n-1", \@DATA ),
   [
      [ 1, "one" ], [ 2, "two" ], [ 3, "three" ], [ 4, "four" ],
   ],
   'head -n-1' );

done_testing;
