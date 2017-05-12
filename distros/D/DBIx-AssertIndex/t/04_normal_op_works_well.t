use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use t::Util;

use DBI;
use DBIx::AssertIndex;

my($mysqld, $dbh) = t::Util::setup_mysqld;

$dbh->do('SET NAMES utf8');

$dbh->do(<<'END;');
CREATE TABLE `test` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END;

# setup
my $sth = $dbh->prepare('INSERT INTO test SET NAME=?');
foreach my $name ('aa'..'zz'){
    $sth->execute($name);
}

my $res;

$res = t::Util::capture {
    my $sth = $dbh->prepare('SELECT COUNT(*) FROM test');
    $sth->execute();
    my($num) = $sth->fetchrow_array;
    is($num, 26*26);
};
is($res, undef, 'select without where');

$res = t::Util::capture {
    my $sth = $dbh->prepare('SELECT COUNT(*) FROM test WHERE id < 100');
    $sth->execute();
    my($num) = $sth->fetchrow_array;
    is($num, 99);
};
is($res, undef, 'select with primary key');

$res = t::Util::capture {
    my $sth = $dbh->prepare(q{SELECT COUNT(*) FROM test WHERE name = 'aa'});
    $sth->execute();
    my($id) = $sth->fetchrow_array;
    is($id, 1);
};
like($res, qr/explain alert/, 'select with no indexed column');

done_testing;
