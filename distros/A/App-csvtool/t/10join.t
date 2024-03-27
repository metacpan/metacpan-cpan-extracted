#!/usr/bin/perl

use v5.26;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;

use Commandable::Invocation;

ok( my $cmd = finder->find_command( "join" ), 'join command exists' );

my $toolpkg = $cmd->package;

is( $toolpkg->WANT_READER, 2, 'join command wants 2 readers' );
ok( $toolpkg->WANT_OUTPUT, 'join command wants output' );

my @DAT2 = (
   [ 1, "one" ],
   [ 2, "two" ],
   [ 3, "three" ],
);

is(
   run_cmd( $cmd, "-f1", [ [ 2, "second" ], [ 4, "fourth" ] ], \@DAT2 ),
   [ [ 2, "second", "two" ], [ 4, "fourth" ] ],
   'join -f1"' );

is(
   run_cmd( $cmd, "-13 -21", [ [ "second", "is", 2 ] ], \@DAT2 ),
   [ [ "second", "is", "2", "two" ] ],
   'join -13 -21"' );

done_testing;
