use strict;
use warnings;

use Test::More tests => 5;

BEGIN{
    use_ok('DBIx::Connection');
}


SKIP: {

    skip('missing env varaibles DB_TEST_CONNECTION, DB_TEST_USERNAME DB_TEST_PASSWORD', 4)
      unless $ENV{DB_TEST_CONNECTION};

    my $connection = DBIx::Connection->new(
        name     => 'my_connection_name',
        dsn      => $ENV{DB_TEST_CONNECTION},
        username => $ENV{DB_TEST_USERNAME},
        password => $ENV{DB_TEST_PASSWORD},
    );

    my $table_not_exists = 1;
    eval {
        $connection->record("SELECT id FROM lob_test");
        $table_not_exists = 0;
    };
    
    SKIP: {
        if ($table_not_exists) {
            my %table = ();
            $table{Oracle} = 'CREATE TABLE lob_test(id NUMBER, name VARCHAR2(100), doc_size NUMBER, blob_content BLOB)';
            $table{PostgreSQL} = 'CREATE TABLE lob_test(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content oid)';
            $table{MySQL} = 'CREATE TABLE lob_test(id NUMERIC, name VARCHAR(100), doc_size NUMERIC, blob_content LONGBLOB)';
            print "\n#missing test table " . $table{$connection->dbms_name};
            skip('missing table', 4);
        }
        $connection->do("DELETE FROM lob_test");
        $connection->do("INSERT INTO lob_test(id, name) VALUES(1, 'test 1')");
        $connection->do("INSERT INTO lob_test(id, name) VALUES(2, 'test 2')");
        $connection->do("INSERT INTO lob_test(id, name) VALUES(3, 'test 3')");
        my $lob_content = 'AB' . ((chr(1) . chr(3) . chr(10)) x (1024 * 31)) . chr(2);
        eval {
            $connection->update_lob(lob_test => 'blob_content', $lob_content, {id => 1}, 'doc_size');
        };
        ok(! $@, 'should update lob');
         {
            my $lob = $connection->fetch_lob(lob_test => 'blob_content', {id => 1}, 'doc_size');
          
            is($lob, $lob_content, 'should fetch lob content');
         }
        eval {
            $connection->update_lob(
                lob_test => 'blob_content',
                ('Z'. $lob_content . $lob_content),
                {id => 1},
                'doc_size'
            );
        };
        ok(! $@, 'should update lob');

         {
            my $lob = $connection->fetch_lob(lob_test => 'blob_content', {id => 1}, 'doc_size');
            is($lob, ('Z'. $lob_content . $lob_content), 'should fetch lob content');
         }
    }
}