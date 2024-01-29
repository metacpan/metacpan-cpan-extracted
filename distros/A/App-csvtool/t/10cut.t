#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "cut" ), 'cut command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'cut command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'cut command wants output' );

my @DATA = (
   [ 1,2,3 ],
   [ 4,5,6 ],
);

is(
   run_cmd( $cmd, "-f1", \@DATA ),
   [
      [ 1 ], [ 4 ],
   ],
   'cut -f1' );

is(
   run_cmd( $cmd, "-f2,3", \@DATA ),
   [
      [ 2,3 ], [ 5,6 ],
   ],
   'cut -f2,3' );

done_testing;
