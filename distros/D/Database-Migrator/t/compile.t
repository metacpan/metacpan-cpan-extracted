## no critic (Moose::RequireMakeImmutable)
use strict;
use warnings;

use Test::Fatal;
use Test::More;

{
    package Test::Migrator;

    use Moose;
    use namespace::autoclean;

    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    sub _create_database { }
    sub _driver_name     {'Foo'}
    sub _drop_database   { }
    sub _run_ddl         { }

    ::is(
        ::exception { with 'Database::Migrator::Core' },
        undef,
        'no exception consuming Database::Migrator::Core role'
    );
}

done_testing();
