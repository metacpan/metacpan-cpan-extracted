package 
    I18NTest::SchemaAuto::Result::ItemBar;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components( qw/ Core / );

__PACKAGE__->table( 'item_bar' );
__PACKAGE__->add_columns(
    'id_item',
    { data_type => 'INT', default_value => 0, is_nullable => 0 },
    'id_bar',
    { data_type => 'INT', default_value => 0, is_nullable => 0 },
);

__PACKAGE__->set_primary_key( 'id_item', 'id_bar' );

__PACKAGE__->belongs_to( 'item', 'I18NTest::SchemaAuto::Result::Item', { 'foreign.id' => 'self.id_item' }, );
__PACKAGE__->belongs_to( 'bar', 'I18NTest::SchemaAuto::Result::Bar', { 'foreign.id' => 'self.id_bar' }, );

1;
