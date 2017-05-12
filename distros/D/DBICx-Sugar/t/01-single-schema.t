use Test::Modern;

use DBICx::Sugar qw(config rset resultset schema);
use Test::Requires qw(DBD::SQLite);

plan tests => 5;

config({
    foo => {
        schema_class => 'Foo',
        dsn          => 'dbi:SQLite:dbname=:memory:',
    }
});

schema->deploy;

ok rset('User')->create({ name => 'bob', age => 2 }), 'created young bob';

subtest 'schema' => sub {
    my $user = schema->resultset('User')->find('bob');
    is $user->age => '2', 'bob is a baby';
    $user = schema('foo')->resultset('User')->find('bob');
    is $user->age => '2', 'found Bob via explicit schema name';
};

subtest 'resultset' => sub {
    my $user = resultset('User')->find('bob');
    is $user->age => '2', 'found bob via resultset';
    $user = rset('User')->find('bob');
    is $user->age => '2', 'found bob via rset';
};

subtest 'invalid schema name' => sub {
    like exception { schema('bar')->resultset('User')->find('bob') },
        qr/schema bar is not configured/,
        'missing schema error thrown';
};
