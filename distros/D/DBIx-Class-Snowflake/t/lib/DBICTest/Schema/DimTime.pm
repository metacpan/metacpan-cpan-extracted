package DBICTest::Schema::DimTime;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('DimTime');
__PACKAGE__->load_components("Snowflake::Dimension");
__PACKAGE__->add_columns(
    'time_id' => { 'data_type' => 'integer', 'is_auto_increment' => 1 },
    'hour'    => { 'data_type' => 'integer' },
    'minute'  => { 'data_type' => 'integer' }
);
__PACKAGE__->set_primary_key('time_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Dimension');

sub create_sql
{
    return <<EOSQL
    time_id INTEGER,
    hour    INTEGER,
    minute  INTEGER
EOSQL
;}

