#!/usr/bin/perl -w

use strict;

use File::Spec;

use lib '.', File::Spec->catdir( File::Spec->curdir, 't', 'lib' );

use Alzabo::Runtime;
use Alzabo::Test::Utils;

use Test::More;

Alzabo::Test::Utils->remove_all_schemas;

my $schema = Alzabo::Test::Utils->any_connected_runtime_schema;

if ($schema)
{
    plan tests => 2;
}
else
{
    plan skip_all => 'no test config provided';
    exit;
}

my $emp_t = $schema->table('employee');

# value of pk is irrelevant, as long as it doesn't exist
my $row = eval { $emp_t->row_by_pk( pk => 1258125 ) };

is( $row, undef, 'no row matched the given pk' );
is( $@, '', 'no exception was thrown with invalid pk' );
