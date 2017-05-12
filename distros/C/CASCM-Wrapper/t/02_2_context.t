#!/usr/bin/perl

#####################
# LOAD CORE MODULES
#####################
use strict;
use warnings;
use Test::More;
use File::Spec;

# Autoflush
local $| = 1;

# What are we testing?
my $module = "CASCM::Wrapper";

# Check for Config::Tiny
eval {
    require Config::Tiny;
    Config::Tiny->import();
  return 1;
} or plan skip_all => "Config::Tiny not found";

# Load
use_ok($module) or exit;

# Context file
my $ctx_file = File::Spec->catfile( 't', 'data', 'scm_context.ini' );

# Init
my $cascm = new_ok( $module, [ { context_file => $ctx_file } ] ) or exit;

my $expected = {
    global => {
        b  => 'harvest',
        eh => 'my_creds.dfo',
    },
    hco => {
        vp => '\repo\myapp\src',
        up => 1,
    },
    hcp => {
        st => 'dev',
    },
};

is_deeply( $cascm->get_context, $expected );

done_testing();
