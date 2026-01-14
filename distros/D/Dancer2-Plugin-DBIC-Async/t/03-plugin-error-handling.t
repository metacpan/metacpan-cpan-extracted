#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use Plack::Test;
use HTTP::Request::Common;

use lib 't/lib';

my ($olderr, $null);
open $olderr, '>&', \*STDERR or die "Can't dup STDERR: $!";
open STDERR, '>', '/dev/null' or open STDERR, '>', \$null;

subtest 'Missing configuration' => sub {

    {
        package TestApp1;
        use Dancer2;
        use lib 't/lib';

        use Dancer2::Plugin::DBIC::Async;

        get '/test' => sub {
            my $count = async_count('User');
            return $count->get;
        };
    }

    my $app = Plack::Test->create(TestApp1->to_app);
    my $res = $app->request(GET '/test');

    ok(!$res->is_success, 'Request fails without configuration');
    like($res->content, qr/Error 500|No configuration/, 'Error message mentions configuration');

};

subtest 'Missing schema_class' => sub {

    my $dir = tempdir(CLEANUP => 1);
    my $db_file = catfile($dir, 'test.db');

    {
        package TestApp2;
        use Dancer2;
        use lib 't/lib';

        set(
            plugins => {
                'DBIC::Async' => {
                    default => {
                        # Missing schema_class
                        dsn      => "dbi:SQLite:dbname=$db_file",
                        user     => '',
                        password => '',
                    },
                },
            }
        );

        use Dancer2::Plugin::DBIC::Async;

        get '/test' => sub {
            my $count = async_count('User');
            return $count->get;
        };
    }

    my $app = Plack::Test->create(TestApp2->to_app);
    my $res = $app->request(GET '/test');

    ok(!$res->is_success, 'Request fails without schema_class');
    like($res->content, qr/Error 500|schema_class/, 'Error message mentions schema_class');
};

subtest 'Missing DSN' => sub {

    {
        package TestApp3;
        use Dancer2;
        use lib 't/lib';

        set(
            plugins => {
                'DBIC::Async' => {
                    default => {
                        schema_class => 'Test::Schema',
                        # Missing dsn
                        user     => '',
                        password => '',
                    },
                },
            }
        );

        use Dancer2::Plugin::DBIC::Async;

        get '/test' => sub {
            my $count = async_count('User');
            return $count->get;
        };
    }

    my $app = Plack::Test->create(TestApp3->to_app);
    my $res = $app->request(GET '/test');

    ok(!$res->is_success, 'Request fails without DSN');
    like($res->content, qr/Error 500|dsn/, 'Error message mentions DSN');
};

subtest 'Invalid connection name' => sub {

    my $dir     = tempdir(CLEANUP => 1);
    my $db_file = catfile($dir, 'test.db');

    {
        package TestApp4;
        use Dancer2;
        use lib 't/lib';

        set(
            plugins => {
                'DBIC::Async' => {
                    default => {
                        schema_class => 'Test::Schema',
                        dsn          => "dbi:SQLite:dbname=$db_file",
                        user         => '',
                        password     => '',
                        async        => { workers => 2 },
                    },
                },
            }
        );

        use Dancer2::Plugin::DBIC::Async;

        get '/test' => sub {
            # Try to use non-existent connection
            my $count = async_count('User', 'nonexistent');
            return $count->get;
        };
    }

    my $app = Plack::Test->create(TestApp4->to_app);
    my $res = $app->request(GET '/test');

    ok(!$res->is_success, 'Request fails with invalid connection name');
    like($res->content, qr/Error 500|No configuration.*nonexistent/, 'Error message mentions missing connection');
};

done_testing();
