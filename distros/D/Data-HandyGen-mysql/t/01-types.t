#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::mysqld;
use DBI;

use Data::HandyGen::mysql;

main();
exit(0);


sub main {

    my $mysqld = Test::mysqld->new( my_cnf => { 'skip-networking' => '' } )
        or plan skip_all => $Test::mysqld::errstr;

    my $dbh = DBI->connect(
                $mysqld->dsn(dbname => 'test')
    ) or die $DBI::errstr;

    
    $dbh->do("CREATE TABLE table_int (val integer)");

    my $hd = Data::HandyGen::mysql->new(dbh => $dbh);
    my $desc = $hd->_table_def('table_int')->def;

    is(keys %$desc, 1, 'table_int: num of columns');
    is($desc->{val}{DATA_TYPE} , 'int', 'table_int: type of column');

    $dbh->disconnect();

    done_testing();
}


__END__

types.t
Check if correct column type names can be retrieved.

