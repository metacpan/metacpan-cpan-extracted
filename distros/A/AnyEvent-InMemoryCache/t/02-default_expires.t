use strict;
use Test::More;

use AnyEvent;
use AnyEvent::InMemoryCache;

my $end_cv = AE::cv;

my $cache = AnyEvent::InMemoryCache->new(expires_in => 2);  # expires in 2 second

ok !$cache->exists("foo");
is $cache->set(foo => "hoge"), "hoge";  # default: 2 second
ok $cache->exists("foo");
is $cache->get("foo"), "hoge";

ok !$cache->exists("bar");
is $cache->set(bar => "fuga"), "fuga";  # lives for 2 second, but overwritten later
ok $cache->exists("bar");
is $cache->get("bar"), "fuga";

ok !$cache->exists("baz");
is $cache->set(baz => "piyo", "3 seconds"), "piyo";  # lives for 3 seconds
ok $cache->exists("baz");
is $cache->get("baz"), "piyo";

my $w0; $w0 = AE::timer 1, 0, sub{  # 1 seconds later
    ok $cache->exists("foo");
    is $cache->get("foo"), "hoge";
    
    ok $cache->exists("bar");
    is $cache->get("bar"), "fuga";
    is $cache->set(bar => "fuga", "3 s"), "fuga", "Extend lifetime!";
    
    ok $cache->exists("baz");
    is $cache->get("baz"), "piyo";
};

my $w1; $w1 = AE::timer 2, 0, sub{  # 2 seconds later
    ok !$cache->exists("foo");
    
    ok $cache->exists("bar");
    is $cache->get("bar"), "fuga";
    
    ok $cache->exists("baz");
    is $cache->get("baz"), "piyo";
};

my $w2; $w2 = AE::timer 4, 0, sub{  # 4 seconds later
    ok !$cache->exists("foo");
    
    ok $cache->exists("bar");
    is $cache->get("bar"), "fuga";
    
    ok !$cache->exists("baz");
};

my $w3; $w3 = AE::timer 5, 0, sub{  # 5 seconds later
    ok !$cache->exists("foo");
    
    ok !$cache->exists("bar");
    
    ok !$cache->exists("baz");
    
    $end_cv->send;
};

$end_cv->recv;
done_testing;
