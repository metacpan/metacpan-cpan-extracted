use strict;
use Test::More 0.98;

use DBI;

my $dbh = DBI->connect('dbi:BlackHole:', undef, undef);

for my $prepare_method (qw/prepare prepare_cached/) {
    note "prepare_method: $prepare_method";
    my $sth = $dbh->$prepare_method('INSERT INTO my_table VALUES (?)');
    ok !$sth->{Active};
    isa_ok $sth, 'DBI::st';

    my $ret = $sth->execute(1);
    is $ret, '1';
    ok !$sth->{Active};

    is $sth->rows, 0;

    ok $sth->finish;;
    ok !$sth->{Active};

    $sth = $dbh->$prepare_method('SELECT * FROM my_table');
    isa_ok $sth, 'DBI::st';

    $ret = $sth->execute();
    is $ret, '1';
    is $sth->rows, 0;

    for my $fetch_method (qw/fetch fetchrow_array fetchrow_arrayref fetchrow_hashref/) {
        my $row = $sth->$fetch_method;
        is $row, undef;
    }

    ok $sth->finish;
    ok !$sth->{Active};
}

done_testing;

