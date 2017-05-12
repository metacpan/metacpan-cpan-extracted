#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use lib qw{../lib  lib};
use Acme::Dump::And::Dumper;

my $data = {
    foo => "bar\nber",
    ber => {
        beer => [qw/x y z/],
        obj  => bless([], 'Foo::Bar'),
    },
};

print DnD $data;

