use strict;
use warnings;
use Test::Requires 'DBD::SQLite';
use Test::More;
use t::Util;
use DBIx::QueryLog;

DBIx::QueryLog->logger(t::Util->new_logger);

my $dbh = t::Util->new_dbh;

my $res = capture_logger {
    $dbh->do('SELECT * FROM sqlite_master');
};

ok exists $res->{time}, 'time is exists';
ok exists $res->{localtime}, 'localtime is exists';
is $res->{line}, 13, 'line ok';
like $res->{file}, qr/30_logger\.t/, 'file ok';
is $res->{pkg}, 'main', 'pkg ok';
is $res->{sql}, 'SELECT * FROM sqlite_master', 'query ok';

done_testing;
