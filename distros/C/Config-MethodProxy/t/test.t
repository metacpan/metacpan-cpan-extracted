#!/usr/bin/env perl
use Test2::Bundle::Extended;
use Test::Fatal;

use Config::MethodProxy qw( :all );

{
    package My::Test::Config;
    sub foo { shift; join('-','FOO',@_) }
    $INC{'My/Test/Config.pm'} = 1;
}

subtest is_method_proxy => sub{
    foreach my $test (
        [undef, 0, 'undef'],
        [1, 0, '1'],
        [[], 0, '[]'],
        [['&proxx'], 0, q<['&proxx']>],
        [{foo=>1}, 0, '{foo=>1}'],
        ['abc', 0, 'abc'],
        [['$proxy'], 1, q<['&proxy']>],
        [['$proxy','Package','method','arg'], 1, q<['&proxy','Package','method','arg']>],
        [['&proxy'], 1, q<['&proxy']>],
    ) {
       my ($value, $ok, $msg) = @$test;

        is(
            !!is_method_proxy( $value ),
            !!$ok,
            "$msg " . ($ok ? 'IS ' : 'is NOT ') . 'a method proxy',
        );
    }
};

subtest call_method_proxy => sub{
    is(
        call_method_proxy(['$proxy', 'My::Test::Config', 'foo', 'bar', 'baz']),
        'FOO-bar-baz',
        'works',
    );

    like(
        dies { call_method_proxy([undef, 'My::Test::Config', 'foo', 'bar', 'baz']) },
        qr{Not a method proxy},
        'invalid marker string failed',
    );

    like(
        dies { call_method_proxy(['$proxy', undef, 'foo', 'bar', 'baz']) },
        qr{package is undefined},
        'undef package failed',
    );

    like(
        dies { call_method_proxy(['$proxy', 'My::Test::Config', undef, 'bar', 'baz']) },
        qr{method is undefined},
        'undef method failed',
    );

    like(
        dies { call_method_proxy(['$proxy', 'My::Test::Config::Bad', 'foo', 'bar', 'baz']) },
        qr{Can't locate},
        'nonexistent package failed',
    );
};

is(
    apply_method_proxies({
        this => 1,
        that => ['$proxy', 'My::Test::Config', 'foo', 'that'],
        them => [
            'abc',
            ['&proxy', 'My::Test::Config', 'foo', 'them'],
            { yo=>['&proxy', 'My::Test::Config', 'foo', 'them', 'yo'] },
        ],
    }),
    {
        this => 1,
        that => 'FOO-that',
        them => [
            'abc',
            'FOO-them',
            { yo=>'FOO-them-yo' },
        ],
    },
    'apply_method_proxies',
);

done_testing;
