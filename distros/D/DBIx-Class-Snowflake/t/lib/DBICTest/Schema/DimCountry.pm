package DBICTest::Schema::DimCountry;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('DimCountry');
__PACKAGE__->load_components("Snowflake::Dimension");
__PACKAGE__->add_columns(
    'country_id' => { 'data_type' => 'integer' },
    'country'    => { 'data_type' => 'text' }
);
__PACKAGE__->set_primary_key('country_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Dimension');

sub create_sql
{
    return <<EOSQL
    country_id INTEGER,
    country    INTEGER
EOSQL
       ;
}

