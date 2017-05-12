#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Create;
use Alzabo::Config;
use Alzabo::Runtime::UniqueRowCache;
use Alzabo::Runtime;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

plan tests => 12;


Alzabo::Test::Utils->remove_all_schemas;


# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

Alzabo::Test::Utils->make_schema($rdbms);

my $config = Alzabo::Test::Utils->test_config_for($rdbms);

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

$s->connect( Alzabo::Test::Utils->connect_params_for($rdbms)  );

{
    my $dep1 = $s->table('department')->insert( values => { name => 'dep1' } );
    my $pk = $dep1->select('department_id');

    my $dep1_copy =
        $s->table('department')->row_by_pk( pk => $pk );

    is( "$dep1", "$dep1_copy",
        "There should only be one reference for a given row" );

    $dep1->delete;
    ok( $dep1->is_deleted, 'copy is deleted' );
    ok( $dep1_copy->is_deleted, 'copy is deleted' );

    my $new_dep1 = $s->table('department')
        ->insert( values => { department_id => $pk, name => 'a new dep1' } );

    ok( ! $new_dep1->is_deleted, 'new dep1 is not deleted' );
}

{
    my $dep2 = $s->table('department')->insert( values => { name => 'dep2' } );
    my $dep2_copy =
        $s->table('department')->row_by_pk( pk => $dep2->select('department_id') );

    $dep2->update( name => 'foo' );
    is( $dep2_copy->select('name'), 'foo', 'name in copy is foo' );

    $s->driver->do( sql  => 'UPDATE department SET name = ? WHERE department_id = ?',
                    bind => [ 'bar', $dep2->select('department_id') ],
                  );

    $dep2->refresh;

    is( $dep2->select('name'), 'bar', 'refresh works for cached rows' );
    is( $dep2_copy->select('name'), 'bar', 'refresh works for cached rows' );

    my $old_id = $dep2->id_as_string;
    {
        my $updated = $dep2->update( department_id => 1000 );
        ok( $updated, 'update() did change values' );
    }

    {
        my $updated = $dep2->update( department_id => 1000 );
        ok( ! $updated, 'update() did not change values' );
    }

    ok( Alzabo::Runtime::UniqueRowCache->row_in_cache
            ( $dep2->table->name, $dep2->id_as_string ),
        'row is still in cache after updating primary key' );

    ok( ! Alzabo::Runtime::UniqueRowCache->row_in_cache( $dep2->table->name, $old_id ),
        'old id is not in cache' );

    my $dep2_copy_2 =
        $s->table('department')->row_by_pk( pk => $dep2->select('department_id'),
                                            no_cache => 1 );

    is( $dep2_copy_2->{state}, 'Alzabo::Runtime::RowState::Live',
        'row state is live, not cached' );
}
