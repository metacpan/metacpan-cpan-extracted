package # hide from PAUSE
    RestrictByUserTest;

use strict;
use warnings;
use RestrictByUserTest::Schema;

sub init_schema {
  my $self = shift;
  my $db_file = "t/var/RestrictByUserTest.db";

  unlink($db_file) if -e $db_file;
  unlink($db_file . "-journal") if -e $db_file . "-journal";
  mkdir("t/var") unless -d "t/var";

  my $schema = RestrictByUserTest::Schema->connect( "dbi:SQLite:${db_file}");
  $schema->deploy();
  return $schema;
}

1;
