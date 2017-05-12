use strict;
use warnings;

use Test::More tests => 16;
use DBI;

BEGIN{
    use_ok('DBIx::Connection');
}


SKIP: {
    
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 15)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
      name     => 'my_connection_name',
      dsn      => $ENV{DB_TEST_CONNECTION},
      username => $ENV{DB_TEST_USERNAME},
      password => $ENV{DB_TEST_PASSWORD},
      db_session_variables => {
          #NLS_DATE_FORMAT => 'DD.MM.YYYY'
          #DATESTYLE => 'German'
      }
    ); 
    
    isa_ok($connection, 'DBIx::Connection', 'should have an instance of the DBIx::Connection');
    ok($connection->check_connection, 'should check connection');
    ok($connection->dbms_name, 'should have dbms name');
    my $dbh = $connection->dbh;
    my $connection1 = DBIx::Connection->new(
        name => 'my_connection_name1',
        dbh  => $dbh
    );
    isa_ok($connection1, 'DBIx::Connection');
    ok($connection1->dbms_name, 'should have dbms name');
    

    $DBIx::Connection::CONNECTION_POOLING = 1;
    $DBIx::Connection::IDLE_THRESHOLD = 1;
    my $pooled_connection1 = DBIx::Connection->connection('my_connection_name');
    my $pooled_connection2 = DBIx::Connection->connection('my_connection_name');
    my $pooled_connection3 = DBIx::Connection->connection('my_connection_name');
    
    isa_ok($pooled_connection1, 'DBIx::Connection', 'should have an instance of the DBIx::Connection');
    isa_ok($pooled_connection2, 'DBIx::Connection', 'should have an instance of the DBIx::Connection');
    isa_ok($pooled_connection3, 'DBIx::Connection', 'should have an instance of the DBIx::Connection');
    ok($pooled_connection1 ne $pooled_connection2 && $pooled_connection1 ne $pooled_connection3 && $pooled_connection3 ne $pooled_connection1, "have 3 instances of connection");
    $pooled_connection1->close();
    my $pooled_connection4 = DBIx::Connection->connection('my_connection_name');
    is($pooled_connection1, $pooled_connection4, "retrive connection from the connection pool");

    $pooled_connection3->close();
    my $pooled_connection5 = DBIx::Connection->connection('my_connection_name');
    is($pooled_connection3, $pooled_connection5, "retrive connection from the connection pool");
    


    $pooled_connection2->close();
    ok($pooled_connection2->is_connected, "connected");
    sleep(2);
    #this is called by connection method
    DBIx::Connection->check_connnections;
    ok(! $pooled_connection2->is_connected, "disconnected because of idle state");
    
    my $pooled_connection6 = DBIx::Connection->connection('my_connection_name');
    is($pooled_connection2, $pooled_connection6, "retrive connection from the connection pool");
    ok($pooled_connection6->is_connected, "reconnected");

 

}
