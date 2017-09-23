package Schema3::Result::Person;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('person');

__PACKAGE__->add_columns(
  id => {
	data_type => 'integer',
	is_auto_increment => 1,
  },
  name => {
    data_type => 'varchar',
    size => 255,
  },
  weight => {
    datatype => 'float',
  },
  height => {
    datatype => 'float',
  },
);

__PACKAGE__->set_primary_key('id');

# Add virtual column
__PACKAGE__->resultset_attributes({
  '+select' => [ \'weight/height' ],
  '+as'     => [ 'weight_to_height_ratio' ],
});

package Schema3;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->register_class(Person => 'Schema3::Result::Person');

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
CREATE TABLE person (
  id INTEGER PRIMARY KEY NOT NULL,
  name varchar(255) NOT NULL,
  weight FLOAT NOT NULL,
  height FLOAT NOT NULL
);

INSERT INTO person (name, weight, height)
VALUES
('Fred Flintstone', 220, 5.2),
('Barney Rubble', 190, 4.8)
