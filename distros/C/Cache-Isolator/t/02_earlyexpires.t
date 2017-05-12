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

    subtest 'basic early_expires' => sub {
        my $isolator = Cache::Isolator->new(
            cache => $cache,
            early_expires_ratio => 2,
            expires_before => 10,
        );

        ok ( $isolator->set('ekey1','value1',12) );
        is ( $isolator->get('ekey1'), 'value1');
        is ( $cache->get('ekey1:earlyexp'), 'value1'); 

        sleep 3;

        is ( $cache->get('ekey1'), 'value1');
        ok ( !$cache->get('ekey1:earlyexp') ); 

        ok ( $isolator->set('ekey2','value2', 20) );
        is ( $isolator->get('ekey2'), 'value2');
        is ( $cache->get('ekey2:earlyexp'), 'value2'); 

        $isolator->delete('ekey2');
        ok ( !$isolator->get('ekey2'));
        ok ( !$cache->get('ekey2:earlyexp')); 
    };
}

done_testing;

