use strict;
use warnings;
use AnyEvent::DNS::Cache::Simple;
use Test::More;
use List::Util qw(sum);
use Time::HiRes qw(time);

my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname("google.com");

if( !$name or $length == 1 ) {
    plan skip_all => 'couldnot resolv google.com';
}

my $guard = AnyEvent::DNS::Cache::Simple->register(
    server => [$addrs[0]],
    timeout => [1,1]
);

my $start_at = time;
my $cv = AE::cv;
AnyEvent::DNS::a "google.com", sub {
    ok(scalar @_ == 0);
    $cv->send;
};
$cv->recv;
my $elapsed = time - $start_at;
my $expected_time = sum @{$AnyEvent::DNS::RESOLVER->{timeout}};
ok(
    $expected_time - 0.5 <= $elapsed && $elapsed <= $expected_time + 0.5,
    "elapsed: $elapsed / expected_time: $expected_time",
);

done_testing;

