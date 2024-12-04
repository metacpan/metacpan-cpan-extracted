#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "count" ), 'count command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'count command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'count command wants output' );

is(
   run_cmd( $cmd, "-f 1", [
      map { [ $_ ] } qw( a b c d e ),
   ] ),
   [
      map { [ $_, 1 ] } qw( a b c d e ),
   ],
   'count -f 1 on unique values' );

is(
   run_cmd( $cmd, "-f 1", [
      map { [ $_ ] } qw( a b a b c ),
   ] ),
   [
      [ a => 2 ], [ b => 2 ], [ c => 1 ],
   ],
   'count -f 1 on repeated values' );

done_testing;
