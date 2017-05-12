use strict;
use Test::More tests => 1;
use AnyEvent::HTTP::LWP::UserAgent;

# For some error cases, AnyEvent::HTTP does not call `on_header' callback.
# Invalid host name is one of the cases.
# This test checks if this class does not die for the cases.

my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
eval { my $res = $ua->get('http://www.invalid/'); };
ok ! $@;
