#!/usr/bin/perl -w
use strict;

use Cache::Historical;
use File::Temp qw(tempfile);
use DateTime::Format::Strptime;
use Test::More tests => 4;

my($fh, $tmpfile) = tempfile( UNLINK => 1 );
unlink $tmpfile; # unlink so db gets initialized

my $c = Cache::Historical->new(
        cache_dir   => "/tmp",
        sqlite_file => $tmpfile,
);

my $fmt = DateTime::Format::Strptime->new(
              pattern => "%Y-%m-%d");

$c->set( $fmt->parse_datetime("2008-01-02"), "msft", 35.22 );

my $upd = $c->last_update();
ok(time() - $upd->epoch() >= 0, "last update time (global)");

$upd = $c->last_update( "msft" );
ok(time() - $upd->epoch() >= 0, "last update time (per key)");

my $dur = $c->since_last_update();
ok($dur->seconds() >= 0, "since last update (global)");

$dur = $c->since_last_update( 'msft' );
ok($dur->seconds() >= 0, "since last update (per key)");
