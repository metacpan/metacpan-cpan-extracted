use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

DBIx::QueryLog->compact(1);

my $dbh = t::Util->new_dbh;
my $res = capture {
my $stmt = << "SQL";
    SELECT  /* comment */     * , name ,
type  FROM \n   sqlite_master WHERE (\t type = ? AND   \n  name = ?  \r   )
OR   name = ? AND ( name <> ? ) AND
      type &

    ? AND name = "hoge '  ' "
SQL
    $dbh->do($stmt, undef, 'a b "c"', 'd ef', "fu '  ga1", 'a', 'b');
};

note $res;
my $expects = quotemeta join ' ',
    q|SELECT /* comment */ *, name, type FROM sqlite_master|,
    q|WHERE (type = 'a b "c"' AND name = 'd ef')|,
    q|OR name = 'fu ''  ga1'|,
    q|AND (name <> 'a')|,
    q|AND type & 'b'|,
    q|AND name = "hoge '  ' "|,
;

like $res, qr/$expects/, 'sql ok';

if (eval { require Test::mysqld; 1 }) {
    DBIx::QueryLog->end;
    if (my $mysqld = t::Util->setup_mysqld) {
        my $dbh = DBI->connect(
            $mysqld->dsn(dbname => 'mysql'), '', '',
            {
                AutoCommit => 1,
                RaiseError => 1,
            },
        ) or die $DBI::errstr;
        $dbh->do(<< 'SQL');
CREATE TABLE `___test` (
    `f  oo` int(10)
)
SQL

        DBIx::QueryLog->begin;
        my $stmt = 'SELECT `f  oo` FROM ___test';
        my $ret = capture {
            $dbh->do($stmt);
        };
        like $ret, qr/$stmt/;
    }
}

done_testing;
