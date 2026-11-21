#!/usr/bin/perl

use v5.26;
use warnings;

use feature qw( signatures );
no warnings qw( experimental::signatures );

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "extend" ), 'extend command exists' );

my $toolpkg = $cmd->package;

ok( $toolpkg->WANT_READER, 'extend command wants reader' );
ok( $toolpkg->WANT_OUTPUT, 'extend command wants output' );

my @DATA = (
   [ 1, 2 ],
   [ 3, 4 ],
   [ 5, 6 ],
);

is(
   run_cmd( $cmd, '1', \@DATA ),
   [
      [ 1, 2, 1 ],
      [ 3, 4, 1 ],
      [ 5, 6, 1 ],
   ],
   'extend (1)' );

is(
   run_cmd( $cmd, '"F[1] + 10"', \@DATA ),
   [
      [ 1, 2, 11 ],
      [ 3, 4, 13 ],
      [ 5, 6, 15 ],
   ],
   'extend (F[1] + 10)' );

done_testing;
