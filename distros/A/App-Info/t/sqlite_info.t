#!/usr/bin/perl -w

use strict;
use Test::More tests => 17;
use constant SKIP => 13;

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
BEGIN { use_ok('App::Info::RDBMS::SQLite') }

# Test info events.
ok( my $info = EventTest->new, "Create info EventTest" );
ok( my $sqlite = App::Info::RDBMS::SQLite->new( on_info => $info ),
    "Got Object");
is( $info->message, "Looking for SQLite",
    "Check constructor info" );

SKIP: {
    # Skip tests?
    skip "SQLite not installed", SKIP unless $sqlite->installed;

    # Check version.
    ok( $sqlite = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 2");
    $info->message while defined $info->message; # Throw away constructor messages.
    $sqlite->version;
    like($info->message, qr/^(Executing `".*sqlite3?(.exe)?" -version`|Grabbing version from DBD::SQLite)$/,
        "Check version info" );

    $sqlite->version;
    ok( ! defined $info->message, "No info" );
    $sqlite->major_version;
    ok( ! defined $info->message, "Still No info" );

    # Check major version.
    ok( $sqlite = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 3");
    $info->message while defined $info->message; # Throw away constructor messages.
    $sqlite->major_version;
    like($info->message, qr/^(Executing `".*sqlite3?(.exe)?" -version`|Grabbing version from DBD::SQLite)$/,
        "Check major info" );

    # Check minor version.
    ok( $sqlite = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 4");
    $info->message while defined $info->message; # Throw away constructor messages.
    $sqlite->minor_version;
    like($info->message, qr/^(Executing `".*sqlite3?(.exe)?" -version`|Grabbing version from DBD::SQLite)$/,
        "Check minor info" );

    # Check patch version.
    ok( $sqlite = App::Info::RDBMS::SQLite->new( on_info => $info ),
        "Got Object 5");
    $info->message while defined $info->message; # Throw away constructor messages.
    $sqlite->patch_version;
    like($info->message, qr/^(Executing `".*sqlite3?(.exe)?" -version`|Grabbing version from DBD::SQLite)$/,
        "Check patch info" );

    # Check dir methods.
    skip "No directories when using DBD::SQLite", 3 unless $sqlite->executable;
    $sqlite->inc_dir;
    like( $info->message, qr/^Searching for include directory$/,
        "Check inc info" );
    $sqlite->lib_dir;
    like( $info->message, qr/^Searching for library directory$/,
          "Check lib info" );
    $sqlite->so_lib_dir;
    like( $info->message, qr/^Searching for shared object library directory$/,
        "Check so lib info" );
}

__END__
