package # hide from PAUSE
  RestrictByUserTest::Schema;

use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes(qw/ Users Notes /);
__PACKAGE__->load_components('Schema::RestrictWithObject');

1;
