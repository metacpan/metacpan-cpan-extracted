use strict;
use warnings;
use Test::More;
use Amon2::DBI;
use Test::Requires 'DBD::Pg', 'DBI', 'Test::postgresql';

my $pg = eval { Test::postgresql->new(
    initdb_args => $Test::postgresql::Defaults{initdb_args} . ' -E UTF8',
) } or plan skip_all => $Test::postgresql::errstr;

my $dbh = Amon2::DBI->connect($pg->dsn);
$dbh->do(q{CREATE TABLE foo (e int not null)});
$dbh->insert('foo', {e => 3});
$dbh->do_i('INSERT INTO foo ', {e => 4});
is join(',', map { @$_ } @{$dbh->selectall_arrayref('SELECT * FROM foo ORDER BY e')}), '3,4';

subtest 'utf8' => sub {
    use utf8;
    $dbh->do(q{CREATE TABLE bar (x varchar(255))});
    $dbh->insert(bar => { x => "こんにちは" });
    my ($x) = $dbh->selectrow_array(q{SELECT x FROM bar});
    is $x, "こんにちは";
};

eval {
    $dbh->insert('bar', {e => 3});
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/Amon2::DBI 's Exception/;

eval {
    my $sth = $dbh->prepare('SELECT * FROM ppp');
    $sth->execute();
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/Amon2::DBI 's Exception/;
like $@, qr/ppp/;

$dbh->disconnect();
ok !$dbh->ping, 'disconnected';

done_testing;
