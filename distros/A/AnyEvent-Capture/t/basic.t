use strict;
use warnings;
use Test::More tests => 2;
use AnyEvent::Capture;
use AnyEvent::Socket qw( inet_aton );

# As of this writing (AnyEvent 7.01), "localhost" is hard coded into AnyEvent::Socket.
my @ips = capture { inet_aton( 'localhost', shift) };

ok( scalar @ips, "we looked up ips for localhost" );

my $time = AE::now;
$SIG{'ALRM'} = sub { die };
eval {
    alarm(1);
    capture { AE::timer 0.5, 0, shift };
    alarm(0);
};
if ($@) {
    fail("We slept successfully");
    diag("  We hadn't woken up after a second and an alarm triggered");
}
else {
    cmp_ok( AE::now-$time, '>', 0.4, "We slept successfully" );
}
