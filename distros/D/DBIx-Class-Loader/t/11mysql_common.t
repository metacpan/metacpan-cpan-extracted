use strict;
use lib qw( . ./t );
use dbixcl_common_tests;

my $database    = $ENV{MYSQL_NAME} || '';
my $user        = $ENV{MYSQL_USER} || '';
my $password    = $ENV{MYSQL_PASS} || '';
my $test_innodb = $ENV{MYSQL_TEST_INNODB} || 0;

my $skip_rels_msg = 'You need to set the MYSQL_TEST_INNODB environment variable to test relationships';

my $tester = dbixcl_common_tests->new(
    vendor          => 'Mysql',
    auto_inc_pk     => 'INTEGER NOT NULL PRIMARY KEY AUTO_INCREMENT',
    innodb          => $test_innodb ? q{Engine=InnoDB} : 0,
    dsn             => "dbi:mysql:$database",
    user            => $user,
    password        => $password,
    skip_rels       => $test_innodb ? 0 : $skip_rels_msg,
    multi_fk_broken => 1,
);

if( !$database || !$user ) {
    $tester->skip_tests('You need to set the MYSQL_NAME, MYSQL_USER and MYSQL_PASS environment variables');
}
else {
    $tester->run_tests();
}
