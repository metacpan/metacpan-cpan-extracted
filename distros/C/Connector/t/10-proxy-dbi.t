# Tests for Connector::Builtin::File::Simple
#

use strict;
use warnings;
use English;
use DBI;
use Log::Log4perl qw(:easy);
use File::Temp qw/ :POSIX /;

use Test::More tests => 22;

eval {
    require DBD::SQLite;
};
if ($EVAL_ERROR) {
    plan skip_all => 'DBD::SQLite is required for tests';
}

Log::Log4perl->easy_init($ERROR);

BEGIN {
    use_ok( 'Connector::Proxy::DBI' );
}

require_ok( 'Connector::Proxy::DBI' );

my $dbfile = tmpnam();

my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", {AutoCommit => 1, RaiseError => 1});
my $sth = $dbh->prepare("CREATE table test( id int, name text ); commit;");
$sth->execute();

$sth = $dbh->prepare("INSERT INTO test (id,name) VALUES (1,'test me'),(2,'test me too')");
$sth->execute();

# diag "Connector::Proxy::File::Simple tests\n";
###########################################################################
my $conn = Connector::Proxy::DBI->new(
    {
    LOCATION  => "dbi:SQLite:dbname=$dbfile",
    table => 'test',
    column => 'name',
    condition => 'id = ?',
    });

is($conn->get(1), 'test me');
is($conn->get(2), 'test me too');

$conn->column('id');
$conn->condition('name like ?');

is($conn->get_size('%test%'), 2);

is($conn->get_size('test me'), 1);
my @res = $conn->get_list('test me');
is(scalar @res, 1);
is($res[0], 1);

$conn->condition('id = ?');
$conn->column('');

my $res = $conn->get_hash(1);

is ($res->{id}, 1);
is ($res->{name}, 'test me');

$conn->column({ 'id' => 'id', '`index`' => 'id', 'title' => 'name' });
$res = $conn->get_hash(1);

is ($res->{id}, 1);
is ($res->{index}, 1);
is ($res->{title}, 'test me');
is ($res->{name}, undef);

$conn = Connector::Proxy::DBI->new(
    {
    LOCATION  => "dbi:SQLite:dbname=$dbfile",
    table => 'test',
    column => 'name',
    condition => 'name like ?',
});

$res = $conn->get('%test%');
ok(!$res);

$conn->ambiguous('return');

$res = $conn->get('%test%');
ok($res);

$conn->ambiguous('die');
eval { $res = $conn->get('%test%');};
ok($EVAL_ERROR);

$conn = Connector::Proxy::DBI->new(
    {
    LOCATION  => "dbi:SQLite:dbname=$dbfile",
    table => 'test',
    condition => 'id = ?',
});

$res = $conn->get_hash('%test%');
ok(!$res);

$conn->ambiguous('return');

$res = $conn->get_hash(1);
is($res->{id}, 1);
is($res->{name}, 'test me');

$conn->condition('name like ?');

$res = $conn->get_hash('%test%');
ok($res->{id});

$conn->ambiguous('die');
eval { $res = $conn->get_hash('%test%');};
ok($EVAL_ERROR);

unlink($dbfile);
