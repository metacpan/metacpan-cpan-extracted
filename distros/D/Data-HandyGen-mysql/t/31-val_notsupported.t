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
            value1 set('foo', 'bar') not null,
            value2 set('magu', 'nanase') null
        )
    });

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);

    subtest 'Not supported type' => sub {
        subtest 'Not nullable' => sub {
            subtest 'Does not have a value' => sub {
                throws_ok { $hd->insert('test_notsupported', { value2 => 'magu' }) }
                    qr/^Type set for value1 is not supported./;
            };

            subtest 'Have a value' => sub {
                my $id = $hd->insert('test_notsupported', { value1 => 'foo', value2 => 'nanase' });
                my $row = $dbh->selectrow_hashref(q{SELECT * FROM test_notsupported WHERE id = ?}, undef, $id);
                is($row->{value1}, 'foo');
            };
        };

        subtest 'Nullable' => sub {
            subtest 'Does not have a value' => sub {
                my $id = $hd->insert('test_notsupported', { value1 => 'bar' });
                my $row = $dbh->selectrow_hashref(q{SELECT * FROM test_notsupported WHERE id = ?}, undef, $id);
                is($row->{value2}, undef);
            };

            subtest 'Have a value' => sub {
                my $id = $hd->insert('test_notsupported', { value1 => 'bar', value2 => 'nanase' });
                my $row = $dbh->selectrow_hashref(q{SELECT * FROM test_notsupported WHERE id = ?}, undef, $id);
                is($row->{value2}, 'nanase');
            };
        };
    };

    $dbh->disconnect();

    done_testing();
}

