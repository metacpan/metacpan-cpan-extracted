package # hide from PAUSE 
    DigestTest;

use strict;
use warnings;
use DigestTest::Schema;

sub initialise {

  my $db_file = "t/var/DigestTest.db";
  
  unlink($db_file) if -e $db_file;
  unlink($db_file . "-journal") if -e $db_file . "-journal";
  mkdir("t/var") unless -d "t/var";
  
  my $dsn = "dbi:SQLite:${db_file}";
  
  return DigestTest::Schema->compose_connection('DigestTest' => $dsn);
}

sub init_schema {
    my $self = shift;
    my $db_file = "t/var/DigestTest.db";

    unlink($db_file) if -e $db_file;
    unlink($db_file . "-journal") if -e $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $dsn = "dbi:SQLite:${db_file}";
    
    my $schema = DigestTest::Schema->compose_connection('DigestTest' => $dsn);
#    print $schema->storage->deployment_statements($schema);
    $schema->deploy();

    
    return $schema;
}

1;
