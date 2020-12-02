use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/Database/Async.pm',
    'lib/Database/Async.pod',
    'lib/Database/Async/Backoff.pm',
    'lib/Database/Async/Backoff/Exponential.pm',
    'lib/Database/Async/DB.pm',
    'lib/Database/Async/Engine.pm',
    'lib/Database/Async/Engine.pod',
    'lib/Database/Async/Engine/Empty.pm',
    'lib/Database/Async/Engine/Empty.pod',
    'lib/Database/Async/ORM.pm',
    'lib/Database/Async/ORM/Constraint.pm',
    'lib/Database/Async/ORM/Extension.pm',
    'lib/Database/Async/ORM/Field.pm',
    'lib/Database/Async/ORM/Schema.pm',
    'lib/Database/Async/ORM/Table.pm',
    'lib/Database/Async/ORM/Type.pm',
    'lib/Database/Async/Pool.pm',
    'lib/Database/Async/Query.pm',
    'lib/Database/Async/Row.pm',
    'lib/Database/Async/StatementHandle.pm',
    'lib/Database/Async/Test.pm',
    'lib/Database/Async/Transaction.pm',
    'lib/Database/Async/Transaction.pod',
    't/00-check-deps.t',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/new.t',
    't/pool.t',
    'xt/author/distmeta.t',
    'xt/author/minimum-version.t',
    'xt/author/mojibake.t',
    'xt/author/no-tabs.t',
    'xt/author/pod-syntax.t',
    'xt/author/portability.t',
    'xt/author/test-version.t',
    'xt/cpanfile.t',
    'xt/release/common_spelling.t',
    'xt/release/cpan-changes.t'
);

notabs_ok($_) foreach @files;
done_testing;
