#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "uniq" ), 'uniq command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'uniq command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'uniq command wants output' );

my @DATA = (
   [ 1, "one" ],
   [ 1, "one again" ],
   [ 2, "two" ],
   [ 3, "three" ],
);

is(
   run_cmd( $cmd, "", \@DATA ),
   [
      [ 1, "one" ], [ 2, "two" ], [ 3, "three" ],
   ],
   'uniq (default)' );

is(
   run_cmd( $cmd, "-f2", \@DATA ),
   [
      [ 1, "one" ], [ 1, "one again" ], [ 2, "two" ], [ 3, "three" ],
   ],
   'uniq -f2' );

done_testing;
