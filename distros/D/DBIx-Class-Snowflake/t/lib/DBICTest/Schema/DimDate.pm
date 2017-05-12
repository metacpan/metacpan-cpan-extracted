package DBICTest::Schema::DimDate;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('DimDate');
__PACKAGE__->load_components("Snowflake::Dimension");
__PACKAGE__->add_columns(
    'date_id' => {
        'data_type'        => 'integer',
        'is_auto_increment' => 1
    },
    'day_of_week'  => { 'data_type' => 'integer', },
    'day_of_month' => { 'data_type' => 'integer', },
    'day_of_year'  => { 'data_type' => 'integer', }
);
__PACKAGE__->set_primary_key('date_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Dimension');

sub create_sql
{
    return <<EOSQL
    date_id         INTEGER,
    day_of_week     INTEGER,
    day_of_month    INTEGER,
    day_of_year     INTEGER
EOSQL
;}
