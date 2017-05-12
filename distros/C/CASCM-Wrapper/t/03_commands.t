#!/usr/bin/perl

#####################
# LOAD CORE MODULES
#####################
use strict;
use warnings;
use Test::More;

# Autoflush
local $| = 1;

my $module = "CASCM::Wrapper";

# Load
use_ok($module) or exit;

# Init
my $cascm = new_ok( $module, [ { dry_run => 1 } ] ) or exit;

# Set Context
ok(
    $cascm->set_context(
        {
            global => {
                b  => 'harvest',
                eh => 'my_creds.dfo',
                v  => 1,
            },
            hco => {
                up => 1,
                vp => '\repo\myapp\src',
            },
        }
    )
);

ok( $cascm->hco('test.pl') eq
      'hco -arg="test.pl" -b "harvest" -eh "my_creds.dfo" -up -v -vp "\repo\myapp\src"'
);

ok( $cascm->hco( { p => 'my_package' }, 'test.pl' ) eq
      'hco -arg="test.pl" -b "harvest" -eh "my_creds.dfo" -p "my_package" -up -v -vp "\repo\myapp\src"'
);

ok( $cascm->hco() eq
      'hco  -b "harvest" -eh "my_creds.dfo" -up -v -vp "\repo\myapp\src"' );

done_testing();
