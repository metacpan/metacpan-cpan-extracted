#!/usr/bin/perl -w

#
# There was a bug which occurred when SQL debugging was on, which
# caused bound parameters that were explicitly set to undef to be
# converted to the string 'NULL'.
#

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

BEGIN { $ENV{ALZABO_DEBUG} = 'SQL' }

use Alzabo::Test::Utils;

use Test::More;


my @rdbms_names = Alzabo::Test::Utils->rdbms_names;

unless (@rdbms_names)
{
    plan skip_all => 'no test config provided';
    exit;
}

plan tests => 2;

Alzabo::Test::Utils->remove_all_schemas;

# doesn't matter which RDBMS is used
my $rdbms = $rdbms_names[0];

Alzabo::Test::Utils->make_schema($rdbms);

my $config = Alzabo::Test::Utils->test_config_for($rdbms);

my $s = Alzabo::Runtime::Schema->load_from_file( name => $config->{schema_name} );

$s->connect( Alzabo::Test::Utils->connect_params_for($rdbms)  );

Test::More::diag( 'This test will produce a lot of debugging output.  Please ignore it' );

my $dep = $s->table('department')->insert( values => { name => 'department' } );

my $emp;
eval_ok ( sub { $emp = $s->table('employee')->insert
                    ( values => { name   => 'Bubba',
                                  cash   => undef,
                                  dep_id => $dep->select('department_id'),
                                } ) },
          'insert with explicit cash => undef while debugging is on' );

is( $emp->select('cash'), undef, 'cash is undef' );
