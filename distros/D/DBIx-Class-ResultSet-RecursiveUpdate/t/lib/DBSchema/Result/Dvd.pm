package DBSchema::Result::Dvd;

# Created by DBIx::Class::Schema::Loader v0.03000 @ 2006-10-02 08:24:09

use strict;
use warnings;

use base 'DBIx::Class';
use overload '""' => sub {$_[0]->name}, fallback => 1;

__PACKAGE__->load_components(qw/IntrospectableM2M Core/);
__PACKAGE__->table('dvd');
__PACKAGE__->add_columns(
  'dvd_id' => {
    data_type => 'integer',
    is_auto_increment => 1
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  'imdb_id' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
  'owner' => { data_type => 'integer' },
  'current_borrower' => { 
    data_type => 'integer', 
    is_nullable => 1,
  },

  'creation_date' => { 
    data_type => 'datetime',
    is_nullable => 1,
  },
  'alter_date' => { 
    data_type => 'datetime',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('dvd_id');
__PACKAGE__->belongs_to('owner', 'DBSchema::Result::User', 'owner');
__PACKAGE__->belongs_to('current_borrower', 'DBSchema::Result::User', 'current_borrower', { join_type => "LEFT" });
__PACKAGE__->has_many('dvdtags', 'Dvdtag', { 'foreign.dvd' => 'self.dvd_id' });
__PACKAGE__->has_many('viewings', 'DBSchema::Result::Viewing', { 'foreign.dvd_id' => 'self.dvd_id' });
__PACKAGE__->many_to_many('tags', 'dvdtags' => 'tag');
# same relationship with a name that's different from the column name
__PACKAGE__->many_to_many('rel_tags', 'dvdtags' => 'rel_tag');
__PACKAGE__->might_have(
    liner_notes => 'DBSchema::Result::LinerNotes', undef,
    { proxy => [ qw/notes/ ] },
);
__PACKAGE__->add_relationship('like_has_many', 'DBSchema::Result::Twokeys', { 'foreign.dvd_name' => 'self.name' }, { accessor => 'multi', accessor_name => 'like_has_many' } );

__PACKAGE__->has_many(
    keysbymethod => 'KeysByMethod',
    { 'foreign.dvd' => 'self.dvd_id' }
);

1;
