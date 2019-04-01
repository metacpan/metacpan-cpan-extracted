#!/usr/bin/env perl
use 5.008001;
use strict;
use warnings;
use Test2::V0;

use Data::MethodProxy;

{
    package My::Test::Config;
    sub foo { shift; join('-','FOO',@_) }
    $INC{'My/Test/Config.pm'} = 1;
}

my $mproxy = Data::MethodProxy->new();

subtest is_valid => sub{
    foreach my $test (
        [undef, 0, 'undef'],
        [1, 0, '1'],
        [[], 0, '[]'],
        [['&proxx'], 0, q<['&proxx']>],
        [{foo=>1}, 0, '{foo=>1}'],
        ['abc', 0, 'abc'],
        [['$proxy'], 0, q<['&proxy']>],
        [['$proxy','Package','method','arg'], 1, q<['&proxy','Package','method','arg']>],
    ) {
       my ($value, $ok, $msg) = @$test;

        is(
            !!$mproxy->is_valid( $value ),
            !!$ok,
            "$msg " . ($ok ? 'IS ' : 'is NOT ') . 'valid',
        );
    }
};

subtest is_callable => sub{
    foreach my $test (
        [['$proxy','My::Test::Config','foo'], 1, q<['$proxy','My::Test::Config','foo']>],
        [['$proxy','My::Test::Config','bar'], 0, q<['$proxy','My::Test::Config','bar']>],
        [['$proxy','My::Test::BadConfig','foo'], 0, q<['$proxy','My::Test::BadConfig','foo']>],
    ) {
       my ($value, $ok, $msg) = @$test;

        is(
            !!$mproxy->is_callable( $value ),
            !!$ok,
            "$msg " . ($ok ? 'IS ' : 'is NOT ') . 'callable',
        );
    }
};

subtest call => sub{
    is(
        $mproxy->call(['$proxy', 'My::Test::Config', 'foo', 'bar', 'baz']),
        'FOO-bar-baz',
        'works',
    );

    like(
        dies { $mproxy->call([undef, 'My::Test::Config', 'foo', 'bar', 'baz']) },
        qr{Invalid method proxy passed to call},
        'invalid marker string failed',
    );

    like(
        dies { $mproxy->call(['$proxy', undef, 'foo', 'bar', 'baz']) },
        qr{Invalid method proxy passed to call},
        'undef package failed',
    );

    like(
        dies { $mproxy->call(['$proxy', 'My::Test::Config', undef, 'bar', 'baz']) },
        qr{Invalid method proxy passed to call},
        'undef method failed',
    );

    like(
        dies { $mproxy->call(['$proxy', 'My::Test::BadConfig', 'foo', 'bar', 'baz']) },
        qr{Uncallable method proxy passed to call},
        'nonexistent package failed',
    );

    like(
        dies { $mproxy->call(['$proxy', 'My::Test::Config', 'bad_foo', 'bar', 'baz']) },
        qr{Uncallable method proxy passed to call},
        'nonexistent subroutine failed',
    );
};

subtest render => sub{
    is(
        $mproxy->render({
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
        'passed',
    );

    like(
        dies { $mproxy->render({
            that => ['$proxy', 'My::Test::Config', 'foo_bad', 'that'],
        }) },
        qr{Uncallable method proxy passed to call},
        'failed: missing method',
    );

    like(
        dies {
            my $circle = [];
            push @$circle, $circle;
            $mproxy->render({
                that => ['$proxy', 'My::Test::Config', 'foo', 'that'],
                round => $circle,
            });
        },
        qr{Circular reference detected in data passed to render},
        'failed: circular reference found',
    );
};

done_testing;
