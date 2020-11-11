use 5.008;

use strict;
use warnings;

use Test::More;

use DBI;

my $dbh = DBI->connect( 'DBI:Mock:', '', '' )
    || die "Cannot create handle: $DBI::errstr\n";

$dbh->{mock_start_insert_id} = ['Foo', 123];
$dbh->{mock_start_insert_id} = ['Baz', 345];

{
    my $sth = $dbh->prepare('INSERT INTO Foo (foo, bar) values (?, ?)');

    $sth->execute(15, 17);
    is($dbh->{mock_last_insert_id}, 123, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 123, "... got the right insert id from the database's last_insert_id");

    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 123, "... got the right insert id from the statement handle's last_insert_id");
    }

    $sth->execute(16, 18);
    is($dbh->{mock_last_insert_id}, 124, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 124, "... got the right insert id from the database handle's last_insert_id");
    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 124, "... got the right insert id from the statement handle's last_insert_id");
    }

    $sth->execute(19, 34);
    is($dbh->{mock_last_insert_id}, 125, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 125, "... got the right insert id from the database handle's last_insert_id");
    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 125, "... got the right insert id from the statement handle's last_insert_id");
    }
}

{
    my $sth = $dbh->prepare('INSERT IGNORE INTO Baz (foo, bar) values (?, ?)');

    $sth->execute(90, 41);
    is($dbh->{mock_last_insert_id}, 345, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 345, "... got the right insert id from the database handle's last_insert_id");
    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 345, "... got the right insert id from the statement handle's last_insert_id");
    }

    $sth->execute(32, 71);
    is($dbh->{mock_last_insert_id}, 346, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 346, "... got the right insert id from the database handle's last_insert_id");
    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 346, "... got the right insert id from the statement handle's last_insert_id");
    }

    $sth->execute(77, 42);
    is($dbh->{mock_last_insert_id}, 347, '... got the right insert id');
    is($dbh->last_insert_id((undef)x4), 347, "... got the right insert id from the database handle's last_insert_id");
    SKIP: {
        skip "Version of DBI::st doesn't support last_insert_id", 1 unless $sth->can('last_insert_id');

        is($sth->last_insert_id((undef)x4), 347, "... got the right insert id from the statement handle's last_insert_id");
    }
}

done_testing();
