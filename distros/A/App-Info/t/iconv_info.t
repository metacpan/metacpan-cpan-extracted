#!/usr/bin/perl -w

use strict;
use Test::More tests => 19;
use constant SKIP => 15;

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
BEGIN { use_ok('App::Info::Lib::Iconv') }

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $iconv = App::Info::Lib::Iconv->new( on_info => $info ), "Got Object");
is( $info->message, "Searching for iconv", "Check constructor info" );

SKIP: {
    # Skip tests?
    skip "libiconv not installed", SKIP unless $iconv->installed;

    # Check version.
    $iconv->version;
    is( $info->message, "Searching for 'iconv.h'", "Check version info" );
    is( $info->message, "Searching for include directory",
        "Check version info again" );

    $iconv->version;
    ok( ! defined $info->message, "No info" );
    $iconv->major_version;
    ok( ! defined $info->message, "Still No info" );

    # Check major version.
    ok( $iconv = App::Info::Lib::Iconv->new( on_info => $info ),
        "Got Object 2");
    $info->message;
    $iconv->major_version;
    is( $info->message, "Searching for 'iconv.h'", "Check major info" );
    is( $info->message, "Searching for include directory",
        "Check major info again" );

    # Check minor version.
    ok( $iconv = App::Info::Lib::Iconv->new( on_info => $info ),
        "Got Object 3");
    $info->message; # Throw away constructor message.
    $iconv->minor_version;
    is( $info->message, "Searching for 'iconv.h'", "Check minor info" );
    is( $info->message, "Searching for include directory",
        "Check minor info again" );

    # Check dir methods.
    ok( $iconv = App::Info::Lib::Iconv->new( on_info => $info ),
        "Got Object 4");
    $info->message; # Throw away constructor message.
    $iconv->bin_dir;
    is( $info->message, "Searching for bin directory", "Check bin info" );
    $iconv->inc_dir;
    is( $info->message, "Searching for include directory", "Check inc info" );
    $iconv->lib_dir;
    is( $info->message, "Searching for library directory", "Check lib info" );
    $iconv->so_lib_dir;
    is( $info->message, "Searching for shared object library directory",
        "Check so lib info" );
}

__END__
