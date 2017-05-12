#!/usr/bin/perl -w -Ilib/ -I../lib/
#
#  Simple test program to ensure that we can load modules and hash files.
#
#  We compare the results with that obtained by Slaughter::Private, and
# the unix "sha1sum" binary - if available.
#
# Steve
# --

use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw/ tempfile /;



#
#  Make our private module available
#
BEGIN {use_ok('Slaughter::Private');}
require_ok('Slaughter::Private');



#
#  Create a temporary file.
#
my ( $fh, $filename ) = tempfile();

ok( -e $filename, "We created a temporary file" );
is( -s $filename, 0, "The file is empty" );


#
#  Create some stub content
#
open( my $handle, ">", $filename ) or
  die "Failed to open $filename - $!";

print $handle <<EOF;
Steve Kemp Testing Hashes.
Hashes are nice.   They're like signatures.
But less messy.

(No ink!)

EOF
close($handle);

#
#  OK run a sanity check
#
if ( -x "/usr/bin/sha1sum" )
{
    my $validation = `sha1sum $filename | awk '{print \$1}'`;
    chomp($validation);

    is( $validation,
        "b57e303d4466e3aac4ea20f3935fb6d77951e2c4",
        "SHA1Sum utility confirmed the temporary file has the hash we expect" );
}


#
#  Attempt to test both digest modules in turn.
#
foreach my $module (qw! Digest::SHA Digest::SHA1 !)
{

    #
    #  Attempt to load the module
    #
    my $eval = "use $module;";
    ## no critic (Eval)
    eval($eval);
    ## use critic

    #
    #  Skip this modning if we failed.
    #
    if ($@)
    {

        #
        #  NOTE:  This should be "0" rather than "1".
        #
        ok( 1, "WARNING: Failed to load $module" );
        next;
    }

    ok( 1, "Loaded module: $module" );
    ok( UNIVERSAL::can( $module, 'new' ),     "module implements new()" );
    ok( UNIVERSAL::can( $module, 'addfile' ), "module implements addfile()" );
    ok( UNIVERSAL::can( $module, 'hexdigest' ),
        "module implements hexdigest()" );

    #
    #  Hash the file
    #
    my $hash = $module->new;
    open( my $handle, "<", $filename ) or
      die "Failed to open $filename - $!";
    $hash->addfile($handle);
    close($handle);

    #
    #  Compare the hash we received with the one we've pre-calculated.
    #
    is( $hash->hexdigest(),
        "b57e303d4466e3aac4ea20f3935fb6d77951e2c4",
        "Our sample data received the correct result" );

    #
    #  Compare the pre-calculated hash against the result returned
    # by Slaughter::Private
    #
    is( "b57e303d4466e3aac4ea20f3935fb6d77951e2c4",
        Slaughter::Private::checksumFile($filename),
        "Slaughter::Private agrees with the $module result." );
}

#
#  Cleanup
#
unlink($filename);
ok( !-e $filename, "Post-test the temporary file is gone" );

