use Test::More tests => 27;
use strict;
use warnings;

my $sql_i = 0;

BEGIN {
        use_ok('DBI');
        use_ok('DBomb');
        use_ok('DBomb::Query');
        use_ok('DBomb::Query::Delete');
        use_ok('DBomb::Test::Util',qw(:all));
};

## Connect
my ($dbh,$q, $ix, $delete);
ok($dbh = $DBomb::Test::Util::dbh = DBI->connect(undef,undef,undef,+{RaiseError=>1, PrintError=>1}), 'connect to database');


## Create table FOO;
drop_table('foo');
ok($dbh->do('CREATE TABLE foo ( foo_id INT NOT NULL, name CHAR(30), PRIMARY KEY (foo_id))'), 'create table foo');


## Add data, then delete it.

    ## Add data
    truncate_table('foo');
    populate_foo();
    ok(count_table('foo') == 4, 'verify row count');

    ## delete everyone!
    $delete = new DBomb::Query::Delete->from('foo');
    $delete->delete($dbh);
    ok(count_table('foo') == 0, 'verify delete');

    ## Add two of everybody.
    ok(truncate_table('foo'), 'truncate foo');
    populate_foo();
    populate_foo();
    ok(count_table('foo') == 8, 'verify row count');

    ## delete blythe
    $delete = new DBomb::Query::Delete($dbh)->from('foo')->where(+{'name' => '?'});
    $delete->execute('blythe');
    ok(count_table('foo') == 6, 'verify row count');

    ## reuse the delete object
    $delete->execute('cher');
    ok(count_table('foo') == 4, 'verify row count');

    ## this time delete nobody
    $delete->execute($dbh,'bogus name');
    ok(count_table('foo') == 4, 'verify row count');

ok(drop_table('foo'), 'drop the table');

## Adds a few people to foo
sub populate_foo
{
    my @names = qw(aaron blythe cher deirdre);
    $ix = $dbh->selectcol_arrayref("SELECT COUNT(*) FROM foo")->[0];
    for (@names){
        ok($dbh->do("INSERT INTO foo (foo_id,name) VALUES (?,?)", +{}, $ix++, $_), "insert $_");
    }
}

1;
# vim:set ft=perl ai si et ts=4 sts=4 sw=4 tw=0
