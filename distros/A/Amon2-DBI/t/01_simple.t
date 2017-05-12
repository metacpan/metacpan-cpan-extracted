use strict;
use warnings;
use Test::More;
use Amon2::DBI;
use Test::Requires 'DBD::SQLite';

eval {
    Amon2::DBI->connect('dbi:unknown:', '', '');
};
ok $@, "dies with unknown driver, automatically.";

my $dbh = Amon2::DBI->connect('dbi:SQLite::memory:', '', '');
$dbh->do(q{CREATE TABLE foo (e)});
$dbh->insert('foo', {e => 3});
$dbh->do_i('INSERT INTO foo ', {e => 4});
is join(',', map { @$_ } @{$dbh->selectall_arrayref('SELECT * FROM foo ORDER BY e')}), '3,4';

subtest 'utf8' => sub {
    use utf8;
    $dbh->do(q{CREATE TABLE bar (x)});
    $dbh->insert(bar => { x => "こんにちは" });
    my ($x) = $dbh->selectrow_array(q{SELECT x FROM bar});
    is $x, "こんにちは";
};

eval {
    $dbh->insert('bar', {e => 3});
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/failed/;

$dbh->disconnect();
ok !$dbh->ping, 'disconnected';

is $dbh->connect_info->[0], 'dbi:SQLite::memory:';

done_testing;
