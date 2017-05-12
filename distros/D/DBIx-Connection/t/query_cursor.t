
use strict;
use warnings;

use Test::More tests => 39;
use DBIx::Connection;

BEGIN{
    use_ok('DBIx::QueryCursor');
}

SKIP: {
    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 38)
      unless $ENV{DB_TEST_CONNECTION};
    

    my $connection = DBIx::Connection->new(
        name     => 'my_connection_name',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    ); 
    
    my $dialect = lc($connection->dbms_name);
    my $cursor = $connection->query_cursor(
        name       => 'my_cursor',
        sql        => "
        SELECT t.* FROM (
        SELECT 1 AS col1, 'text 1' AS col2 " . ($dialect eq 'oracle' ? ' FROM dual' : '') . "
        UNION ALL
        SELECT 2 AS col1, 'text 2' AS col2 " . ($dialect eq 'oracle' ? ' FROM  dual' : '') . "
        ) t
        WHERE 1 = ? "
    );
    is($cursor, $connection->find_query_cursor('my_cursor'), 'should have cached query cursor');
    $cursor->execute([1]);
    is_deeply($cursor->columns, ['col1', 'col2'], 'should have query columns');
    
    isa_ok($cursor, 'DBIx::QueryCursor');
    {
        my $result_set = $cursor->execute([1]);
        ok($cursor->fetch(), 'should fetch row');
        {
            ok($result_set , 'should have more results');
            is('1', $result_set->{col1}, 'should have value for the column col 1');
            is('text 1', $result_set->{col2}, 'should have value for the column col 2');
            
        }

        ok($cursor->fetch(), 'should fetch row');
        {
            ok($result_set , 'should have more results');
            is('2', $result_set->{col1}, 'should have value for the column col 1');
            is('text 2', $result_set->{col2}, 'should have value for the column col 2');
        }
    }
        

    {
        my $result_set = $cursor->execute([1], []);
        ok($cursor->fetch(), 'should fetch row');
        {
            ok($result_set , 'should have more results');
            is('1', $result_set->[0], 'should have value for the column col 1');
            is('text 1', $result_set->[1], 'should have value for the column col 2');
            
        }

        ok($cursor->fetch(), 'should fetch row');
        {
            ok($result_set , 'should have more results');
            is('2', $result_set->[0], 'should have value for the column col 1');
            is('text 2', $result_set->[1], 'should have value for the column col 2');
        }
    }

    {       
        my @result_set;
        $cursor->execute([1], \@result_set);
        my $iterator = $cursor->iterator;
        
        is(ref($iterator), 'CODE', 'should have code reference as intereator');
        {
            my $result = $iterator->();
            ok($result, 'should have more results');
            is_deeply($result, \@result_set, 'should have the same values');
            is($result_set[0], 1, 'should have value for the column col 1');
            is($result_set[1], 'text 1', 'should have value for the column col 2');
            
        }
        {
            my $result = $iterator->();
            ok($result, 'should have more results');
            is_deeply($result, \@result_set, 'should have the same values');
            is($result_set[0], 2, 'should have value for the column col 1');
            is($result_set[1], 'text 2', 'should have value for the column col 2');
            ok(! $iterator->(), 'should not have any more results');
        }
    }
    
    {
        my %result_set;
        $cursor->execute([1], \%result_set);
        my $iterator = $cursor->iterator;
        is(ref($iterator), 'CODE', 'should have code reference as intereator');
        {
            my $result = $iterator->();
            is_deeply($result, [1, 'text 1'], 'should have value for row 1');
            is($result->[0], $result_set{col1}, 'should have value for the column col 1');
            is($result->[1], $result_set{col2}, 'should have value for the column col 2');
        }
        is(1, $cursor->rows, 'should retrieve 1 row');
        
        {
            my $result = $iterator->();
            is_deeply($result, [2, 'text 2'], 'should have value for row 2');
            is($result->[0], $result_set{col1}, 'should have value for the column col 1');
            is($result->[1], $result_set{col2}, 'should have value for the column col 2');
        }
        
        is(2, $cursor->rows, 'should retrieve 2 rows');
    }


}