#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "filter" ), 'filter command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'filter command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'filter command wants output' );

my @DATA = (
   [ 1, "one" ],
   [ 50, "fifty" ],
   [ 5, "five" ],
   [ 10, "ten" ]
);

is(
   run_cmd( $cmd, '1', \@DATA ),
   [
      [ 1, "one" ],
      [ 50, "fifty" ],
      [ 5, "five" ],
      [ 10, "ten" ],
   ],
   'filter (1)' );  # TODO: 'true' token

is(
   run_cmd( $cmd, '"F[1] < 10"', \@DATA ),
   [
      [ 1, "one" ],
      [ 5, "five" ],
   ],
   'filter (F[1] < 10)' );

done_testing;
