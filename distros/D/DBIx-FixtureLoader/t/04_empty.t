use strict;
use warnings;
use utf8;
use Test::More;
BEGIN {
    local $@;
    eval {require Text::CSV_XS};
    unless ($@) {
        note 'Text::CSV_XS version 0.99 or under has utf8 problem. force Text::CVS_PP.';
        $ENV{PERL_TEXT_CSV} = 'Text::CSV_PP' if $Text::CSV_XS::VERSION < 1.00;
    }
}
use DBI;
use DBIx::FixtureLoader;
use Test::Requires 'Test::mysqld';

my $mysqld = Test::mysqld->new(my_cnf => {'skip-networking' => ''}) or plan skip_all => $Test::mysqld::errstr;
my $dbh = DBI->connect($mysqld->dsn, '', '', {RaiseError => 1, mysql_enable_utf8 => 1}) or die 'cannot connect to db';

$dbh->do(q{DROP TABLE IF EXISTS zero;});
$dbh->do(q{
CREATE TABLE zero (
    id   INTEGER PRIMARY KEY,
    name VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
});

my $m = DBIx::FixtureLoader->new(
    dbh => $dbh,
);

isa_ok $m, 'DBIx::FixtureLoader';
is $m->_driver_name, 'mysql';

my $result;

$m->load_fixture('t/data/zero.csv');
$result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM zero ORDER BY id;');
is $result->[0], 0;

$m->load_fixture('t/data/zero.csv', update => 1);
$result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM zero ORDER BY id;');
is $result->[0], 0;

done_testing;
