package MySchema::Result::HasPrimaryKey;
use base 'DBIx::Class::Core';
__PACKAGE__->table('has_primary_key');
__PACKAGE__->add_columns(qw(baz faz));
__PACKAGE__->set_primary_key('baz');
1;
