use strict;
use warnings;
use Test::More;
use Amon2::DBI;
use Test::Requires 'DBD::mysql', 'DBI', 'Test::mysqld';

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => ''
    }
) or plan skip_all => $Test::mysqld::errstr;

my $dbh = Amon2::DBI->connect($mysqld->dsn());
$dbh->do(q{CREATE TABLE foo (e int unsigned not null)});
$dbh->insert('foo', {e => 3});
$dbh->do_i('INSERT INTO foo ', {e => 4});
is join(',', map { @$_ } @{$dbh->selectall_arrayref('SELECT * FROM foo ORDER BY e')}), '3,4';

subtest 'utf8' => sub {
    use utf8;
    $dbh->do(q{CREATE TABLE bar (x varchar(255)) DEFAULT CHARACTER SET utf8});
    $dbh->insert(bar => { x => "こんにちは" });
    my ($x) = $dbh->selectrow_array(q{SELECT x FROM bar});
    is $x, "こんにちは";
};

eval {
    $dbh->insert('bar', {e => 3});
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/failed/;

eval {
    my $sth = $dbh->prepare('SELECT * FROM ppp');
    $sth->execute();
}; note $@;
ok $@, "Dies with unknown table name automatically.";
like $@, qr/failed/;
like $@, qr/ppp/;

$dbh->disconnect();
ok !$dbh->ping, 'disconnected';

done_testing;
