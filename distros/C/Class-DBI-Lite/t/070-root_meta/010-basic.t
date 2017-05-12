#!/usr/bin/perl -w

use strict;
use warnings 'all';
use Test::More 'no_plan';
use lib qw( lib t/lib );
use Data::Dumper;

use_ok( 'My::State' );

ok( my $meta = My::State->root_meta );

is_deeply(
  $meta->dsn  => [ 'DBI:SQLite:dbname=t/testdb', '', '' ]
);

is( $meta->schema => 'DBI:SQLite:dbname=t/testdb' );

