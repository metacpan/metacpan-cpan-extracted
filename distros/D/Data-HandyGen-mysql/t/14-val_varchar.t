#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use DBI;
use Test::mysqld;

use Data::HandyGen::mysql;

plan skip_all => 'mysql_install_db not found'
    unless `which mysql_install_db 2>/dev/null`;

main();
done_testing();

exit(0);


sub main {

    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;

    $dbh->do(q{
        CREATE TABLE table_varchar (
            id      integer primary key auto_increment,
            string0 varchar(10) not null,
            string1 varchar(9) not null,
            string2 varchar(8) not null,
            string3 varchar(7) not null,
            string4 varchar(6) not null,
            string5 varchar(2) not null,
            string6 varchar(1) not null
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    #  Basically, column names + '_' + ID
    $dbh->do(q{ALTER TABLE table_varchar AUTO_INCREMENT = 1});  #  next ID = 1
    my $id = $hd->insert('table_varchar');

    my $sth = $dbh->prepare('SELECT * FROM table_varchar WHERE id = ?');
    $sth->bind_param(1, $id);
    $sth->execute();

    my $result = $sth->fetchrow_hashref();

    is($result->{string0}, 'string0_1');
    is($result->{string1}, 'string1_1');
    is($result->{string2}, 'string_1');
    is($result->{string3}, 'strin_1');
    is($result->{string4}, 'stri_1');
    is($result->{string5}, '_1');
    is($result->{string6}, '1');

    $dbh->do(q{ALTER TABLE table_varchar AUTO_INCREMENT = 1234567});  #  next ID = 1234567
    $id = $hd->insert('table_varchar');

    $sth->bind_param(1, $id);
    $sth->execute();

    $result = $sth->fetchrow_hashref();

    is($result->{string0}, 'st_1234567');
    is($result->{string1}, 's_1234567');
    is($result->{string2}, '_1234567');
    is($result->{string3}, '1234567');
    is(length($result->{string4}), 6);
    is(length($result->{string5}), 2);
    is(length($result->{string6}), 1);
     

    $sth->finish;
    $dbh->disconnect;
}


