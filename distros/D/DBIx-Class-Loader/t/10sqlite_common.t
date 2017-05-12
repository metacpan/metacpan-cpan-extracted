use strict;
use lib qw( ./t );
use dbixcl_common_tests;

eval { require DBD::SQLite };
my $class = $@ ? 'SQLite2' : 'SQLite';

{
    my $tester = dbixcl_common_tests->new(
        vendor          => 'SQLite',
        auto_inc_pk     => 'INTEGER NOT NULL PRIMARY KEY',
        dsn             => "dbi:$class:dbname=./t/sqlite_test",
        user            => '',
        password        => '',
        multi_fk_broken => 1,
    );

    $tester->run_tests();
}

END {
    unlink './t/sqlite_test';
}
