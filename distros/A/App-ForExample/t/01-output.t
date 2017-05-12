#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use t::Test;

run_for_example_eg qw# catalyst/fastcgi apache2 standalone --bare --output #, scratch->base;
ok( scratch->exists( 'catalyst-fastcgi.apache2' ) );
ok( -s _ );
ok( ! scratch->exists( 'catalyst-fastcgi.start-stop' ) );
ok( ! scratch->exists( 'catalyst-fastcgi.monit' ) );

run_for_example_eg qw# catalyst/fastcgi apache2 standalone --output #, scratch->base;
ok( scratch->exists( 'catalyst-fastcgi.apache2' ) );
ok( -s _ );
ok( scratch->exists( 'catalyst-fastcgi.start-stop' ) );
ok( -s _ );
ok( scratch->exists( 'catalyst-fastcgi.monit' ) );
ok( -s _ );

run_for_example_eg qw# catalyst/fastcgi apache2 standalone --output #, scratch->file( 'test' );
ok( scratch->exists( 'test.apache2' ) );
ok( -s _ );
ok( scratch->exists( 'test.start-stop' ) );
ok( -s _ );
ok( scratch->exists( 'test.monit' ) );
ok( -s _ );
