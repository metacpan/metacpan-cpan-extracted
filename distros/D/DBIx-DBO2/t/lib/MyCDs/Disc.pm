package MyCDs::Disc;

use strict;
use DBIx::DBO2::Record '-isasubclass';

use DBIx::DBO2::Fields (
  { name => 'id', field_type => 'sequential', },
  { name => 'name', field_type => 'string', length => 64, required => 1 },
  { name => 'year', field_type => 'number' },
  { name=>'artist', field_type=>'foreign_key', 
      accessors => ['name'], related_class=>'MyCDs::Artist' },
  { name => 'genre', field_type => 'number' },
  { name => 'added_to_db', field_type => 'timestamp', interface => 'created' },
  { name => 'updated_db', field_type => 'timestamp', interface => 'modified' },
);

1;
