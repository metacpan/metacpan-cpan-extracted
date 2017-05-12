use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

my $dbh = t::Util->new_dbh;

my $do_with_bind = capture {
    $dbh->do('SELECT * FROM sqlite_master WHERE name = ?', undef, 'foo');
};

like $do_with_bind, qr/SELECT \* FROM sqlite_master WHERE name = 'foo'/, 'do with a bind value';
unlike $do_with_bind, qr/SELECT \* FROM sqlite_master.+SELECT \* FROM sqlite_master/s, 'do with a bind value; no duplicates';

my $do_without_bind = capture {
    $dbh->do('SELECT * FROM sqlite_master');
};

like $do_without_bind, qr/SELECT \* FROM sqlite_master/, 'do without a bind value';
unlike $do_without_bind, qr/SELECT \* FROM sqlite_master.+SELECT \* FROM sqlite_master/s, 'do without a bind value; no duplicates';

my $select = capture {
    $dbh->selectall_arrayref('SELECT * FROM sqlite_master');
};

like $select, qr/SELECT \* FROM sqlite_master/, 'select';
unlike $select, qr/SELECT \* FROM sqlite_master.+SELECT \* FROM sqlite_master/s, 'select; no duplicates';

done_testing;
