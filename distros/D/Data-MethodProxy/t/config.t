#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Config::MethodProxy qw( :all );

{
    package My::Test::Config;
    sub foo { shift; join('-','FOO',@_) }
    $INC{'My/Test/Config.pm'} = 1;
}

is(
    !!is_method_proxy(['$proxy','Package','method','arg']),
    !!1,
    'is_method_proxy passed',
);

is(
    !!is_method_proxy('foo'),
    !!0,
    'is_method_proxy failed',
);

is(
    call_method_proxy(['$proxy', 'My::Test::Config', 'foo', 'bar', 'baz']),
    'FOO-bar-baz',
    'call_method_proxy passed',
);

like(
    dies { call_method_proxy([undef, 'My::Test::Config', 'foo', 'bar', 'baz']) },
    qr{Invalid method proxy passed to call},
    'call_method_proxy failed',
);

is(
    apply_method_proxies({
        that => ['$proxy', 'My::Test::Config', 'foo', 'that'],
    }),
    { that => 'FOO-that' },
    'apply_method_proxies passed',
);

like(
    dies { apply_method_proxies({
        that => ['$proxy', 'My::Test::Config', 'foo_bad', 'that'],
    }) },
    qr{Uncallable method proxy passed to call},
    'apply_method_proxies failed',
);

done_testing;
