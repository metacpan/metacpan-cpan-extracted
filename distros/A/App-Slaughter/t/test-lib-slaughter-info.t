#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Test we can load the information modules.  This
# skips the Windows implementation.
#
# Steve
# --
#


use strict;
use warnings;

use Test::More qw! no_plan !;

#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');


#
#  Find the location
#
my $dir = undef;

$dir = "./lib/Slaughter/Info"  if ( -d "./lib/Slaughter/Info" );
$dir = "../lib/Slaughter/Info" if ( -d "../lib/Slaughter/Info" );
ok( -d $dir, "We found the Info directory" );


#
#  Look for each module
#
foreach my $name ( sort( glob( $dir . "/*.pm" ) ) )
{
    if ( $name =~ /(.*)\/(.*)\.pm/ )
    {

        #
        #  Name of the module implementation file.
        #
        my $name = $2;

        #
        # Load the module
        #
        use_ok("Slaughter::Info::$name");
        require_ok("Slaughter::Info::$name");

        #
        # Create a new instance of the module.
        #
        my $module = "Slaughter::Info::$name";
        my $handle = $module->new();

        #
        #  Is the module the type we wish to be?
        #
        ok( $handle, "Calling the constructor succeeded." );
        isa_ok( $handle, $module );

        #
        #  Does the module implement our API?
        #
        ok( UNIVERSAL::can( $handle, "getInformation" ),
            "required method available - getInformation" );

        #
        # Setup an empty hash.
        #
        my $info;
        ok( keys %$info < 1,
            "Before calling Slaughter::Info::$module our hash is empty" );

        #
        # Call the function
        #
        $info = $handle->getInformation();
        ok( $info, "undef wasn't returned." );

        #
        # We should now find the hash has an entry or two.
        #
        ok( keys %$info >= 1,
            "After calling Slaughter::Info::$module our hash is updated" );

    }
}
