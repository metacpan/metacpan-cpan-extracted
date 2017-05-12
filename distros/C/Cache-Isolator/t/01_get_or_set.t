use strict;
use Test::More;

use Test::TCP qw(test_tcp empty_port wait_port);
use Test::SharedFork;
use Test::Skip::UnlessExistsExecutable;

use Cache::Memcached::Fast;
use File::Which qw(which);
use Proc::Guard;

use Cache::Isolator;

skip_all_unless_exists 'memcached';

sub run_memcached_server {
    my $port = shift;
    my @memcached = (scalar which('memcached'), '-p', $port, '-U', 0);
    push @memcached, '-u', 'nobody' if $> == 0; #root
    my $proc = proc_guard( @memcached );
    wait_port($port);
    return $proc;
}

sub create_memcached_client {
    my $port = shift;
    return Cache::Memcached::Fast->new(
        +{ servers => [ 'localhost:' . $port ] } );
}

{
    my $port  = empty_port;
    my $proc  = run_memcached_server($port);
    my $cache = create_memcached_client($port);

    subtest 'basic get_or_set' => sub {
        my $isolator = Cache::Isolator->new(
            cache => $cache
        );
        my $ret =  $isolator->get_or_set('key1',sub{
                                  return "value1"
                              },100);
        is( $ret, "value1");
        is( $cache->get('key1'), 'value1');
    };

    subtest 'multi get_or_set' => sub {
        $cache->set('key2-i',1,100);
        my @pids;
        for ( 1..10 ) {
            my $pid = fork();
            if ( $pid == 0 ) {
                my $cache = create_memcached_client($port);
                my $isolator = Cache::Isolator->new(
                    cache => $cache,
                );
                my $ret =  $isolator->get_or_set('key2',sub{
                    sleep 1;
                    $cache->incr('key2-i');
                },100);
                is( $ret, 2);
                exit;
            }
            elsif ( $pid ) {
                push @pids, $pid;
            }
        }

        waitpid( $_, 0) for @pids;
        is( $cache->get('key2'), 2);
        is( $cache->get('key2-i'), 2);
    };

    subtest 'parallel get_or_set' => sub {
        $cache->set('key3-i',1,100);
        my @pids;
        for ( 1..10 ) {
            my $pid = fork();
            if ( $pid == 0 ) {
                my $cache = create_memcached_client($port);
                my $isolator = Cache::Isolator->new(
                    cache => $cache,
                    concurrency => 3
                );
                my $ret =  $isolator->get_or_set('key3',sub{
                    my $incr = $cache->incr('key3-i');
                    sleep 5;
                    $incr;
                },100);
                ok( $ret );
                exit;
            }
            elsif ( $pid ) {
                push @pids, $pid;
            }
        }
        waitpid( $_, 0) for @pids;
        ok( $cache->get('key3') > 0 && $cache->get('key3') <= 4 );
        is( $cache->get('key3-i'), 4);
    };


    subtest 'get_or_set timeout' => sub {
        my @pids;
        my $pid = fork();
        if ( $pid == 0 ) {
            my $cache = create_memcached_client($port);
            my $isolator = Cache::Isolator->new(
                cache => $cache,
                timeout => 5,
            );
            my $ret =  $isolator->get_or_set('key4',sub{
                sleep 10;
                "child"
            },100);
            exit;
        }
        sleep 1;
        
        my $isolator = Cache::Isolator->new(
            cache => $cache,
            timeout => 10,
        );
        my $ret =  $isolator->get_or_set('key4',sub{
            ok( !$cache->get('key4') );
            "parent";
        },100);
        ok( $ret, "parent");

        waitpid( $pid, 0);

        ok( $cache->get('key4'), 'child' );
    };

    subtest 'get_or_set trial' => sub {
        my @pids;
        my $pid = fork();
        if ( $pid == 0 ) {
            my $cache = create_memcached_client($port);
            my $isolator = Cache::Isolator->new(
                cache => $cache,
            );
            my $ret =  $isolator->get_or_set('key5',sub{
                sleep 5;
                "child"
            },100);
            exit;
        }
        sleep 1;

        my $isolator = Cache::Isolator->new(
            cache => $cache,
            trial => 3,
        );
        eval {
            my $ret =  $isolator->get_or_set('key5',sub{
                "parent";
            },100);
        };
        like( $@, qr/reached max trial count/);

        waitpid( $pid, 0);
        ok( $cache->get('key5'), 'child' );
    };
}


done_testing;

