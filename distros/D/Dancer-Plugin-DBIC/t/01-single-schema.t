use Test::More tests => 4;

use lib 't/lib';
use Dancer qw(:syntax :tests);
use Dancer::Plugin::DBIC;
use Test::Exception;

eval { require DBD::SQLite };
plan skip_all => 'DBD::SQLite required to run these tests' if $@;

set plugins => {
    DBIC => {
        foo => {
            schema_class => 'Foo',
            dsn =>  'dbi:SQLite:dbname=:memory:',
        },
    }
};

schema->deploy;
ok rset('User')->create({ name => 'bob', age => 2 });

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
    throws_ok { schema('bar')->resultset('User')->find('bob') }
        qr/schema bar is not configured/, 'missing schema error thrown';
};
