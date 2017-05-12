#!/usr/bin/env perl
# Copyright (c) 2007 Jonathan Rockway <jrockway@cpan.org>

use strict;
use warnings;
use CatalystX::Starter;
use Test::TableDriven (
    split_module => { 'Foo::Bar' => [qw/Foo Bar/],
                      'Foo'      => [qw/Foo/],
                    },
);

runtests;

sub split_module {
    return [CatalystX::Starter::_split_module($_[0])];
}
