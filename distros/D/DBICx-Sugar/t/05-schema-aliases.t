use Test::Modern;

use DBICx::Sugar qw(config rset schema);
use Test::Requires qw(DBD::SQLite);

plan tests => 5;

config({
    default => {
        schema_class => 'Foo',
        dsn          =>  'dbi:SQLite:dbname=:memory:',
    },
    foo => {
        alias => 'default',
    },
    badalias => {
        alias => 'zzz',
    },
});

schema->deploy;
ok rset('User')->create({ name => 'bob', age => 30 });

subtest 'default schema' => sub {
    ok my $user = rset('User')->find('bob'), 'found bob';
    is $user->age => '30', 'bob is getting old';
};

subtest 'schema alias' => sub {
    ok my $user = schema('foo')->resultset('User')->find('bob'), 'found bob';
    is $user->age => '30', 'bob is still old';
};

subtest 'bad alias' => sub {
    like exception { schema('badalias')->resultset('User')->find('bob') },
        qr/schema alias zzz does not exist in the config/,
        'got bad alias error';
};
