package TestApp::Schema::Result::MultiPk;
use parent 'DBIx::Class';
use strict;
use warnings;

__PACKAGE__->load_components('Core');
__PACKAGE__->table('MultiPk');
__PACKAGE__->add_columns(qw/ id bill ted /);
__PACKAGE__->set_primary_key(qw{bill ted});

1;
