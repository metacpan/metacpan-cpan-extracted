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
  photographer => {
    data_type => 'varchar',
    size => 40,
  },
  file => {
	data_type => 'varchar',
	size => 255,
    is_fs_column => 1,
    fs_column_path =>'./t/var/files',
  });

__PACKAGE__->set_primary_key('photo_id');

package ExtraTest::Schema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

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
CREATE TABLE photo (
  photo_id INTEGER PRIMARY KEY NOT NULL,
  photographer varchar(40) NOT NULL,
  file varchar(255) NOT NULL
)

