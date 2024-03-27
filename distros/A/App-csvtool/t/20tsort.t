#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "tsort" ), 'tsort command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'tsort command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'tsort command wants output' );

# Use a format whose strings wouldn't be sorted alphabetically, to demonstrate
# that the sort order works
is(
   run_cmd( $cmd, qq(-f1 --timefmt=%Y/%b/%d), [
      [ "2024/Apr/01", "second" ],
      [ "2024/Dec/01", "fifth" ],
      [ "2024/Feb/01", "first" ],
      [ "2024/Jun/01", "third" ],
      [ "2024/Oct/01", "fourth" ],
   ] ),
   [
      [ "2024/Feb/01", "first" ],
      [ "2024/Apr/01", "second" ],
      [ "2024/Jun/01", "third" ],
      [ "2024/Oct/01", "fourth" ],
      [ "2024/Dec/01", "fifth" ],
   ],
   'tsort -f1 --timefmt=%Y/%m/%d' );

done_testing;
