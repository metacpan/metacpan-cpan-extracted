use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBD::SQLite';
use DBI;

subtest 'disconnect' => sub {
    my $orig_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $orig_dbh->do(q{CREATE TABLE member (id integer, name)});
    $orig_dbh->do(q{INSERT INTO member (id, name) VALUES (1, "John")});

    {
        note 'just close parent';
        my $dbh = DBI->connect('dbi:PassThrough:', '', '', {pass_through_source => $orig_dbh});
        $dbh->disconnect();
    }
    subtest 'parent connection is not closed.' => sub {
        my $dbh = DBI->connect('dbi:PassThrough:', '', '', {pass_through_source => $orig_dbh});
        is($dbh->selectrow_array(q{SELECT COUNT(*) FROM member}), 1);
    };
};

done_testing;

