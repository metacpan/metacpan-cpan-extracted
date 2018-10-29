#! /usr/bin/perl

use strict;
use warnings;
use JSON;
use Test::More;
use Test::Exception;
use Cwd qw/abs_path/;
use Appium::Commands;

BEGIN: {
    my $test_lib = abs_path(__FILE__);
    $test_lib =~ s/(.*)\/.*\.t$/$1\/lib/;
    push @INC, $test_lib;
    require MockAppium;
    MockAppium->import(qw/endpoint_ok alias_ok/);

    unless (use_ok('Appium')) {
        BAIL_OUT("Couldn't load Appium");
        exit;
    }
}

my $mock_appium = MockAppium->new;

INVALID_STRATEGY: {
    throws_ok( sub { $mock_appium->find_element('a locator', 'invalid strategy'); },
               qr/android/,
               'Appium should tell us about the right finder strategies'
           );

}

CAPS: {
    my $fake_caps = { app => 'fake' };
    my $caps_key = MockAppium->new(caps => $fake_caps);
    ok($caps_key, 'caps is a valid key for instantiation');

    my $desired_key = MockAppium->new(desired_capabilities => $fake_caps);
    ok($desired_key, 'desired is a valid key for instantiation');

    throws_ok(sub { MockAppium->new(
        desired_capabilities => $fake_caps,
        caps                 => $fake_caps
    ) },
              qr/Conflicting init_args/, 'we won\'t accept both of them, either');
}

CONTEXT: {
    my $context = 'WEBVIEW_1';
    my ($res, $params) = $mock_appium->switch_to->context( $context );
    alias_ok('switch_to->context', $res);
    cmp_ok($params->{name}, 'eq', $context, 'can switch to a context');
}

HIDE_KEYBOARD: {
    my $tests = [
        {
            args => [],
            expected => {
                test => 'no args passes default strategy',
                key => 'strategy',
                value => 'tapOutside'
            }
        },
        {
            args => [ key_name => 'Done' ],
            expected => {
                test => 'can pass a key_name',
                key => 'keyName',
                value => 'Done'
            }
        },
        {
            args => [ strategy => 'fake strategy', key => 'Done' ],
            expected => {
                test => 'can pass a strategy',
                key => 'strategy',
                value => 'fake strategy'
            }
        }
    ];

    foreach (@$tests) {
        my $expected = $_->{expected};
        my (undef, $params) = $mock_appium->hide_keyboard(@{ $_->{args} });

        my $key = $expected->{key};
        ok( exists $params->{$key}, 'hide_keyboard, key: ' . $expected->{test});
        cmp_ok( $params->{$key}, 'eq', $expected->{value}, 'hide_keyboard, val: ' . $expected->{test});

        if ($expected->{test} eq 'can pass a strategy') {
            ok( exists $params->{key}, 'hide_keyboard, key: strategy and key are included');
            cmp_ok( $params->{key}, 'eq', 'Done', 'hide_keyboard, val: strategy and key are included');

        }
    }
}

ANDROID_KEYCODES: {
    my $code = 176;
    endpoint_ok('press_keycode', [ $code ], { keycode => $code });
    endpoint_ok('long_press_keycode', [ $code, 'metastate' ], { keycode => $code, metastate => 'metastate' });

}

PUSH_PULL: {
    my $path = '/fake/path';
    my $data = 'pretend to be base 64 encoded';
    endpoint_ok('pull_file', [ $path ], { path => $path });
    endpoint_ok('pull_folder', [ $path ], { path => $path });
    endpoint_ok('push_file', [ $path, $data ], { path => $path, data => $data });
}

FIND: {
    my @selector = qw/fake selection critera/;
    endpoint_ok('complex_find', [ @selector ], { selector => \@selector });
}

APP: {
    endpoint_ok('background_app', [ 5 ], { seconds => 5 });
    endpoint_ok('is_app_installed', [ 'a fake bundle id' ], { bundleId => 'a fake bundle id' });
    endpoint_ok('install_app', [ '/fake/path/to.app' ], { appPath => '/fake/path/to.app' });
    endpoint_ok('remove_app', [ '/fake/path/to.app' ], { appId => '/fake/path/to.app' });
    endpoint_ok('launch_app');
    endpoint_ok('close_app');
}

DEVICE: {
    endpoint_ok('lock', [ 5 ], { seconds => 5 });
    endpoint_ok('is_locked');
    endpoint_ok('shake');
    endpoint_ok('open_notifications');
    endpoint_ok('network_connection');
    endpoint_ok('set_network_connection', [ 6 ], { parameters => { type => 6 } });
}

MISC: {
    endpoint_ok('end_test_coverage', [ 'intent', 'path' ], {
        intent => 'intent',
        path => 'path'
    });

    ok($mock_appium->can('tap'), 'tap: Appium can tap');
    lives_ok(sub { $mock_appium->tap }, 'tap: and we can tap without dying');
}

done_testing;
