use strict;
use Test::More;

use AnyEvent;
use AnyEvent::InMemoryCache;

my $end_cv = AE::cv;

tie my %cache, 'AnyEvent::InMemoryCache', expires_in => 1;  # expires in 1 second

is scalar keys %cache, 0;
is "" . %cache, "0";
ok !%cache;

ok !exists $cache{"foo"};
is(($cache{"foo"} = "hoge"), "hoge");  # lives for 1 second
ok exists $cache{"foo"};
is $cache{"foo"}, "hoge";

is scalar keys %cache, 1;
is_deeply [sort keys %cache], [qw(foo)];
ok scalar %cache;

ok !exists $cache{"bar"};
is(($cache{"bar"} = "fuga"), "fuga");  # lives 1 second, but extend lifetime later
ok exists $cache{"bar"};
is $cache{"bar"}, "fuga";

is scalar keys %cache, 2;
is_deeply [sort keys %cache], [qw(bar foo)];
ok scalar %cache;

ok !exists $cache{"baz"};
is(($cache{"baz"} = "piyo"), "piyo");  # lives 1 second, will be deleted soon
ok exists $cache{"baz"};
is $cache{"foo"}, "hoge";

is scalar keys %cache, 3;
is_deeply [sort keys %cache], [qw(bar baz foo)];
ok scalar %cache;

# Delete baz
is delete $cache{"UNKNOWN"}, undef;
is delete $cache{"baz"}, "piyo";

ok !exists $cache{"baz"};
is scalar keys %cache, 2;
is_deeply [sort keys %cache], [qw(bar foo)];
ok scalar %cache;

# Overwrite bar
(tied %cache)->set(bar => "updated!", "3s");
is $cache{"bar"}, "updated!";


my $w1; $w1 = AE::timer 2, 0, sub{  # 2 seconds later
    is scalar keys %cache, 1;
    is_deeply [sort keys %cache], [qw(bar)];
    ok scalar %cache;
    
    ok !exists $cache{"foo"};
    
    ok exists $cache{"bar"};
    is $cache{"bar"}, "updated!";
    
    ok !exists $cache{"baz"};
};

my $w2; $w2 = AE::timer 4, 0, sub{  # 4 seconds later
    is scalar keys %cache, 0;
    is_deeply [sort keys %cache], [];
    is "" . %cache, "0";
    ok !%cache;
    
    ok !exists $cache{"foo"};
    ok !exists $cache{"bar"};
    ok !exists $cache{"baz"};
    
    $end_cv->send;
};


$end_cv->recv;
done_testing;
