#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Driver;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}


my $tests_per_run = 2;

plan tests => $tests_per_run * @rdbms_names;


my %rdbms = ( mysql => 'MySQL',
              pg    => 'PostgreSQL' );

foreach my $rdbms (@rdbms_names)
{
    my $config = Alzabo::Test::Utils->test_config_for($rdbms);

    my $driver = Alzabo::Driver->new( rdbms => $rdbms{$rdbms} );

    my @schemas;
    eval_ok( sub { @schemas =
                       $driver->schemas( Alzabo::Test::Utils->connect_params_for($rdbms) ) },
             "Schema method for $rdbms{ $config->{rdbms} }" );

    ok( scalar @schemas, 'schemas were found' );
}
