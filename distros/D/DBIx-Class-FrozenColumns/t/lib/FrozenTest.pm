package # hide from PAUSE 
    FrozenTest;

use strict;
use warnings;
use FrozenTest::Schema;

sub init {
    my $db_file = "t/var/FrozenTest.db";
    -f && unlink for $db_file, $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";
  
    my $schema = FrozenTest::Schema->connect("dbi:SQLite:${db_file}");
    $schema->deploy(undef, 't/');
    $schema;
}

1;
