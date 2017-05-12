#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# Base DBD Driver Test

BEGIN { use_ok ("DBI") }

my ($switch, $drh);
ok ($switch = DBI->internal,	"DBI->internal");
is (ref $switch, "DBI::dr",	"DBI::dr ref 1");

eval {
    # This is a special case. install_driver should not normally be used.
    ok ($drh = DBI->install_driver ("Unify"),	"install_driver");
    is (ref $drh, "DBI::dr",	"DBI::dr ref 2");
    };
if ($@) {
    $@ =~ s/\n\n+/\n/g;
    $@ and warn "Failed to load Unify extension and/or shared libraries:\n$@";
    warn "The remaining tests will probably also fail with the same error.\a\n\n";
    # try to provide some useful pointers for some cases
    warn "*** Please read the README and README.help files for help. ***\n";
    warn "\n";
    sleep 5;
    }

ok ($drh->{Version},	"Driver version");

done_testing;
