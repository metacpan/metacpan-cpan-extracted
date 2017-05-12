use strict;
use warnings;
use Test::Requires qw(DBD::mysql Test::mysqld);
use Test::More;
use t::Util;

use DBI;
use DBIx::AssertIndex;

my($mysqld, $dbh) = t::Util::setup_mysqld;

my $res = t::Util::capture {
    $dbh->do('SET NAMES utf8');

    $dbh->do(<<'END;');
CREATE TABLE `test` (
  `id` smallint(5) unsigned NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
END;

    my $sth = $dbh->prepare('show tables');
    $sth->execute();

    $dbh->do('INSERT INTO test SET NAME=?', undef, 'foo');
    $dbh->do('INSERT INTO test SET NAME=?', undef, 'bar');
};
is($res, undef);

done_testing;
