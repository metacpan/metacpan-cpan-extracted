use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires qw/DBD::SQLite/;

use DBI;

sub create_dbh {
    my $orig_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    my $dbh = DBI->connect('dbi:PassThrough:', '', '', {pass_through_source => $orig_dbh});
    $dbh->do(q{CREATE TABLE member (id integer not null primary key, name)}) or die $dbh->errstr;
    $dbh->do(q{INSERT INTO member (id, name) VALUES (1, "John")}) or die $dbh->errstr;
    $dbh->do(q{INSERT INTO member (id, name) VALUES (2, "Ben")}) or die $dbh->errstr;
    return $dbh;
}

subtest 'selectrow_array' => sub {
    my $dbh = create_dbh();
    my $cnt = $dbh->selectrow_array(q{SELECT COUNT(*) FROM member;});
    is($cnt, 2);
};
subtest 'prepare_cached' => sub {
    my $dbh = create_dbh();
    my $sth = $dbh->prepare_cached(q{SELECT SUM(id) FROM member});
    $sth->execute();
    is($sth->fetchrow_array(), 3);
};
subtest 'FETCH' => sub {
    my $dbh = create_dbh();
    my $version = $dbh->{sqlite_version};
    ok $version;
    note $version;
};
subtest 'STORE' => sub {
    my $dbh = create_dbh();
    {
        no utf8;
        $dbh->do(q{INSERT INTO member (id, name) VALUES (?, ?)}, {}, 3, 'さいきろん');
    }
    $dbh->{sqlite_unicode} = 1;
    my ($name) = $dbh->selectrow_array(q{SELECT name FROM member WHERE id=3});
    is($name, 'さいきろん');
};
subtest 'can_ok' => sub {
    my $dbh = create_dbh();
    can_ok($dbh, qw(table_info));
};
subtest 'last_insert_rowid' => sub {
    my $dbh = create_dbh();
    $dbh->do(q{INSERT INTO member (name) VALUES ("Gyan")}) or die $dbh->errstr;
    is($dbh->func('last_insert_rowid'), 3);
};

done_testing;

