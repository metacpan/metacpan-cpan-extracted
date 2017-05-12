package 
    I18NTest::SchemaAuto::Result::Foo;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components( qw/ I18NColumns Core / );

__PACKAGE__->table( 'foo' );
__PACKAGE__->add_columns(
    'id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, is_auto_increment => 1 },
    'id_item',
    { data_type => 'INT', default_value => 0, is_nullable => 0 },
);
__PACKAGE__->add_i18n_columns(
    'string',
    { data_type => 'VARCHAR', default_value => "", is_nullable => 1, size => 255 },
    'text',
    { data_type => 'TEXT', default_value => "", is_nullable => 1 },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->belongs_to( 'item', 'I18NTest::SchemaAuto::Result::Item', { 'foreign.id' => 'self.id_item' }, );

1;
