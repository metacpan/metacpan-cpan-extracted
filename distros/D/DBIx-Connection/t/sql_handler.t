
use strict;
use warnings;

use Test::More tests => 6;

use DBIx::Connection;

BEGIN {
    use_ok('DBIx::SQLHandler');
}

SKIP: {
    # all tests assume that there is the following table CREATE TABLE test(id NUMBER, name VARCHAR2(100))
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 5)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
        name     => 'my_connection_name',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    ); 
    
    my $table_not_exists = 1;
    eval {
        $connection->record("SELECT * FROM test");
        $table_not_exists = 0;
    };

SKIP: {
    
    if ($table_not_exists) {
        print "\n#missing test table CREATE TABLE test(id NUMBER, name VARCHAR2(100))\n";
        skip('missing table', 5);
    }

	ok($connection->has_table('test'));
    
        $connection->do("DELETE FROM test");
        {    
            my $sql_handler = new DBIx::SQLHandler(
                name        => 'test_ins',
                connection  => $connection,
                sql         => "INSERT INTO test(id, name) VALUES(?, ?)"
            );
            eval {
                $sql_handler->execute(1, 'Smith');
            };
            ok(! $@, 'should insert a row');
        }
    
        {    
            my $sql_handler = new DBIx::SQLHandler(
                name        => 'test_ins',
                connection  => $connection,
                sql         => "UPDATE test SET name = ? WHERE id = ?"
            );
            eval {
                $sql_handler->execute('Smith1',1)
            };
            ok(! $@, 'should update a row');
        }
    
    
        {    
            my $sql_handler = $connection->sql_handler(
                name        => 'test_del',
                sql         => "DELETE FROM test WHERE id = ?"
            );
            is($sql_handler, $connection->find_sql_handler('test_del'), 'should have cached sql handler');
            eval {
                $sql_handler->execute('1');
            };
            ok( ! $@ , 'should delete row');
        }
    }

}
