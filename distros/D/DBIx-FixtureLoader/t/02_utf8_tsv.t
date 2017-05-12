use strict;
use warnings;
use utf8;
use Test::More;
use Test::Requires {
    'DBD::SQLite' => 1.27,
    'Text::CSV'   => 1.31,
};
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

my $_column_width = 16;
note 'DBD::SQLite';
note sprintf(" %-${_column_width}s : %s", 'VERSION', $DBD::SQLite::VERSION);
note 'Text::CSV';
note sprintf(" %-${_column_width}s : %s", 'VERSION', Text::CSV->VERSION);
note sprintf(" %-${_column_width}s : %s", 'Backend', Text::CSV->module);
note sprintf(" %-${_column_width}s : %s", 'Backend::VERSION', Text::CSV->version);

my $dbh = DBI->connect("dbi:SQLite::memory:", '', '', {RaiseError => 1, sqlite_unicode => 1}) or die 'cannot connect to db';
$dbh->do(q{
    CREATE TABLE item (
        id   INTEGER PRIMARY KEY,
        name VARCHAR(255)
    );
});

my $m = DBIx::FixtureLoader->new(
    dbh => $dbh,
);
isa_ok $m, 'DBIx::FixtureLoader';
is $m->_driver_name, 'SQLite';
ok !$m->bulk_insert;

$m->load_fixture('t/data/item.tsv');

my $result = $dbh->selectrow_arrayref('SELECT COUNT(*) FROM item ORDER BY id;');
is $result->[0], 2;

my $rows = $dbh->selectall_arrayref('SELECT * FROM item ORDER BY id;', {Slice => {}});
is scalar @$rows, 2;
is $rows->[0]{name}, 'エクスカリバー';

done_testing;
