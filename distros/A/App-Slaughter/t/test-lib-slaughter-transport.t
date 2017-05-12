#!/usr/bin/perl -w -I../lib -I./lib/
#
#  Test we can load the transport modules, and that they offer
# the complete/expected API.
#
# Steve
# --
#


use strict;
use Test::More qw! no_plan !;

#
#  Load the Slaughter module
#
BEGIN {use_ok('Slaughter');}
require_ok('Slaughter');


#
#  Find the location of the transport modules on disk.
#
my $dir = undef;

$dir = "./lib/Slaughter/Transport"  if ( -d "./lib/Slaughter/Transport" );
$dir = "../lib/Slaughter/Transport" if ( -d "../lib/Slaughter/Transport" );

ok( -d $dir, "We found the transport directory." );


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
        use_ok("Slaughter::Transport::$name");
        require_ok("Slaughter::Transport::$name");

        #
        # Create a new instance of the module.
        #
        my $module = "Slaughter::Transport::$name";
        my $handle = $module->new();

        #
        #  Is the module the type we wish to be?
        #
        ok( $handle, "Calling the constructor succeeded." );
        isa_ok( $handle, $module );

        #
        # Test that our required methods are present
        #
        foreach my $method (qw! error fetchContents isAvailable name new !)
        {
            ok( UNIVERSAL::can( $handle, $method ),
                "required method available - $method" );
        }

        #
        # Call the "name" method, which is always safe, and ensure it returns
        # something sane.
        #
        my $reported = $handle->name();
        ok( $reported, "We received output from name()." );
        is( $reported, $name, "The name matches what we expect." );

        #
        #
        # Sanity check by ensuring that a made-up method name is
        # invalid.
        #
        # This ensures we're not misusing UNIVERSAL:can
        #
        ok( !UNIVERSAL::can( $handle, "not_present" ),
            "Random methods aren't present." );
    }
}
