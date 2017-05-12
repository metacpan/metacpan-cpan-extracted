#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Some simple tests that validate the Slaughter code is correct.
#
#  Here we use the API methods:
#
#    LogMessage
#
#


use strict;
use Test::More qw! no_plan !;


#
#  This will be populated.
#
our %LOG;



#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');


#
#  Ensure the log array is empty.
#
is( scalar keys %LOG, 0, "Our log-array is empty" );

#
#  Log a couple of messages.
#
LogMessage( Level => "debug", Message => "Steve" );
LogMessage( Level => "debug", Message => "Kemp" );


#
#  Ensure the log array is non-empty.
#
is( scalar keys %LOG, 1, "Our log-array is no longer empty." );


#
#  We have entries with the level "debug" only so foar
#
my @levels = keys %LOG;
is( scalar @levels, 1,       "We have only one type of debug level" );
is( $levels[0],     "debug", "The type of debug level is correct" );


#
#  Add two more logged messages, with different levels
#
LogMessage( Level => "alert", Message => "Kemp" );
LogMessage( Level => "panic", Message => "Kemp" );


#
#  Sorted levels
#
@levels = sort keys %LOG;
is( scalar @levels, 3, "We have now got three type of debug level" );

#
#  See that they are what we set.
#
is( $levels[0], "alert", "The first level is correct" );
is( $levels[1], "debug", "The second level is correct" );
is( $levels[2], "panic", "The third level is correct" );
