package DBIx::Cookbook::DBIC::Sakila::Result::FilmInStock;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table_class('DBIx::Class::ResultSource::View');

__PACKAGE__->table('FilmInStock');
__PACKAGE__->add_columns(
  "inventory_id",
  {
    data_type => "SMALLINT",
    default_value => undef,
    extra => { unsigned => 1 },
    is_auto_increment => 1,
    is_nullable => 0,
    size => 5,
  },
			);
__PACKAGE__->result_source_instance->is_virtual(1);

__PACKAGE__->result_source_instance->view_definition(<<'EOSQL');

CALL film_in_stock(?,?,@count);

EOSQL

1;
