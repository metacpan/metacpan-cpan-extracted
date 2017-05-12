#!perl -T

use strict;
use warnings;
use lib 't';

use Test::More tests => 27;

use MyClass;

do {
    my $c = MyClass->new();
    $c->load_components('AutoloadPlugin');
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->autoload_plugins({ module => 'Hello'}); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->autoload_plugins({ module => 'Hello'}); # hashref.
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], undef;
    is scalar(@{ $c->run_hook('hello') }), 1;
};

do {
    my $c = MyClass->new();
    $c->load_components('AutoloadPlugin');
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->autoload_plugins('Hello'); # simple string
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->autoload_plugins('Hello'); # simple string
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], undef;
    is scalar(@{ $c->run_hook('hello') }), 1;
};

do {
    my $c = MyClass->new();
    $c->load_components('AutoloadPlugin');
    is $c->call('hello'), undef;
    is $c->run_hook('hello'), undef;

    $c->autoload_plugins('+MyClass::Plugin::Hello'); # full path
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is scalar(@{ $c->run_hook('hello') }), 1;

    $c->autoload_plugins('+MyClass::Plugin::Hello'); # full path
    is $c->call('hello'), 'hello';
    is $c->run_hook('hello')->[0], 'hook hello';
    is $c->run_hook('hello')->[1], undef;
    is scalar(@{ $c->run_hook('hello') }), 1;
};

