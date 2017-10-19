package TestSchema::Result::Data;
use base 'DBIx::Class';

__PACKAGE__->load_components(
  'HashAccessor',
  'InflateColumn::Serializer',
  'Core'
);
 
__PACKAGE__->table('data');

__PACKAGE__->add_columns(
  'data' => {
    'data_type' => 'VARCHAR',
    'size' => 255,
    'serializer_class' => 'JSON',
  }
);

__PACKAGE__->add_hash_accessor( da => 'data' );

1;