#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "strptime" ), 'strptime command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'strptime command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'strptime command wants output' );

is(
   run_cmd( $cmd, "-f1 -U", [
      [ "2024-01-09T14:00:00", "first" ],
      [ "2024-01-09T14:05:00", "second" ],
      [ "2024-01-09T15:00:00", "third" ],
   ] ),
   [
      [ 1704808800, "first", ],
      [ 1704809100, "second", ],
      [ 1704812400, "third", ],
   ],
   'strptime -f1 -U' );

# Unspecified time fields are filled in as zeroes
is(
   run_cmd( $cmd, qq(-f1 -U --timefmt=%Y-%m-%d), [
      [ "2024-01-01", "first" ],
      [ "2024-01-05", "second" ],
      [ "2024-02-01", "third" ],
   ] ),
   [
      [ 1704067200, "first" ],
      [ 1704412800, "second" ],
      [ 1706745600, "third" ],
   ],
   'strptime -f1 -U --timefmt=%Y-%m-%d' );

done_testing;
