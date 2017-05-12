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


my $tests_per_run = 2;

plan tests => $tests_per_run * @rdbms_names;


Alzabo::Test::Utils->remove_all_schemas;


foreach my $rdbms (@rdbms_names)
{
    Test::More::diag( "Running $rdbms reverse engineering tests" );

    my $s1 = Alzabo::Test::Utils->make_schema($rdbms);

    my $config = Alzabo::Test::Utils->test_config_for($rdbms);

    delete $config->{schema_name};

    $config->{name}  = $s1->name;
    $config->{rdbms} = $s1->driver->driver_id;

    my $s2;
    eval_ok( sub { $s2 = Alzabo::Create::Schema->reverse_engineer(%$config) },
	     "Reverse engineer the @{[$s1->name]} schema with @{[$s1->driver->driver_id]}" );

    if ( ref $s2 )
    {
        my @diff = $s1->rules->schema_sql_diff( old => $s1,
                                                new => $s2 );

        my $sql = join "\n", @diff;

        is ( $sql, '',
             "Reverse engineered schema's SQL should be the same as the original's" );

        $s1->delete;
    }
    else
    {
        ok( 0, "Reverse engineering failed, cannot do diff" );
    }
}
