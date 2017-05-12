{
package
  Schema::Item;
  
use base 'DBIx::Class';

__PACKAGE__->load_components(qw(PhoneticSearch Core));

__PACKAGE__->table('item');

__PACKAGE__->add_columns(
  id => { data_type => 'integer', auto_increment => 1, },
  name1 => { data_type => 'character varying', phonetic_search => 1 },
  name2 => { data_type => 'character varying', is_nullable => 1, phonetic_search => { algorithm => 'Koeln' } }

);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->resultset_class('DBIx::Class::ResultSet::PhoneticSearch');

}


{ 
package 
  Schema;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes('Item');

sub connect {
  my $class = shift;
  my $schema = $class->next::method('dbi:SQLite::memory:');
  $schema->deploy;
  return $schema;
}

}

1;

