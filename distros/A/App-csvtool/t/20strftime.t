#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "strftime" ), 'strftime command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'strftime command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'strftime command wants output' );

is(
   run_cmd( $cmd, "-f1 -U", [
      [ 1704808800, "first", ],
      [ 1704809100, "second", ],
      [ 1704812400, "third", ],
   ] ),
   [
      [ "2024-01-09T14:00:00", "first" ],
      [ "2024-01-09T14:05:00", "second" ],
      [ "2024-01-09T15:00:00", "third" ],
   ],
   'strftime -f1 -U' );

done_testing;
