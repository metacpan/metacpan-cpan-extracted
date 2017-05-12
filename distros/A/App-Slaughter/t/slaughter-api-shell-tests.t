#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Some simple tests that validate the Slaughter code is correct.
#
#  Here we use the single API method:
#
#    RunCommand
#
# Steve
# --
#


use strict;
use Test::More qw! no_plan !;
use File::Temp qw/ tempfile /;

#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');


#
#  Create a temporary file.
#
my ( $fh, $filename ) = tempfile();

ok( -e $filename, "We created a temporary file" );
is( -s $filename, 0, "The file is empty" );


#
# Run the command "true"
#
my $ret = RunCommand( Cmd => "true > $filename" );
is( $ret,         0, "The execution of 'true' succeeded" );
is( -s $filename, 0, "The execution if 'true' produced no output" );


#
# Run the command "false"
#
$ret = RunCommand( Cmd => "false > $filename" );
ok( $ret || 1,
    "The execution of 'false' failed, as expected - based on return code" );
is( -s $filename, 0, "The execution if 'false' produced no output" );


#
# Run a command which will not exist
#
ok( !-x "/missing/command/or/file", "Our sample file doesn't exist: great!" );
$ret = RunCommand( Cmd => "/missing/command/or/file 2> $filename" );
ok( $ret || 1, "The execution of missing command failed, as expected" );
ok( -s $filename, "Our output file grew - showing an error" );

#
#  This test will test that the output of the failed command contains
# a message from the shell along the lines of:
#
#    /missing/command/or/file: not found
#    /missing/command/or/file: No such file or directory
#
#
open( my $file, "<", $filename );
while ( my $line = <$file> )
{
    ok( $line =~ /(no such file|not found)/i,
        "Output file contained an error" );
}
close($file);



#
#  Cleanup
#
unlink($filename);
ok( !-e $filename, "Post-testing our temporary file is gone" );
