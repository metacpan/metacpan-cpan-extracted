use strict;
use Test::More tests => 3;

use_ok "Cache::Memcached::AnyEvent";

# explicitly test the protocols
use_ok "Cache::Memcached::AnyEvent::Protocol::Binary";
use_ok "Cache::Memcached::AnyEvent::Protocol::Text";