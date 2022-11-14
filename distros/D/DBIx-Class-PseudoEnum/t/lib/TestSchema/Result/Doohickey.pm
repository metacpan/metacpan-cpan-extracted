package TestSchema::Result::Doohickey;
use Modern::Perl;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('doohickey');
__PACKAGE__->add_columns(qw/id field1 field2/);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->load_components('PseudoEnum');
__PACKAGE__->enumerations_use_column_names();
__PACKAGE__->enumerate( 'field1', [qw/One Two Three Four Blue/] );
__PACKAGE__->enumerate( 'field2', [qw/BLUE RED GREEN/] );

1;
