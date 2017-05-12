#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Create;
use Alzabo::Config;
use Alzabo::Runtime;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

plan tests => 25;


Alzabo::Test::Utils->remove_all_schemas;


# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

if ( $rdbms eq 'mysql' )
{
    # prevent subroutine redefinition warnings
    local $^W = 0;
    eval 'use Alzabo::SQLMaker::MySQL qw(:all)';
}
elsif ( $rdbms eq 'pg' )
{
    local $^W = 0;
    eval 'use Alzabo::SQLMaker::PostgreSQL qw(:all)';
}

Alzabo::Test::Utils->make_schema($rdbms);

my $config = Alzabo::Test::Utils->test_config_for($rdbms);

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

$s->connect( Alzabo::Test::Utils->connect_params_for($rdbms)  );

my $department = $s->table('department')->insert( values => { name => 'D 1' } );
my $dep_id = $department->select('department_id');

{
    my $handle =
        $s->table('employee')->insert_handle
            ( columns => [ $s->table('employee')->columns( 'name', 'dep_id' ) ] );

    foreach my $name ( qw( Faye Jet Maggie ) )
    {
        my $row =
            $handle->insert( values =>
                             { name => $name,
                               dep_id => $dep_id,
                             }
                           );

        ok( $row->select('employee_id'), 'row has an employee id' );
        is( $row->select('name'), $name, "name is $name" );
        is( $row->select('dep_id'), $dep_id, "dep_id is $dep_id" );
        is( $row->select('smell'), 'grotesque', 'smell is default value' );
    }

    eval { $handle->insert( values =>
                            { name => 'Dave',
                              dep_id => $dep_id,
                              smell  => 'geeky',
                            }
                          ) };
    like( $@, qr/cannot provide a value.+\(smell\)/i, 'try to insert with a bad column' );
}

{
    my $handle =
        $s->table('employee')->insert_handle
            ( columns => [ $s->table('employee')->columns( 'name', 'dep_id' ) ],
              values  => { smell => LOWER('GOOD') },
            );

    my $row =
        $handle->insert( values =>
                         { name => 'Cecilia',
                           dep_id => $dep_id,
                         }
                       );

    ok( $row->select('employee_id'), 'row has an employee id' );
    is( $row->select('name'), 'Cecilia', "name is Cecilia" );
    is( $row->select('dep_id'), $dep_id, "dep_id is $dep_id" );
    is( $row->select('smell'), 'good', 'smell is "good"' );
}

{
    my $handle =
        $s->table('employee')->insert_handle
            ( columns => [ $s->table('employee')->columns( 'name', 'dep_id' ) ],
              values  => { smell => 'good' },
            );

    my $row =
        $handle->insert( values =>
                         { name => 'Cecilia',
                           dep_id => $dep_id,
                         }
                       );

    ok( $row->select('employee_id'), 'row has an employee id' );
    is( $row->select('name'), 'Cecilia', "name is Cecilia" );
    is( $row->select('dep_id'), $dep_id, "dep_id is $dep_id" );
    is( $row->select('smell'), 'good', 'smell is "good"' );

    # override a static value
    $row =
        $handle->insert( values =>
                         { name => 'Cecilia',
                           dep_id => $dep_id,
                           smell  => 'great',
                         }
                       );

    ok( $row->select('employee_id'), 'row has an employee id' );
    is( $row->select('name'), 'Cecilia', "name is Cecilia" );
    is( $row->select('dep_id'), $dep_id, "dep_id is $dep_id" );
    is( $row->select('smell'), 'great', 'smell is "great"' );
}
