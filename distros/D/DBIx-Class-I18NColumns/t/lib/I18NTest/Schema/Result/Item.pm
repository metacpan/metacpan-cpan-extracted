package 
    I18NTest::Schema::Result::Item;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components( qw/ I18NColumns Core / );

__PACKAGE__->table( 'item' );
__PACKAGE__->add_columns(
    'id',
    { data_type => 'INT', default_value => 0, is_nullable => 0 },
    'name',
    { data_type => 'VARCHAR', default_value => "", is_nullable => 0, size => 255 },
);
__PACKAGE__->add_i18n_columns(
    'string',
    { data_type => 'VARCHAR', default_value => "", is_nullable => 0, size => 255 },
    'text',
    { data_type => 'TEXT', default_value => "", is_nullable => 0 },
);

__PACKAGE__->set_primary_key( 'id' );

sub auto_resultset_class { 0 }
sub auto_i18n_rs         { 0 }

1;
