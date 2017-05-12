#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Some simple tests that validate the Slaughter code is correct.
#
#  Here we use the two API methods:
#
#    UserExists +
#    UserDetails
#
#  We attempt to fetch the username we're currently running under,
# fetching that from the $USER environmental variable.
#
#


use strict;
use Test::More qw! no_plan !;


my $SELF = getlogin || getpwuid($<) || $ENV{ 'USER' };

#
#  Ensure we have a user we're running as.
#
ok( length($SELF) > 0, "We have a user" );

#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');

#
#  Ensure the user exists
#
my $user = undef;
$user = UserExists( User => $SELF );
ok( $user, "We found a username" );

#
#  Get the details
#
$user = UserDetails( User => $SELF );
is( $user->{ 'Login' }, $SELF, "The username matches the environment" );
ok( -d $user->{ 'Home' }, "The username has a home directory that exists" );
