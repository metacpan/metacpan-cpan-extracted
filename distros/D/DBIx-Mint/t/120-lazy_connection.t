#!/usr/bin/perl

use lib 't';
use Test::DB;
use Test::More tests => 5;
use strict;
use warnings;

### Make sure connections are lazy

BEGIN {
    use_ok 'DBIx::Mint';
}

{
    package Bloodbowl::Team; use Moo;
    with 'DBIx::Mint::Table';

    has id           => ( is => 'rw' );
    has name         => ( is => 'rw' );
    has coach        => ( is => 'rw' );
}

# DBIx::Mint object creation
my $is_connected = 0;
my @params = Test::DB->connection_params;
$params[3]->{ Callbacks }{ connected } = sub { $is_connected = 1; return; };

my $mint   = DBIx::Mint->connect( @params );
ok $mint->has_connector,
    'Mint has a DBIx::Connector object';
is $is_connected, 0,
    'The database connection is not made during object construction';
    
my $schema = $mint->schema;

$schema->add_class(
    class    => 'Bloodbowl::Team',
    table    => 'teams',
    pk       => 'id',
    auto_pk  => 1
);

is $is_connected, 0,
    'The database connection is not made while declaring a schema';

# It is at this point that we need the database connection
my $dbh = $mint->dbh;
is $is_connected, 1,
    'The database connection is active when first used';

done_testing();
