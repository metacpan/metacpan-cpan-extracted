use strict;
use warnings;
require "./t/TestCache.pm";
t::TestCache->import();
use AnyEvent::DNS::Cache::Simple;
use Test::More;
use Test::Requires qw/Net::DNS::Lite/;

my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname("www.example.com");
if( !$name or $length == 1 ) {
    plan skip_all => 'couldnot resolv www.example.com';
}

my $cache = t::TestCache->new;
$Net::DNS::Lite::CACHE = $cache;

my $guard = AnyEvent::DNS::Cache::Simple->register(
    cache => $cache
);

for my $i ( 1..3 ) {
    my $cv = AE::cv;
    ok(!$cache->get('in a www.example.com')) if $i == 1;
    AnyEvent::DNS::a "www.example.com", sub {
        ok(scalar @_);
        $cv->send;
    };
    $cv->recv;
    ok($cache->get('in a www.example.com'),"positive cache check $i");
}
is($t::TestCache::HIT{'in a www.example.com'}, 5);
my $addr = Net::DNS::Lite::inet_aton("www.example.com");
ok($addr);
ok(scalar grep {$_ eq $addr} @addrs);
is($t::TestCache::HIT{'in a www.example.com'}, 6);

done_testing;
