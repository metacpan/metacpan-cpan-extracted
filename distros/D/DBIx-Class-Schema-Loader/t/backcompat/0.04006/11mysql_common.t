use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => qw(test_backcompat test_rdbms_mysql);

use strict;
use warnings;
use lib qw(t/backcompat/0.04006/lib);
use dbixcsl_common_tests;
use Test::More;

my $dsn         = $ENV{DBICTEST_MYSQL_DSN} || '';
my $user        = $ENV{DBICTEST_MYSQL_USER} || '';
my $password    = $ENV{DBICTEST_MYSQL_PASS} || '';
my $test_innodb = $ENV{DBICTEST_MYSQL_INNODB} || 0;

my $skip_rels_msg = 'You need to set the DBICTEST_MYSQL_INNODB environment variable to test relationships';

dbixcsl_common_tests->new(
    vendor           => 'Mysql',
    auto_inc_pk      => 'INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT',
    innodb           => $test_innodb ? q{Engine=InnoDB} : 0,
    dsn              => $dsn,
    user             => $user,
    password         => $password,
    skip_rels        => $test_innodb ? 0 : $skip_rels_msg,
    no_inline_rels   => 1,
    no_implicit_rels => 1,
)->run_tests();
