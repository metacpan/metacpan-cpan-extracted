#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use DBIx::ResultSet::Connector;

my @args = ('dbi:SQLite:dbname=t/test.db', '', '');

isnt(
    exception { DBIx::ResultSet::Connector->new() },
    undef,
    'new without args dies',
);

my $dbix_connector = DBIx::Connector->new( @args );
is(
    exception { DBIx::ResultSet::Connector->new(dbix_connector=>$dbix_connector) },
    undef,
    'new() with args works',
);

is(
    exception { DBIx::ResultSet->connect(@args) },
    undef,
    'DBIx::ResultSet->connect() with args works',
);

is(
    exception { DBIx::ResultSet::Connector->connect(@args) },
    undef,
    'DBIx::ResultSet::Connector->connect() with args works',
);

done_testing;
