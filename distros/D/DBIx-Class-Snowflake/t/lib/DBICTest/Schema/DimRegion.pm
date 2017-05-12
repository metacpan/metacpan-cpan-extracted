package DBICTest::Schema::DimRegion;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('DimRegion');
__PACKAGE__->load_components("Snowflake::Dimension");
__PACKAGE__->add_columns(
    'region_id'  => { 'data_type' => 'integer', 'is_auto_increment' => 1 },
    'country_id' => { 'data_type' => 'integer' },
    'region'     => { 'data_type' => 'text' }
);
__PACKAGE__->set_primary_key('region_id');
__PACKAGE__->belongs_to( country_id => 'DBICTest::Schema::DimCountry' => 'country_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Dimension');

sub create_sql
{
    return <<EOSQL
    region_id  INTEGER,
    country_id INTEGER,
    region     INTEGER
EOSQL
       ;
}

