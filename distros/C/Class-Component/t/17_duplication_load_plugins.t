#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 36;

use MyClass;

do {
    my $c = MyClass->new();
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->load_plugins({ module => 'Hello'}); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->load_plugins({ module => 'Hello'}); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 2;
};

do {
    my $c = MyClass->new();
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->load_plugins({ module => 'Hello', config => {} }); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->load_plugins({ module => 'Hello', config => {} }); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 2;
};

do {
    my $c = MyClass->new();
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->load_plugins('Hello'); # simple string
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->load_plugins('Hello'); # simple string
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], undef;
    is scalar(@{ $c->run_hook('hello') }), 1;
};

do {
    my $c = MyClass->new();
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->load_plugins('+MyClass::Plugin::Hello'); # full path
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->load_plugins('+MyClass::Plugin::Hello'); # full path
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], undef;
    is scalar(@{ $c->run_hook('hello') }), 1;
};
