package 
    I18NTest::SchemaAuto::Result::Item;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components( qw/ I18NColumns Core / );

__PACKAGE__->table( 'totem' );
__PACKAGE__->add_columns(
    'id',
    { data_type => 'INT', default_value => 0, is_nullable => 0, is_auto_increment => 1 },
    'name',
    { data_type => 'VARCHAR', default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->add_i18n_columns(
    'string',
    { data_type => 'VARCHAR', default_value => "", is_nullable => 1, size => 255 },
    'text',
    { data_type => 'TEXT', default_value => "", is_nullable => 1 },
);

__PACKAGE__->set_primary_key( 'id' );

__PACKAGE__->has_many( 'foos', 'I18NTest::SchemaAuto::Result::Foo', { 'foreign.id_item' => 'self.id' } );

__PACKAGE__->has_many( 'item_bars', 'I18NTest::SchemaAuto::Result::ItemBar', { 'foreign.id_item' => 'self.id' } );
__PACKAGE__->many_to_many( 'bars', 'item_bars', 'bar' );

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;

    $sqlt_table->add_index( name => 'idx_name', fields => [qw/ name /] );                                             
}

1;
