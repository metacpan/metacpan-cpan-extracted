use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires 'DBIx::Inspector', 'DBD::SQLite';
use DBI;

sub create_dbh {
    my $orig_dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    my $dbh = DBI->connect('dbi:PassThrough:', '', '', {pass_through_source => $orig_dbh});
    $dbh->do(q{CREATE TABLE member (id integer, name)}) or die $dbh->errstr;
    $dbh->do(q{INSERT INTO member (id, name) VALUES (1, "John")}) or die $dbh->errstr;
    $dbh->do(q{INSERT INTO member (id, name) VALUES (2, "Ben")}) or die $dbh->errstr;
    $dbh->do(q{CREATE TABLE entry (id integer, body)}) or die $dbh->errstr;
    return $dbh;
}

subtest 'tables(inspector)' => sub {
    my $dbh = create_dbh();
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    is(join(', ', sort { $a cmp $b } map { $_->name } $inspector->tables), 'entry, member');
};

done_testing;

