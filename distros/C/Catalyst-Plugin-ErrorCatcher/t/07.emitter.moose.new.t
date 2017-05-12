#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

use Test::More 0.92;
use Test::Exception;

BEGIN {
    use FindBin::libs;
}

BEGIN {
    $ENV{ TESTAPP_CONFIG }          = "$FindBin::Bin/lib/testapp_mooseemitinit.conf";
}

use Catalyst::Test 'TestApp';

# ensure that everything is running
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;

# check for a value that's only set in new()
is(
    TestApp->config->{"My::MooseEmitter"}{set_in_new},
    1,
    "config value set in call to emitter's new()"
);
ok(
    ref(TestApp->_errorcatcher_emitter_of->{'My::MooseEmitter'}),
    'stored _errorcatcher_emitter_of value'
);
isa_ok (
    TestApp->_errorcatcher_emitter_of->{'My::MooseEmitter'},
    'My::MooseEmitter',
);

# the emitter should have a tired value for jason
is(
    TestApp->_errorcatcher_emitter_of->{'My::MooseEmitter'}->jason,
    'tired',
    'jason is tired'
);
# the emitter should have a faked_config_value
is(
    TestApp->_errorcatcher_emitter_of->{'My::MooseEmitter'}->faked_value,
    'not really here',
    'value from BUILDARGS is correct'
);
# the emitter should have a some_config_value
is(
    TestApp->_errorcatcher_emitter_of->{'My::MooseEmitter'}->from_config,
    'shiny',
    'config value via BUILDARGS is correct'
);

# check output with stacktrace
TestApp->config->{stacktrace}{enable} = 1;
TestApp->config->{"Plugin::ErrorCatcher"}{enable} = 1;
{
    my ($res,$c);

    lives_ok {
        ok( ($res,$c) = ctx_request('http://localhost/foo/crash_user'), 'request ok' );
    } "survived request to exception URL";

    my $ec_msg;
    eval{ $ec_msg = $c->_errorcatcher_msg };
    ok( defined $ec_msg, 'parsed error message ok' );

    # we should have some user information
    like(
        $ec_msg,
        qr{User: buffy \[id\] \(Catalyst::Authentication::User::Hash\)},
        'user details ok'
    );

    like(
        $ec_msg,
        qr{Error: Vampire\n},
        'Buffy staked the vampire'
    );

    # check for a value that's only set in emit()
    is(
        TestApp->config->{"My::MooseEmitter"}{set_in_emit},
        1,
        "config value set in call to emitter's emit()"
    );

    # check for a value that's only set in new()
    is(
        TestApp->config->{"My::MooseEmitter"}{set_in_new},
        1,
        "config value persisted from call to emitter's new()"
    );
}

done_testing;
