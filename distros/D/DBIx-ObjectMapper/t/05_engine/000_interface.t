use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Engine;

ok my $engine = DBIx::ObjectMapper::Engine->new;
for(
    'transaction',
    'namesep',
    'driver',
    'quote',
    'iterator',
    'datetime_parser',
    'get_primary_key',
    'get_column_info',
    'get_unique_key',
    'get_tables',
    'select',
    'select_single',
    'update',
    'insert',
    'delete',
    'log',
) {
    ok $engine->can($_);
    $engine->$_;
}

done_testing;
