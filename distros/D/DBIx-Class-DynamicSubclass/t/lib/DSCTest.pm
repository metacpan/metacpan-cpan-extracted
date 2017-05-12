package # hide from PAUSE
    DSCTest;

use strict;
use warnings;
use DSCTest::Schema;

sub init {
    my $db_file = "t/var/DSCTest.db";
    -f && unlink for $db_file, $db_file . "-journal";
    mkdir("t/var") unless -d "t/var";

    my $schema = DSCTest::Schema->connect("dbi:SQLite:${db_file}");
    $schema->deploy(undef, 't/');
    $schema;
}

1;
