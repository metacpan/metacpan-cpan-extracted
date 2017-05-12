package DBICTest::Schema::FactB;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Snowflake::Fact Core));
__PACKAGE__->table('FactB');
__PACKAGE__->add_columns(
    'fact_id' => { 'data_type' => 'integer', 'is_auto_increment' => 1 },
    'date_id' => { 'data_type' => 'integer' },
    'city_id' => { 'data_type' => 'integer' },
);
__PACKAGE__->set_primary_key('fact_id');
__PACKAGE__->belongs_to( date_id => 'DBICTest::Schema::DimDate' => 'date_id');
__PACKAGE__->belongs_to( city_id => 'DBICTest::Schema::DimCity' => 'city_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Fact');

sub create_sql
{
    return <<EOSQL
    fact_id     INTEGER,
    date_id     INTEGER,
    city_id     INTEGER
EOSQL
;}

1;

