#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "This test requires File::Temp" unless eval { require File::Temp };
    plan tests => 3;
}

use ok "Catalyst::Plugin::Cache::Store::FastMmap";

{
    package MockApp;
    use base qw/Catalyst::Plugin::Cache::Store::FastMmap/;
    
    our %backends;
    sub register_cache_backend {
        my ( $app, $name, $backend ) = @_;
        $backends{$name} = $backend;
    }
}

can_ok( "MockApp", "setup_fastmmap_cache_backend" );

my ( $fh, $name ) = File::Temp::tempfile;

MockApp->setup_fastmmap_cache_backend( foo => { share_file => $name } );

isa_ok( $MockApp::backends{foo}, "Cache::FastMmap" );

END {
    close $fh;
    unlink $name if -e $name;
}
