#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

my $tests_per_run = 4;
my $test_count = $tests_per_run * @rdbms_names;

plan tests => $test_count;

Alzabo::Test::Utils->remove_all_schemas;

foreach my $rdbms (@rdbms_names)
{
    my $s = Alzabo::Test::Utils->make_schema( $rdbms, 1 );

    my $name = $s->name . '_2';

    my $config = Alzabo::Test::Utils->test_config_for($rdbms);
    $config->{schema_name} = $name;
    delete $config->{rdbms};

    eval_ok( sub { $s->create(%$config) },
             "call create() for $rdbms with name parameter" );

    my %schemas =
        ( map { $_ => 1  }
          $s->driver->schemas( Alzabo::Test::Utils->connect_params_for($rdbms) )
        );
    ok( $schemas{$name},
        "schema with new name ($name) was created for $rdbms" );

    my $t = $s->make_table( name => 'just_a_table' );
    $t->make_column( name => 'jat_pk',
                     type => 'integer',
                     primary_key => 1,
                   );

    my $sql = join "\n", $s->sync_backend_sql(%$config);
    like( $sql, qr/CREATE TABLE[\s"'`]+just_a_table/i,
          "create new table in sync SQL for $rdbms" );
    unlike( $sql, qr/CREATE TABLE.+CREATE_TABLE/is,
            "do not create other new tables in sync SQL for $rdbms" );
}


Alzabo::Test::Utils->remove_all_schemas;
