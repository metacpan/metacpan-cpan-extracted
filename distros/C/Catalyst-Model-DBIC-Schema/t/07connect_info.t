use strict;
use warnings;

use FindBin '$Bin';
use lib "$Bin/lib";

use Test::More;
use Test::Exception;
use Catalyst::Model::DBIC::Schema;
use ASchemaClass;

# execise the connect_info coercion

my $coderef = sub {};

my @tests = (
    ['dbi:SQLite:foo.db', '', ''],
    { dsn => 'dbi:SQLite:foo.db', user => '', password => '' },

    ['dbi:SQLite:foo.db', ''],
    { dsn => 'dbi:SQLite:foo.db', user => '', password => '' },

    ['dbi:SQLite:foo.db'],
    { dsn => 'dbi:SQLite:foo.db', user => '', password => '' },

    'dbi:SQLite:foo.db',
    { dsn => 'dbi:SQLite:foo.db', user => '', password => '' },

    ['dbi:Pg:dbname=foo', 'user', 'pass',
        { pg_enable_utf8 => 1, auto_savepoint => 1 }],
    { dsn => 'dbi:Pg:dbname=foo', user => 'user', password => 'pass',
        pg_enable_utf8 => 1, auto_savepoint => 1 },

    ['dbi:Pg:dbname=foo', 'user', 'pass',
        { pg_enable_utf8 => 1 }, { auto_savepoint => 1 }],
    { dsn => 'dbi:Pg:dbname=foo', user => 'user', password => 'pass',
        pg_enable_utf8 => 1, auto_savepoint => 1 },

    [ { dsn => 'dbi:Pg:dbname=foo', user => 'user', password => 'pass',
        pg_enable_utf8 => 1, auto_savepoint => 1 } ],
    { dsn => 'dbi:Pg:dbname=foo', user => 'user', password => 'pass',
        pg_enable_utf8 => 1, auto_savepoint => 1 },

    [$coderef, { pg_enable_utf8 => 1, auto_savepoint => 1 }],
    { dbh_maker => $coderef, pg_enable_utf8 => 1, auto_savepoint => 1 },
);

my @invalid = (
    { foo => 'bar' },
    [ { foo => 'bar' } ],
    ['dbi:Pg:dbname=foo', 'user', 'pass',
        { pg_enable_utf8 => 1 }, { AutoCommit => 1 }, { auto_savepoint => 1 }],
);

# ignore redefined warnings, and uninitialized warnings from old
# ::Storage::DBI::Replicated
local $SIG{__WARN__} = sub {
    $_[0] !~ /(?:redefined|uninitialized)/i && warn @_
};

for (my $i = 0; $i < @tests; $i += 2) {
    my $m = instance(
        connect_info => $tests[$i]
    );

    is_deeply $m->connect_info, $tests[$i+1],
        'connect_info coerced correctly';
}

throws_ok { instance(connect_info => $_) } qr/valid connect_info/i,
    'invalid connect_info throws exception'
    for @invalid;

# try as ConnectInfos (e.g.: replicants)
my @replicants = map $tests[$_], grep $_ % 2 == 0, 0..$#tests;

{
    package TryConnectInfos;

    use Moose;
    use Catalyst::Model::DBIC::Schema::Types 'ConnectInfos';

    has replicants => (is => 'ro', isa => ConnectInfos, coerce => 1);
}

my $m = TryConnectInfos->new(
    replicants   => \@replicants
);

lives_and {
    is_deeply(TryConnectInfos->new(replicants => $tests[1])->replicants,
        [ $tests[1] ])
} 'single replicant hashref coerces correctly';

is_deeply $m->replicants, [
    map $tests[$_], grep $_ % 2, 0 .. $#tests
], 'replicant connect_infos coerced correctly';

{
    ASchemaClass->connection( @{$tests[0]} );
    my $m = instance();

    is_deeply $m->connect_info, $tests[1],
        'connect_info coerced correctly when defining connection in the schema class';
}

done_testing;

sub instance {
    Catalyst::Model::DBIC::Schema->new({
        schema_class => 'ASchemaClass',
        @_
    })
}
