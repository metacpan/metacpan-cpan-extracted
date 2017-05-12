use strict;
use Test::More;

use AnyEvent;
use AnyEvent::InMemoryCache;

my $end_cv = AE::cv;

my $cache = AnyEvent::InMemoryCache->new;

ok !$cache->exists("foo");
is $cache->set(foo => "hoge"), "hoge";  # Unlimited
ok $cache->exists("foo");
is $cache->get("foo"), "hoge";

ok !$cache->exists("bar");
is $cache->set(bar => "fuga", "2s"), "fuga";  # lives for 2 seconds
ok $cache->exists("bar");
is $cache->get("bar"), "fuga";

ok !$cache->exists("baz");
is $cache->set(baz => "piyo", "4 seconds"), "piyo";  # lives for 4 seconds
ok $cache->exists("baz");
is $cache->get("baz"), "piyo";

my $w1; $w1 = AE::timer 3, 0, sub{  # 3 sendos later
    ok $cache->exists("foo");
    is $cache->get("foo"), "hoge";
    
    ok !$cache->exists("bar");
    
    ok $cache->exists("baz");
    is $cache->get("baz"), "piyo";
};

my $w2; $w2 = AE::timer 5, 0, sub{  # 5 sendos later
    ok $cache->exists("foo");
    is $cache->get("foo"), "hoge";
    
    ok !$cache->exists("bar");
    ok !$cache->exists("baz");
    
    is $cache->delete("foo"), "hoge";
    ok !$cache->exists("foo");
    
    $end_cv->send;
};

$end_cv->recv;
done_testing;
