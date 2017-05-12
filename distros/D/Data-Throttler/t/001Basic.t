######################################################################
# Test suite for Throttler
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

use Test::More;
use Data::Throttler;

plan tests => 16;

my $throttler = Data::Throttler->new(
    max_items => 2,
    interval  => 60,
);

is($throttler->try_push(), 1, "1st item");
is($throttler->try_push(), 1, "2nd item");
is($throttler->try_push(), 0, "3nd item");

is($throttler->try_push(key => "foobar"), 1, "1st item (key)");
is($throttler->try_push(key => "foobar"), 1, "2nd item (key)");
is($throttler->try_push(key => "foobar"), 0, "3nd item (key)");

is($throttler->reset_key(key => "foobar"), 2, "reset key with two attempts");
is($throttler->try_push(key => "foobar"), 1, "pushed an item");
is($throttler->reset_key(key => "foobar"), 1, "reset key with one attempt");
is($throttler->reset_key(key => "foobar"), 0, "immediate reset shows zero attempts");

$throttler = Data::Throttler->new(
    max_items => 2,
    interval  => 2,
);

$throttler->try_push() for (1..3);
is($throttler->try_push(), 0, "rejected before sleep");
sleep(2);
is($throttler->try_push(), 1, "1st item after sleep");

$throttler->try_push() for (1..3);
is($throttler->try_push( 'force' => 0 ), 0, 'no force = reject/no increment');
is($throttler->current_value(), 2, 'before force');
is($throttler->try_push( 'force' => 1 ), 0, 'force = reject/increment');
is($throttler->current_value(), 3, 'confirm increment');
