#!/usr/bin/perl

package CacheTestApp;

use strict;
use warnings;

use Catalyst qw/
    Cache
    Cache::Store::Memory
/;

__PACKAGE__->setup;

__PACKAGE__;

__END__
