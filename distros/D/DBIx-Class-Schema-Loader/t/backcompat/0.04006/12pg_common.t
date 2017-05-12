use DBIx::Class::Schema::Loader::Optional::Dependencies
    -skip_all_without => qw(test_backcompat test_rdbms_pg);

use strict;
use warnings;
use lib qw(t/backcompat/0.04006/lib);
use dbixcsl_common_tests;
use Test::More;


my $dsn      = $ENV{DBICTEST_PG_DSN} || '';
my $user     = $ENV{DBICTEST_PG_USER} || '';
my $password = $ENV{DBICTEST_PG_PASS} || '';

dbixcsl_common_tests->new(
    vendor      => 'Pg',
    auto_inc_pk => 'SERIAL NOT NULL PRIMARY KEY',
    dsn         => $dsn,
    user        => $user,
    password    => $password,
)->run_tests();

