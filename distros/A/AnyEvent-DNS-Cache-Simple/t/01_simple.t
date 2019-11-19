use strict;
use warnings;
use AnyEvent::DNS::Cache::Simple;
require "./t/TestCache.pm";
t::TestCache->import();
use Test::More;

my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname("google.com");

if( !$name or $length == 1 ) {
    plan skip_all => 'couldnot resolv google.com';
}

my $cache = t::TestCache->new;
my $guard = AnyEvent::DNS::Cache::Simple->register(
    cache => $cache
);

for my $i ( 1..3 ) {
    my $cv = AE::cv;
    ok(!$cache->get('in a google.com')) if $i == 1;
    AnyEvent::DNS::a "google.com", sub {
        ok(scalar @_);
        $cv->send;
    };
    $cv->recv;
    ok($cache->get('in a google.com'),"positive cache check $i");
}
is($t::TestCache::HIT{'in a google.com'}, 5);

undef $guard;

for my $i ( 1..3 ) {
    my $cv = AE::cv;
    AnyEvent::DNS::a "example.com", sub {
        ok(scalar @_);
        $cv->send;
    };
    $cv->recv;
    ok(!$cache->get('in a example.com'),"negative cache check $i");
}
ok(!$t::TestCache::HIT{'in a example.com'});

done_testing();
