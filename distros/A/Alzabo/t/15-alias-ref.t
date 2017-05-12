#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Test::Utils;

use Test::More;


use Alzabo::Runtime;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

plan tests => 1;


Alzabo::Test::Utils->remove_all_schemas;


# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

Alzabo::Test::Utils->make_schema($rdbms);

my $config = Alzabo::Test::Utils->test_config_for($rdbms);

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

my $destroy = 0;
sub Alzabo::Runtime::Table::DESTROY { $destroy++ }

{
    my $employee_t = $s->table('employee');

    {
        my $alias1 = $employee_t->alias;
        $alias1->primary_key;
    }

    is( $destroy, 1, 'alias should go out of scope' );
}
