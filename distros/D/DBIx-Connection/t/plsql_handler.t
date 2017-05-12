
use strict;
use warnings;

use Test::More tests => 10;

use DBIx::Connection;

BEGIN {
use_ok('DBIx::PLSQLHandler');
}

SKIP: {
skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 9) unless $ENV{DB_TEST_CONNECTION};

my $connection = DBIx::Connection->new(
    name     => 'my_connection_name',
    dsn      => $ENV{DB_TEST_CONNECTION},
    username => $ENV{DB_TEST_USERNAME},
    password => $ENV{DB_TEST_PASSWORD},
); 
my $dialect = lc($connection->dbms_name);
{
    my $plsql_handler = new DBIx::PLSQLHandler(
        name        => 'test',
        connection  => $connection,
        plsql       => "BEGIN
        " . ($dialect ne 'mysql'
             ? ":var1 := :var2 || :var3;"
             : ":var1 := concat(:var2, :var3);") .
             "
        :var2 := 'done';
        END;
    ");
    
    isa_ok($plsql_handler, 'DBIx::PLSQLHandler');
    
    my $bind_variables = $plsql_handler->bind_variables;
    is_deeply($bind_variables, {
        var1 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'out'
        },
        var2 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'inout'
        },
        var3 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'in'
        }
    }, 'should have bind variables');
    
    
    my $result_set = $plsql_handler->execute(var2 => 'abc', var3 => 'def');
    is_deeply($result_set, {
      'var1' => 'abcdef',
      'var2' => 'done'
    }, 'should have plsql resultset');
}

{
    my $plsql_handler = new DBIx::PLSQLHandler(
        name        => 'int_test',
        connection  => $connection,
        plsql       => "BEGIN
        :var1 := :var2 + :var3;
        END;",
        bind_variables => {
            var1 => {type => 'SQL_INTEGER'},
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
        }
    );
    my $result_set = $plsql_handler->execute(var2 => 12, var3 => 8);
    is($result_set->{var1}, 20, 'should have sum');
}

{
    my $plsql_handler = new DBIx::PLSQLHandler(
        name        => 'test_proc',
        connection  => $connection,
        plsql       => "
        DECLARE
        var1 INT;
        BEGIN
        " . ($dialect eq 'mysql' ? 'SET' : ''). " var1 := :var2 + :var3;
        END;",
        bind_variables => {
            var2 => {type => 'SQL_INTEGER'},
            var3 => {type => 'SQL_INTEGER'}
        }
    );
    eval {
        my $result_set = $plsql_handler->execute(var2 => 12, var3 => 8);
    };
    ok(!$@, 'should execute block');
}


{
    #dynamic change of procedure
    my $plsql_handler = $connection->plsql_handler(
        name        => 'test',
        connection  => $connection,
        plsql       => "BEGIN
        " . ($dialect ne 'mysql'
            ? ":var1 := :var3 || :var2;"
            : ":var1 := concat(:var3, :var2);") .
            "
        :var2 := 'done';
        END;
    ");

    
    isa_ok($plsql_handler, 'DBIx::PLSQLHandler');
    my $plsql_cached = $connection->find_plsql_handler('test');
    is($plsql_handler, $plsql_cached, 'should find plsql handler');
    my $bind_variables = $plsql_handler->bind_variables;
    is_deeply($bind_variables, {
        var1 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'out'
        },
        var2 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'inout'
        },
        var3 => {
          type => 'SQL_VARCHAR',
          width => 32000,
          binding => 'in'
        }
    }, 'should have bind variables');
    
    
    my $result_set = $plsql_handler->execute(var2 => 'abc', var3 => 'def');
    is_deeply($result_set, {
      'var1' => 'defabc',
      'var2' => 'done'
    }, 'should have plsql resultset');
    }
}
   