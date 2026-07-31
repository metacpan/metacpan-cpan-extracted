#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Author tests not required for installation" );
}

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

# Scoped to lib/: the default is blib, which also holds the bundled Net-SNMP
# perl modules (SNMP.pm, NetSNMP::*) staged there by the alienfile.  Their POD is
# upstream's to fix, not ours.
all_pod_files_ok( all_pod_files('lib') );
