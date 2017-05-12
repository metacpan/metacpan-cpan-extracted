package DBICTest::Schema::FactA;
our $VERSION = '0.10';



use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw(Snowflake::Fact Core));
__PACKAGE__->table('FactA');
__PACKAGE__->add_columns(
    'fact_id' => { 'data_type' => 'integer', 'is_auto_increment' => 1 },
    'date_id' => { 'data_type' => 'integer' },
    'time_id' => { 'data_type' => 'integer' },
    'fact'    => { 'data_type' => 'text' }
);
__PACKAGE__->set_primary_key('fact_id');
__PACKAGE__->belongs_to( date_id => 'DBICTest::Schema::DimDate' => 'date_id');
__PACKAGE__->belongs_to( time_id => 'DBICTest::Schema::DimTime' => 'time_id');
__PACKAGE__->resultset_class('DBIx::Class::Snowflake::ResultSet::Fact');

sub create_sql
{
    return <<EOSQL
    date_id     INTEGER,
    time_id     INTEGER,
    fact        STRING
EOSQL
;}

1;
