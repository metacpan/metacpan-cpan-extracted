use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;
use Term::ANSIColor qw(colored);

DBIx::QueryLog->color('green');

my $dbh = t::Util->new_dbh;
my $res = capture {
    $dbh->do('SELECT * FROM sqlite_master');
};

my $expects = quotemeta colored ['green'], 'SELECT * FROM sqlite_master';
like $res, qr/$expects/, 'sql ok';

done_testing;
