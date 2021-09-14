use strict;
use warnings;

use Test::More;
use Test::MockModule;
use Log::Any::Test;
use Log::Any qw($log);
use File::Temp;
use Path::Tiny;

use Database::Async::Engine::PostgreSQL;

subtest 'password supplied by uri' => sub {
    my $eng = Database::Async::Engine::PostgreSQL->new(
        uri=>'postgresql://user:PW@localhost'
    );

    local $ENV{PGPASSWORD} = 'hugo';

    is($eng->database_password, 'PW', 'uri wins over PGPASSWORD');
    done_testing;
};

subtest 'password supplied by PGPASSWORD' => sub {
    my $eng = Database::Async::Engine::PostgreSQL->new(
        uri=>'postgresql://user@localhost'
    );

    local $ENV{PGPASSWORD} = 'hugo';

    my $fh = File::Temp->new;
    local $ENV{PGPASSFILE} = $fh->filename;
    path($fh->filename)->spew_utf8([
        "*:*:*:*:pgpass"
    ]);

    is($eng->database_password, 'hugo', 'PGPASSWORD wins over .pgpass');
    done_testing;
};

subtest 'PGPASSFILE' => sub {
    my $eng = Database::Async::Engine::PostgreSQL->new(
        uri=>'postgresql://user@localhost'
    );

    local $ENV{PGPASSWORD} = '';

    my $fh = File::Temp->new;
    local $ENV{PGPASSFILE} = $fh->filename;
    path($fh->filename)->spew_utf8([
        "*:*:*:*:pgpass\n"
    ]);

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $module = Test::MockModule->new('File::HomeDir');
    $module->redefine(my_home => sub {
        $dir
    });
    path($dir.'/.pgpass')->spew_utf8([
        "*:*:*:*:home\n"
    ]);

    unless ($^O eq 'MSWin32') {
        $log->clear;
        $eng->database_password;
        $log->contains_ok(qr/permissions should be u=rw \(0600\) or less/, 'permission warning');
        chmod 0600, $fh->filename;
    }
    is($eng->database_password, 'pgpass', 'PGPASSFILE wins over ~/.pgpass');
    done_testing;
};

subtest 'parsing' => sub {
    my $eng = Database::Async::Engine::PostgreSQL->new(
        uri=>'postgresql://USER@HOST:9876/DB'
    );

    local $ENV{PGPASSWORD} = '';
    local $ENV{PGPASSFILE} = '';

    my $dir = File::Temp::tempdir(CLEANUP => 1);
    my $module = Test::MockModule->new('File::HomeDir');
    $module->redefine(my_home => sub {
        $dir
    });
    path($dir.'/.pgpass')->spew_utf8([
        "*:*:*:*:val\\id:\n"
    ]);
    chmod 0600, $dir.'/.pgpass' unless $^O eq 'MSWin32';
    is($eng->database_password, 'valid', 'backslash');

    for (my $i=1; $i<16; $i++) {
        path($dir.'/.pgpass')->spew_utf8([
            join(':', ($i & 8 ? 'HOST' : '*',
                       $i & 4 ? '9876' : '*',
                       $i & 2 ? 'DB'   : '*',
                       $i & 1 ? 'USER' : '*',
                       "valid\n")),
            "HOST:9876:DB:USER:invalid\n",
            "*:*:*:*:invalid\n",
        ]);
        chmod 0600, $dir.'/.pgpass' unless $^O eq 'MSWin32';
        is($eng->database_password, 'valid', "first match $i wins");
    }
    done_testing;
};

done_testing;
