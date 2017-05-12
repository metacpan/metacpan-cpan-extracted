#!/usr/bin/perl -w

use strict;
use Test::More tests => 22;
use constant SKIP => 18;

##############################################################################
# Make sure that we can use the stuff that's in our local lib directory.
BEGIN {
    unshift @INC, 't/lib', 'lib';
}
chdir 't';
use EventTest;

##############################################################################
BEGIN { use_ok('App::Info::Lib::OSSPUUID') }

my $ext = $^O eq 'MSWin32' ? '[.]exe' : '';

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $uuid = App::Info::Lib::OSSPUUID->new( on_info => $info ),
    "Got Object");
is( $info->message, "Looking for uuid-config", "Check constructor info" );

SKIP: {
    # Skip tests?
    skip 'OSSP UUID Library not installed', SKIP unless $uuid->installed;

    # Check name.
    $uuid->name;
    like($info->message, qr/^Executing `".*uuid-config$ext" --version`$/,
         "Check name info" );
    $uuid->name;
    ok( ! defined $info->message, "No info" );
    $uuid->version;
    ok( ! defined $info->message, "Still No info" );

    # Check version.
    ok( $uuid = App::Info::Lib::OSSPUUID->new( on_info => $info ),
        "Got Object 2");
    $info->message; # Throw away constructor message.
    $uuid->version;
    like($info->message, qr/^Executing `".*uuid-config$ext" --version`$/,
        "Check version info" );

    $uuid->version;
    ok( ! defined $info->message, "No info" );
    $uuid->major_version;
    ok( ! defined $info->message, "Still No info" );

    # Check major version.
    ok( $uuid = App::Info::Lib::OSSPUUID->new( on_info => $info ),
        "Got Object 3");
    $info->message; # Throw away constructor message.
    $uuid->major_version;
    like($info->message, qr/^Executing `".*uuid-config$ext" --version`$/,
        "Check major info" );

    # Check minor version.
    ok( $uuid = App::Info::Lib::OSSPUUID->new( on_info => $info ),
        "Got Object 4");
    $info->message; # Throw away constructor message.
    $uuid->minor_version;
    like($info->message, qr/^Executing `".*uuid-config$ext" --version`$/,
        "Check minor info" );

    # Check patch version.
    ok( $uuid = App::Info::Lib::OSSPUUID->new( on_info => $info ),
        "Got Object 5");
    $info->message; # Throw away constructor message.
    $uuid->patch_version;
    like($info->message, qr/^Executing `".*uuid-config$ext" --version`$/,
        "Check patch info" );

    # Check dir methods.
    $uuid->bin_dir;
    like( $info->message, qr/^Executing `".*uuid-config$ext" --bindir`$/,
          "Check bin info" );
    $uuid->inc_dir;
    like( $info->message, qr/^Executing `".*uuid-config$ext" --includedir`$/,
        "Check inc info" );
    $uuid->lib_dir;
    like( $info->message, qr/^Executing `".*uuid-config$ext" --libdir`$/,
          "Check lib info" );
    $uuid->cflags;

    # Check configure info.
    like( $info->message, qr/^Executing `".*uuid-config$ext" --cflags`$/,
        "Check cflags info" );
    $uuid->ldflags;
    like( $info->message, qr/^Executing `".*uuid-config$ext" --ldflags`$/,
        "Check ldflags info" );
}

__END__
