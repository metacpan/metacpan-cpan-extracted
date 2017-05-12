#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;

use Alzabo::Create::Schema;

my $config = Alzabo::Test::Utils->test_config_for('pg');

unless ( keys %$config )
{
    plan skip_all => 'no Postgres test config provided';
    exit;
}

{
    package FakeSchema;

    sub new { return bless { name => $_[1] }, $_[0] }

    sub db_schema_name { $_[0]->{name} }
}

require DBD::Pg;
require Alzabo::Driver::PostgreSQL;


plan tests => 6;

Alzabo::Test::Utils->remove_schema('pg');


my $schema_name = delete $config->{schema_name};
delete $config->{rdbms};

{
    # This seems to help avoid those damn 'source database "template1"
    # is being accessed by other users' errors.  Freaking Postgres!
    sleep 1;

    # We create a couple of tables *without* using Alzabo, then see
    # whether it can reverse-engineer them and preserve foreign key
    # relationships.
    my $driver = Alzabo::Driver->new( rdbms  => 'PostgreSQL',
                                      schema => FakeSchema->new('template1'),
                                    );
    $driver->connect( %$config );
    my $dbh = $driver->handle;

    $dbh->do("CREATE DATABASE $schema_name");
    $dbh->disconnect;

    ok( 1, 'drop and create database' );

    $driver = Alzabo::Driver->new( rdbms  => 'PostgreSQL',
                                   schema => FakeSchema->new($schema_name),
                                 );
    $driver->connect( %$config );
    $dbh = $driver->handle;

    $dbh->do( q{CREATE TABLE foobar
                (
                 foo_ts timestamp default now() primary key
                )
               });

    $dbh->disconnect;
    ok( 1, 'create tables to be reverse engineered' );
}

my $schema = Alzabo::Create::Schema->reverse_engineer
  ( name  => $schema_name,
    rdbms => 'PostgreSQL',
    %$config,
  );

ok( $schema, 'schema was created via reverse engineering' );

{
    my $t = $schema->table('foobar');
    ok( $t, 'found foobar table' );

    my $c = $t->column('foo_ts');
    ok( $c->default_is_raw(), 'default is raw for foobar.foo_ts' );
    is( $c->default(), 'now()', 'default is now() for foobar.foo_ts' );
}
