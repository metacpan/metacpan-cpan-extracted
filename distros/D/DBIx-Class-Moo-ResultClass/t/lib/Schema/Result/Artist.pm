package Schema::Result::Artist;

use DBIx::Class::Moo::ResultClass;

extends 'Schema::Result';
with 'Component';

has spork => (is => 'ro', default => sub { 'THERE IS NO SPROK' });

__PACKAGE__->table('artist');

__PACKAGE__->add_columns(
  artist_id => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size => '96',
  });

__PACKAGE__->set_primary_key('artist_id');

1;
