package S;

use strict;
use warnings;
use base 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;

sub test_db {
  my $db = shift->connect("dbi:SQLite::memory:");
  $db->deploy({});

  return $db;
}

1;
