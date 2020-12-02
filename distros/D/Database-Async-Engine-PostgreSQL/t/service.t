use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Test::Fatal;
use Test::Deep;
use File::Temp;
use Path::Tiny;

use Database::Async::Engine::PostgreSQL;

subtest 'pg_service.conf location' => sub {
    my $class = 'Database::Async::Engine::PostgreSQL';
    delete local $ENV{PGSERVICEFILE};
    delete local $ENV{PGSYSCONFDIR};
    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $module = Test::MockModule->new('File::HomeDir');
    $module->redefine(my_home => sub {
        $dir
    });
    is($class->service_conf_path, '/etc/pg_service.conf', 'fallback with no local config');
    path($dir)->child('.pg_service.conf')->spew_utf8("[example]\n");
    is($class->service_conf_path, $dir . '/.pg_service.conf', 'finds home config when it exists');
    $ENV{PGSYSCONFDIR} = $dir;
    is($class->service_conf_path, $dir . '/pg_service.conf', 'finds PGSYSCONFDIR when set, even if it does not exist');
    path($dir)->child('pg_service.conf')->spew_utf8("[example]\n");
    is($class->service_conf_path, $dir . '/pg_service.conf', 'still finds PGSYSCONFDIR when set when it does exist');
    $ENV{PGSERVICEFILE} = '/random/path';
    is($class->service_conf_path, '/random/path', 'uses PGSERVICEFILE when found');
    done_testing;
};

subtest 'pg_service.conf parsing' => sub {
    my $class = 'Database::Async::Engine::PostgreSQL';
    my $fh = File::Temp->new;
    local $ENV{PGSERVICEFILE} = $fh->filename;
    path($fh->filename)->spew_utf8([
        map { "$_\n" }
            '[example]',
            'host=1.2.3.4',
    ]);
    like(exception {
        $class->find_service('missing')
    }, qr/not found/, 'raise exception when asking for service that does not exist');
    cmp_deeply($class->find_service('example'), { host => '1.2.3.4' }, 'can read service config');
    path($fh->filename)->spew_utf8([
        map { "$_\n" }
            '[example]',
            'host=1.2.3.5',
            'port=5434',
            'user=some_user',
            'dbname=some_database',
            'sslmode=prefer',
    ]);
    cmp_deeply(
        $class->find_service('example'),
        {
            host    => '1.2.3.5',
            port    => 5434,
            user    => 'some_user',
            dbname  => 'some_database',
            sslmode => 'prefer',
        },
        'new service config is picked up after changing the file'
    );
    done_testing;
};
done_testing;


