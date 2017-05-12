
use strict;
use warnings;

use DBIx::Connection;

my $connection = DBIx::Connection->new(
        name     => 'my_connection_name',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
); 

my $cursor = $connection->query_cursor(sql => "select * from emp where deptno > ?", name => 'emp_select');
my $dataset = $cursor->execute(20);
while ($cursor->fetch) {
    print $_ . " => " . $dataset->{$_}
      for keys %$dataset;
}

my $record = $connection->record("select * from emp where empno = ?", 'xxx');

my $sql_handler = $connection->sql_handler(sql => "INSERT INTO emp(empno, ename) VALUES(?, ?)", name => 'emp_ins');
$sql_handler->execute(1, 'Smith');
$sql_handler->execute(2, 'Witek');
