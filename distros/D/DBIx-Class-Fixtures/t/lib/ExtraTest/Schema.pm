package ExtraTest::Schema::Result::Album;

use base 'DBIx::Class::Core';

__PACKAGE__->table('album');
__PACKAGE__->add_columns(
  'albumid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('albumid');

__PACKAGE__->has_many(
    photos => 'ExtraTest::Schema::Result::Photo'
);

1;

package ExtraTest::Schema::Result::Photographer;

use base 'DBIx::Class::Core';

__PACKAGE__->table('photographer');
__PACKAGE__->add_columns(
  'photographerid' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('photographerid');

__PACKAGE__->has_many(
    photos => 'ExtraTest::Schema::Result::Photo'
);

1;


package ExtraTest::Schema::Result::Photo;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw/InflateColumn::FS/);
__PACKAGE__->table('photo');

__PACKAGE__->add_columns(
  photo_id => {
	data_type => 'integer',
	is_auto_increment => 1,
  },
  album => {
    data_type => 'integer',
  },
  photographer => {
    data_type => 'integer',
  },
  file => {
	data_type => 'varchar',
	size => 255,
    is_fs_column => 1,
    fs_column_path =>'./t/var/files',
  });

__PACKAGE__->set_primary_key('photo_id');

__PACKAGE__->belongs_to( photographer => 'ExtraTest::Schema::Result::Photographer' );
__PACKAGE__->belongs_to( album => 'ExtraTest::Schema::Result::Album' );

package ExtraTest::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->register_class(
  Album => 'ExtraTest::Schema::Result::Album');
__PACKAGE__->register_class(
  Photographer => 'ExtraTest::Schema::Result::Photographer');
__PACKAGE__->register_class(
  Photo => 'ExtraTest::Schema::Result::Photo');

sub load_sql {
  local $/ = undef;
  my $sql = <DATA>;
}

sub init_schema {
  my $sql = (my $schema = shift)
    ->load_sql;

  ($schema->storage->dbh->do($_) ||
   die "Error on SQL: $_\n")
    for split(/;\n/, $sql);
}

1;

__DATA__
CREATE TABLE album (
  albumid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);
CREATE TABLE photographer (
  photographerid INTEGER PRIMARY KEY NOT NULL,
  name varchar(100) NOT NULL
);
CREATE TABLE photo (
  photo_id INTEGER PRIMARY KEY NOT NULL,
  album INTEGER NOT NULL,
  photographer INTEGER NOT NULL,
  file varchar(255) NOT NULL
)

