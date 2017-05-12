package DBICTest::Schema::DimCity;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('DimCity');    # _not_ SimCity, which is a great game
__PACKAGE__->load_components("Snowflake::Dimension");
__PACKAGE__->add_columns(
    'city_id'   => { 'data_type' => 'integer', 'is_auto_increment' => 1 },
    'region_id' => { 'data_type' => 'integer' },
    'city'      => { 'data_type' => 'text' }
);
__PACKAGE__->set_primary_key('city_id');
__PACKAGE__->belongs_to( region_id => 'DBICTest::Schema::DimRegion' => 'region_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Dimension');

sub create_sql
{
    return <<EOSQL
    city_id   INTEGER,
    region_id INTEGER,
    city      INTEGER
EOSQL
       ;
}

