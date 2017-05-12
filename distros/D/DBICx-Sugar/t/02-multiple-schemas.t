use Test::Modern;

use DBICx::Sugar qw(config rset resultset schema);
use File::Temp qw(tempfile);
use Test::Requires qw(DBD::SQLite);

plan tests => 3;

my @dbfiles = map { (tempfile SUFFIX => '.db' )[1] } 1..2;

subtest 'two schemas' => sub {
    config({
        foo => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfiles[0]",
        },
        bar => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfiles[1]",
        },
    });

    schema('foo')->deploy;
    ok schema('foo')->resultset('User')->create({ name => 'bob', age => 30 });
    schema('bar')->deploy;
    ok schema('bar')->resultset('User')->create({ name => 'sue', age => 20 });

    my $user = schema('foo')->resultset('User')->find('bob');
    ok $user, 'found bob';
    is $user->age => '30', 'bob is getting old';

    $user = schema('bar')->resultset('User')->find('sue');
    ok $user, 'found sue';
    is $user->age => '20', 'sue is the right age';

    like exception { schema('poo')->resultset('User')->find('bob') },
        qr/schema poo is not configured/, 'Missing schema error thrown';

    like exception { schema->resultset('User')->find('bob') },
        qr/The schema default is not configured/,
        'Missing default schema error thrown';
};

subtest 'two schemas with a default schema' => sub {
    config({
        default => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfiles[0]",
        },
        bar => {
            schema_class => 'Foo',
            dsn =>  "dbi:SQLite:dbname=$dbfiles[1]",
        },
    });

    ok my $bob = schema->resultset('User')->find('bob'), 'found bob';
    is $bob->age => 30;
};

unlink @dbfiles;
