use strict;
use warnings;
use FindBin::libs;

use Test::More;

BEGIN {
    use_ok 'DBICTest::Schema';
}

{
    local $ENV{DBIC_NO_VERSION_CHECK} = 1;

    my $re = qr/test\-\d{8}\-\d{6}\.sql/;
    
    my $filename;
    $filename = DBICTest::Schema->connect('DBI:mysql:test')->storage->backup_filename;
    like
        $filename, $re, '$dsn = "DBI:mysql:$database"';
    
    $filename = DBICTest::Schema->connect('DBI:mysql:test','foo','bar')->storage->backup_filename;
    like
        $filename, $re, '$dsn = "DBI:mysql:$database"';
    
    $filename = DBICTest::Schema->connect('DBI:mysql:database=test;host=127.0.0.1','foo','bar')->storage->backup_filename;
    like
        $filename, $re, '$dsn = "DBI:mysql:database=$database;host=$hostname"';
    
    $filename = DBICTest::Schema->connect('DBI:mysql:dbname=test;host=127.0.0.1','foo','bar')->storage->backup_filename;
    like
        $filename, $re, '$dsn = "DBI:mysql:dbname=$database;host=$hostname"';
    
    $filename = DBICTest::Schema->connect('DBI:mysql:dbname=test;host=127.0.0.1;port=1234','foo','bar')->storage->backup_filename;
    like
        $filename, $re, '$dsn = "DBI:mysql:database=$database;host=$hostname;port=$port"';
    
}

done_testing;
