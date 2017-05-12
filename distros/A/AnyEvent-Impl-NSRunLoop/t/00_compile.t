use strict;
use Test::More tests => 1;

use AnyEvent;
use AnyEvent::Impl::NSRunLoop;

is AnyEvent::detect, 'AnyEvent::Impl::NSRunLoop';
