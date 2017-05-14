package # hide from PAUSE
    CdbiTreeTest;

use strict;
use warnings;
use CdbiTreeTest::Schema;

use FindBin '$Bin';

sub init_schema {
  my $self = shift;
  my $db_dir  = File::Spec->catdir($Bin, "var");
  my $db_file = File::Spec->catfile($db_dir, "Test.db");

  unlink($db_file) if -e $db_file;
  unlink($db_file . "-journal") if -e $db_file . "-journal";
  mkdir($db_dir) unless -d $db_dir;

  my $dsn = "dbi:SQLite:dbname=${db_file}";
  #my $dsn = "dbi:mysql:dbname=mobius";
  my $schema = CdbiTreeTest::Schema->connect($dsn);
  $schema->deploy();
  return $schema;
}

sub clear {
  my $db_dir  = File::Spec->catdir($Bin, "var");
  my $db_file = File::Spec->catfile($db_dir, "Test.db");
  return unless -e $db_file;
  $_[0]->storage->disconnect;
  unlink($db_file) or die "Failed to clear test db $db_file";
}

1;
