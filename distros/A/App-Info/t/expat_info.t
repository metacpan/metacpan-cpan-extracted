#!/usr/bin/perl -w

use strict;
use Test::More tests => 22;
use constant SKIP => 18;

##############################################################################
# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    } else {
        unshift @INC, 't/lib', 'lib';
    }
}
chdir 't';
use EventTest;

##############################################################################
BEGIN { use_ok('App::Info::Lib::Expat') }

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $expat = App::Info::Lib::Expat->new( on_info => $info ), "Got Object");
is( $info->message, "Searching for Expat libraries", "Check constructor info" );

SKIP: {
    # Skip tests?
    skip "Expat not installed", SKIP unless $expat->installed;

    # Check version.
    $expat->version;
    is( $info->message, "Searching for 'expat.h'", "Check version info" );
    is( $info->message, "Searching for include directory",
        "Check version info again" );

    $expat->version;
    ok( ! defined $info->message, "No info" );
    $expat->major_version;
    ok( ! defined $info->message, "Still No info" );

    # Check major version.
    ok( $expat = App::Info::Lib::Expat->new( on_info => $info ),
        "Got Object 2");
    $info->message;
    $expat->major_version;
    is( $info->message, "Searching for 'expat.h'", "Check major info" );
    is( $info->message, "Searching for include directory",
        "Check major info again" );

    # Check minor version.
    ok( $expat = App::Info::Lib::Expat->new( on_info => $info ),
        "Got Object 3");
    $info->message; # Throw away constructor message.
    $expat->minor_version;
    is( $info->message, "Searching for 'expat.h'", "Check minor info" );
    is( $info->message, "Searching for include directory",
        "Check minor info again" );

    # Check patch version.
    ok( $expat = App::Info::Lib::Expat->new( on_info => $info ),
        "Got Object 4");
    $info->message; # Throw away constructor message.
    $expat->patch_version;
    is( $info->message, "Searching for 'expat.h'", "Check patch info" );
    is( $info->message, "Searching for include directory",
        "Check patch info again" );

    # Check dir methods.
    ok( $expat = App::Info::Lib::Expat->new( on_info => $info ),
        "Got Object 5");
    $info->message; # Throw away constructor message.
    $expat->bin_dir;
    ok( ! defined $info->message, "Check bin info" );
    $expat->inc_dir;
    is( $info->message, "Searching for include directory", "Check inc info" );
    $expat->lib_dir;
    ok( ! defined $info->message, "Check lib info" );
    $expat->so_lib_dir;
    is( $info->message, "Searching for shared object library directory",
        "Check so lib info" );
}

__END__
