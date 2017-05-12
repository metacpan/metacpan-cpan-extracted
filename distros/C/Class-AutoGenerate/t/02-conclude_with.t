#!/usr/bin/env perl
use strict;
use warnings;

use Test::More tests => 3;

package My::Util;

sub require_helpers {
    my $class = shift;
    my $module = shift;

    for my $name ( qw( Bob Larry ) ) {
        my $helper = "My::Thing::${module}::Helper::$name";
        eval "require '$helper'";
        die $@ if $@;
    }
}

package My::ClassLoader;
use Class::AutoGenerate -base;

requiring 'My::Thing::*' => generates {
    my $module = $1;

    defines 'do_something' => sub { return 1 };

    conclude_with source_code "My::Util->require_helpers('$module');";
};

requiring 'My::Thing::*::Helper::*' => generates {
    my $module = $1;
    my $name   = $2;

    # We only make helpers for something that exists!
    my $thing = "My::Thing::$module";
    eval "require '$thing'" or next_rule;

    defines 'help_with_something' => sub { return 1 };
};

package main;

My::ClassLoader->new;

require_ok('My::Thing::Flup');
require_ok('My::Thing::Flup::Helper::Bob');
require_ok('My::Thing::Flup::Helper::Larry');
