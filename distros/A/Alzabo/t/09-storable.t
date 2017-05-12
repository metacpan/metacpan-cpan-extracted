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

plan tests => 9;


Alzabo::Test::Utils->remove_all_schemas;


# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

Alzabo::Test::Utils->make_schema($rdbms);

my $config = Alzabo::Test::Utils->test_config_for($rdbms);

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

$s->connect( Alzabo::Test::Utils->connect_params_for($rdbms)  );

{
    my $emp_t = $s->table('employee');
    $s->table('department')->insert( values => { department_id => 1,
                                                 name => 'borging' } );

    $emp_t->insert( values => { employee_id => 98765,
                                name => 'bob98765',
                                smell => 'bb',
                                dep_id => 1 } );

    my $ser;
    eval_ok( sub { my $row = $emp_t->row_by_pk( pk => 98765 );
                   $ser = Storable::freeze($row) },
             "Freeze employee" );

    my $eid;
    eval_ok( sub { my $row = Storable::thaw($ser);
                   $eid = $row->select('employee_id') },
             "Thaw employee" );

    is( $eid, 98765,
        "Employee survived freeze & thaw" );

    eval_ok( sub { my $row = $emp_t->row_by_pk( pk => 98765 );
                   $ser = Storable::nfreeze($row) },
             "NFreeze employee" );

    my $smell;
    eval_ok( sub { my $row = Storable::thaw($ser);
                   $smell = $row->select('smell') },
             "Thaw employee" );

    is( $smell, 'bb',
        "Employee survived nfreeze & thaw" );

    eval_ok( sub { my $p_row = $emp_t->potential_row( values => { name => 'Alice' } );
                   $ser = Storable::freeze($p_row) },
             "Freeze potential employee" );

    my $name;
    eval_ok( sub { my $p_row = Storable::thaw($ser);
                   $name = $p_row->select('name') },
             "Thaw potential employee" );

    is( $name, 'Alice',
        "Potential employee survived freeze & thaw" );
}
