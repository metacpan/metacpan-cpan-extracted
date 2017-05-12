#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use CatalystX::Starter;
use Test::TableDriven (
    module2dist => {
                     'Foo::Bar'                   => 'Foo-Bar',
                     'Foo::Bar::Baz'              => 'Foo-Bar-Baz',
                     'Catalyst::Plugin::Foo::Bar' => 'Catalyst-Plugin-Foo-Bar',
                   },
);

runtests;

sub module2dist {
    return CatalystX::Starter::_module2dist($_[0]);
}
