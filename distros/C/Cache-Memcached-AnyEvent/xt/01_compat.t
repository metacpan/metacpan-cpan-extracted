use strict;
use Test::Memcached;
use Test::More;
use AnyEvent;
use constant HAVE_CACHE_MEMCACHED => eval { require Cache::Memcached };

BEGIN {
    if (! HAVE_CACHE_MEMCACHED) {
        plan(skip_all => "Cache::Memcached not available");
    }
}

use_ok "Cache::Memcached::AnyEvent";

my $server = Test::Memcached->new();
$server->start();

my $namespace = join('.', $$, {}, time(), rand() );
my @keys = 'a'..'z';

my $cmemd = Cache::Memcached->new({
    servers => [ "127.0.0.1:" . $server->option('tcp_port') ],
    namespace => $namespace,
});
my $memd = Cache::Memcached::AnyEvent->new({
    servers => [ "127.0.0.1:" . $server->option('tcp_port') ],
    namespace => $namespace,
});
my $cv = AE::cv;
foreach my $key (@keys) {
    $cv->begin;
    $memd->set($key, join('.', $$, {}, time(), rand() ), sub {
        $memd->get( $key, sub {
            my $got = shift;
            ok $got, "Got value from Cache::Memcached::AnyEvent: $got";
            is $got, $cmemd->get( $key ), "value from Cache::Memcached matches Cache::Memcached::AnyEvent";
            $cv->end;
        } );
    } );
}

$cv->recv;
done_testing;