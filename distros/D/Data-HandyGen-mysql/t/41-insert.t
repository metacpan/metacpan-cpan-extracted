#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;


main();
exit(0);


#   process_table 


sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;
    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);


    for my $engine (qw/ INNODB MyISAM /) {
        diag "Testing $engine ...";
        $dbh->do(qq{SET storage_engine=$engine});
        test_nullable($hd);
        test_pk($hd);
        test_notnull_nofk($hd);
        test_notnull_default_fk($hd);
        test_notnull_nodefault_fk($hd);
        test_error($hd);
        test_nopk($hd);
        test_pk2($hd);
    }

    $dbh->disconnect();

    done_testing();
}


#  No values will be assigned to nullable column. 
#  (Although default value will be assigned if exists)
sub test_nullable {
    my ($hd) = @_;

    $hd->fk(1);
    my $dbh = $hd->dbh;

    $dbh->do(q{DROP TABLE IF EXISTS test_nullable});
    $dbh->do(q{DROP TABLE IF EXISTS test_nullable_foreign});
    $dbh->do(q{
        CREATE TABLE test_nullable_foreign (
            id int primary key,
            name varchar(10)
        )
    });
    $dbh->do(q{
        CREATE TABLE test_nullable (
            col_with_default    int DEFAULT 100,
            col_without_default int,
            col_with_fk         int,
            CONSTRAINT FOREIGN KEY (col_with_fk) REFERENCES test_nullable_foreign(id)
        )
    });
    
    my $id = $hd->insert('test_nullable');
    is($id, undef);

    my ($count) = $dbh->selectrow_array(q{ SELECT COUNT(*) FROM test_nullable });
    is($count, 1);

    ($count) = $dbh->selectrow_array(q{ SELECT COUNT(*) FROM test_nullable_foreign });
    is($count, 0);

    my @cols = $dbh->selectrow_array(q{
        SELECT col_with_default, col_without_default, col_with_fk 
        FROM test_nullable
    });
    is($cols[0], 100);      #  col_with_default (default value will be assigned)
    is($cols[1], undef);    #  col_without_default -> undef
    is($cols[2], undef);    #  col_with_fk -> undef

}


sub test_pk {
    my ($hd) = @_;

    my $dbh = $hd->dbh;

    #  auto_increment primary key
    $dbh->do(q{DROP TABLE IF EXISTS test_pk_ai});
    $dbh->do(q{
        CREATE TABLE test_pk_ai (
            id int primary key auto_increment
        )});
    #  If pk value is specified, the value will be used.
    my $id = $hd->insert('test_pk_ai', { id => 200 });
    is($id, 200);

    #  If pk value is not specified and pk column is auto_increment,
    #  auto_increment value will be used.
    $dbh->do(q{ALTER TABLE test_pk_ai AUTO_INCREMENT = 300});
    $hd->_set_user_valspec('test_pk_ai', {});   #  reset valspec
    $id = $hd->insert('test_pk_ai');
    is($id, 300);
    $id = $hd->insert('test_pk_ai');
    is($id, 301);
    
    #  Non-auto_increment primary key 
    $dbh->do(q{DROP TABLE IF EXISTS test_pk_nai});
    $dbh->do(q{
        CREATE TABLE test_pk_nai (
            id int primary key
        )});
    #  Random value will be assigned.
    $id = $hd->insert('test_pk_nai');
    like($id, qr/^\d+$/, "(random id is $id)");
   
    
    #  Varchar primary key
    $dbh->do(q{DROP TABLE IF EXISTS test_pk_varchar});
    $dbh->do(q{
        CREATE TABLE test_pk_varchar (
            id varchar(10) primary key
        )});
    $id = $hd->insert('test_pk_varchar');
    like($id, qr/^\w{10}$/, "(random id is $id)");
    $id = $hd->insert('test_pk_varchar');
    like($id, qr/^\w{10}$/, "(random id is $id)");

    $id = $hd->insert('test_pk_varchar', { id => 'abcde12345' });
    is($id, 'abcde12345');     
}


sub test_notnull_nofk {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{DROP TABLE IF EXISTS test_notnull_nofk});
    $dbh->do(q{
        CREATE TABLE test_notnull_nofk (
            id integer primary key auto_increment,
            nodefault1 int not null,
            nodefault2 varchar(10) not null,
            default1   int not null default 10,
            default2   varchar(10) not null default 'Default'
        )
    });
    my $id = $hd->insert('test_notnull_nofk', {});

    my $res = $dbh->selectrow_hashref(q{SELECT * FROM test_notnull_nofk WHERE ID = ?}, undef, $id);
    like($res->{nodefault1}, qr/^\d+$/, "random value is $res->{nodefault1}");
    like($res->{nodefault2}, qr/^\w{10}$/, "random value is $res->{nodefault2}");
    is($res->{default1}, 10);
    is($res->{default2}, 'Default');
}
        

sub test_notnull_default_fk {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $hd->fk(1);

    $dbh->do(q{DROP TABLE IF EXISTS test1});
    $dbh->do(q{DROP TABLE IF EXISTS foreign1});
    $dbh->do(q{
        CREATE TABLE foreign1 (
            id integer primary key auto_increment
        )});
    $dbh->do(q{
        CREATE TABLE test1 (
            id integer primary key auto_increment,
            default1 int not null default 10,
            constraint foreign key (default1) references foreign1 (id)
        )});
    
    #  first time (referenced record doesn't exist)
    my $id;
    lives_ok { $id = $hd->insert('test1', {}); }
        or diag "Maybe failed to add record to referenced table";

    my $res = $dbh->selectrow_hashref(q{SELECT * FROM test1 WHERE id = ?}, undef, $id);
    is($res->{default1}, 10);

    $res = $dbh->selectrow_hashref(q{SELECT * FROM foreign1 LIMIT 1});
    is($res->{id}, 10);

    #  second time (referenced record already exists)
    lives_ok { $id = $hd->insert('test1', {}); }
        or diag "Maybe failed to add record to referenced table";
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test1 WHERE id = ?}, undef, $id);
    is($res->{default1}, 10);
  
    #  No additional records exist 
    _check_row_count($dbh, 'foreign1', 1);
     

    $hd->fk(0);
}



sub test_notnull_nodefault_fk {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $hd->fk(1);
    $dbh->do(q{DROP TABLE IF EXISTS test2});
    $dbh->do(q{DROP TABLE IF EXISTS foreign2});
    $dbh->do(q{
        CREATE TABLE foreign2 (
            id integer primary key auto_increment
        )});
    $dbh->do(q{ALTER TABLE foreign2 AUTO_INCREMENT = 1});
    $dbh->do(q{
        CREATE TABLE test2 (
            id integer primary key auto_increment,
            default1 int not null,
            constraint foreign key (default1) references foreign2 (id)
        )});

    my $id;
    my $res;

    #
    #  No record exists in foreign2
    #
    $id = $hd->insert('test2', {});
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    my $test2_id = $res->{id};
    my $default1 = $res->{default1};

    $res = $dbh->selectrow_hashref(q{SELECT COUNT(*) as count FROM foreign2 WHERE id = ?}, undef, $default1);
    is($res->{count}, 1);
    
    $dbh->do(q{DELETE FROM test2 WHERE id = ?}, undef, $test2_id);
    $dbh->do(q{DELETE FROM foreign2 WHERE id = ?}, undef, $default1);

    my $INSERT_COUNT = 100;

    for ( 1 .. $INSERT_COUNT ) {
        $dbh->do(q{INSERT INTO foreign2 (id) VALUES(?)}, undef, $_ * 10007);
    }

    #
    #  No user value specified as column 'default1'
    #
    lives_ok { $id = $hd->insert('test2', {}) };
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    is( $res->{default1} % 10007, 0)
        or diag "default1 is $res->{default1}";

    #  No additional records exist
    _check_row_count($dbh, 'foreign2', $INSERT_COUNT);

    
    #
    #  'default1' is specified as one of foreign2.id
    #
    lives_ok { $id = $hd->insert('test2', { default1 => 10007 * 6 }) };
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    is( $res->{default1}, 10007 * 6 );

    #  No additional records exist
    _check_row_count($dbh, 'foreign2', $INSERT_COUNT);

    
    #
    #  'default1' is specified as a value which doesn't exist in foreign2.id
    #
    $INSERT_COUNT++;
    lives_ok {
        $id = $hd->insert('test2', { default1 => 10007 * $INSERT_COUNT });
    };
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    is( $res->{default1}, 10007 * $INSERT_COUNT );

    #  Additional record has been created.
    _check_row_count($dbh, 'foreign2', $INSERT_COUNT);
    $res = $dbh->selectrow_hashref(q{SELECT COUNT(*) as count FROM foreign2 WHERE id = ?}, undef, 10007 * $INSERT_COUNT);
    is( $res->{count}, 1 );
    

    #
    #  'default1' itself is not specified, instead foreign2.id is specified which already exists in foreign2
    #
    lives_ok {
        $id = $hd->insert('test2', { 'foreign2.id' => 10007 * 7 });
    };
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    is( $res->{default1}, 10007 * 7 );

    #  No additional records exist
    _check_row_count($dbh, 'foreign2', $INSERT_COUNT);
    

    #
    #  'default1' itself is not specified, instead foreign2.id is specified which doesn't exist in foreign2
    #
    $INSERT_COUNT++;
    lives_ok {
        $id = $hd->insert('test2', { 'foreign2.id' => 10007 * $INSERT_COUNT });
    };
    $res = $dbh->selectrow_hashref(q{SELECT * FROM test2 WHERE id = ?}, undef, $id);
    is( $res->{default1}, 10007 * $INSERT_COUNT );

    #  Additional record has been created. 
    _check_row_count($dbh, 'foreign2', $INSERT_COUNT);
    $res = $dbh->selectrow_hashref(q{SELECT COUNT(*) as count FROM foreign2 WHERE id = ?}, undef, 10007 * $INSERT_COUNT);
    is( $res->{count}, 1 );


    $hd->fk(0);
}


sub _check_row_count {
    my ($dbh, $table, $count) = @_;

    my $res = $dbh->selectrow_hashref(qq{SELECT COUNT(*) as count FROM $table});
    is($res->{count}, $count);
}



sub test_error {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{DROP TABLE IF EXISTS test_error1});
    $dbh->do(q{
        CREATE TABLE test_error1 (
            id integer
        )
    });

    #  table 'test_error2' does not exist.
    diag q{(NOTE) The following exception "Table ... doesn't exist" is an intended one.};
    throws_ok( 
        sub { $hd->insert('test_error2', { id => 'a' }) }, 
        qr/Table 'test.test_error2' doesn't exist/, 
        "(expected error)"
    );
}


sub test_nopk {
    my ($hd) = @_;
    
    my $dbh = $hd->dbh;
    
    $dbh->do(q{DROP TABLE IF EXISTS test_pk0});
    $dbh->do(q{
        CREATE TABLE test_pk0 (
            col1 varchar(10),
            col2 varchar(10) not null
        )
    });
    
    my $id = $hd->insert('test_pk0', { col1 => 'abc' });
    is($id, undef);
    
    my $row = $dbh->selectrow_hashref(q{
                SELECT * FROM test_pk0 LIMIT 1
            });
    is($row->{col1}, 'abc');
    like($row->{col2}, qr/^\w+$/);
}


sub test_pk2 {
    my ($hd) = @_;
    my $dbh = $hd->dbh;

    $dbh->do(q{DROP TABLE IF EXISTS test_pk2});
    $dbh->do(q{
        CREATE TABLE test_pk2 (
            id1 integer,
            id2 integer,
            col1 varchar(10) not null,
            PRIMARY KEY (id1, id2)
        )
    });
    
    my $id = $hd->insert('test_pk2', {});
    is($id, undef);
    
    my $row = $dbh->selectrow_hashref(q{
                SELECT * FROM test_pk2 LIMIT 1
            });
    like($row->{id1}, qr/^\d+$/);
    like($row->{id2}, qr/^\d+$/);
    like($row->{col1}, qr/^\w+$/);
}




     



