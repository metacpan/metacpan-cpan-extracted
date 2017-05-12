use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
    local $@;
    eval {require Text::CSV_XS};
    unless ($@) {
        if ($Text::CSV_XS::VERSION < 1.00) {
            note 'Text::CSV_XS version 0.99 or under has utf8 problem. force Text::CVS_PP.';
            $ENV{PERL_TEXT_CSV} = 'Text::CSV_PP';
        }
    }
}
use DBI;
use DBIx::FixtureLoader;
use Test::Requires 'Test::mysqld';

my $mysqld = Test::mysqld->new(my_cnf => {'skip-networking' => ''}) or plan skip_all => $Test::mysqld::errstr;
my $dbh = DBI->connect($mysqld->dsn, '', '', {RaiseError => 1, mysql_enable_utf8 => 1}) or die 'cannot connect to db';

$dbh->do(q{SET SESSION sql_mode='TRADITIONAL'});
$dbh->do(q{DROP TABLE IF EXISTS item;});
$dbh->do(q{
    CREATE TABLE item (
        id        INTEGER PRIMARY KEY,
        name      VARCHAR(255),
        attribute TINYINT NOT NULL DEFAULT 1
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
});

my $m = DBIx::FixtureLoader->new(
    dbh              => $dbh,
    skip_null_column => 1,
    update           => 1,
);
ok !$m->bulk_insert;
$m->load_fixture('t/data/item-skip-null.csv');

my $result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM item ORDER BY id;');
is $result->[0], 2;

my $rows = $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id;', {Slice => {}});
is scalar @$rows, 2;
is $rows->[0]{attribute}, 5;
is $rows->[1]{attribute}, 1;

$m->load_fixture('t/data/item-skip-null.csv');
is $rows->[1]{attribute}, 1;

done_testing;
