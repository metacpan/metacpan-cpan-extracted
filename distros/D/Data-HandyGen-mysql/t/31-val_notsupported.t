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


# 

sub main {
    
    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;
    $dbh->{RaiseError} = 1;

    $dbh->do(q{
        CREATE TABLE test_notsupported (
            id integer primary key auto_increment,
            value set('foo', 'bar') not null
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    my ($id, $row);
    SKIP: {
        eval { use Test::Warn };
        skip 'Test::Warn is not installed.', 1 if $@;

        warnings_exist { $id = $hd->insert('test_notsupported', {}) }
            qr/^Type set for value is not supported./;
    }
    $row = $dbh->selectrow_hashref(q{SELECT * FROM test_notsupported WHERE id = ?}, undef, $id);
    is($row->{value}, '');    

    $id = $hd->insert('test_notsupported', { value => 'bar' });
    $row = $dbh->selectrow_hashref(q{SELECT * FROM test_notsupported WHERE id = ?}, undef, $id);
    is($row->{value}, 'bar');    

    $dbh->disconnect();

    done_testing();
}

