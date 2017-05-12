use strict;
use warnings;

use Test::Fatal;
use Test::More;
use lib 't/lib';

BEGIN {
    $ENV{DANCER_ENVIRONMENT} = 'json';

    eval 'use Dancer2::Session::DBIC';
    plan skip_all => "Dancer2::Session::DBIC required to run these tests" if $@;

    eval 'use DBIx::Class';
    plan skip_all => "DBIx::Class required to run these tests" if $@;

    eval 'use DBD::SQLite';
    plan skip_all => "DBD::SQLite required to run these tests" if $@;

    eval 'use DBICx::Sugar';
    plan skip_all => "DBICx::Sugar required to run these tests" if $@;

    require DBIx::Class::Optional::Dependencies;
    my $deps = DBIx::Class::Optional::Dependencies->req_list_for('deploy');
    for (keys %$deps) {
        eval "use $_ $deps->{$_}";
        plan skip_all => "$_ >= $deps->{$_} required to run these tests" if $@;
    }
}

BEGIN {
    use DBICx::Sugar qw(schema);

    DBICx::Sugar::config(
        {
            default => {
                dsn          => "dbi:SQLite:dbname=:memory:",
                schema_class => "TestApp::Schema"
            }
        }
    );

    is exception { schema->deploy }, undef, "Deploy DBIC schema lives";
}

diag "Dancer2::Session::DBIC $Dancer2::Session::DBIC::VERSION";

use Tests;
Tests::run_tests();

done_testing;
