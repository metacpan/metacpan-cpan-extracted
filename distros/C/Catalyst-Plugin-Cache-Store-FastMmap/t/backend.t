#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

BEGIN {
    plan skip_all => "This test requires File::Temp" unless eval { require File::Temp };
    plan tests => 4;
}

use Test::Exception;

use ok "Catalyst::Plugin::Cache::Backend::FastMmap";

my ( $fh, $name ) = File::Temp::tempfile();

my $cache = Catalyst::Plugin::Cache::Backend::FastMmap->new(
    share_file => $name,
);

lives_ok {
    $cache->set( key => "non_ref" );
} "you can set non references too";

is( $cache->get("key"), "non_ref", "they are returned properly" );

$cache->set( complex => my $d = { foo => [qw/bar gorch/], baz => "moose" } );

is_deeply( $cache->get("complex"), $d, "storing of refs is unaffected" );

END {
    close $fh;
    unlink $name if -e $name;
}
