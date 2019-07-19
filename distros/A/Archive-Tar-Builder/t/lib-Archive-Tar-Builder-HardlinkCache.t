#! /usr/bin/perl

# Copyright (c) 2019, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Archive::Tar::Builder::HardlinkCache;

use Test::More 'tests' => 4;
use Test::Exception;

lives_ok {
    Archive::Tar::Builder::HardlinkCache->new;
}
'Archive::Tar::Builder::HardlinkCache->new does not die()';

my $cache = Archive::Tar::Builder::HardlinkCache->new;

is( $cache->lookup( 0, 0, 'foo/bar' ) => undef,     '$cache->lookup() returns undef on first encounter of dev/inode pair' );
is( $cache->lookup( 0, 0, 'foo/bar' ) => 'foo/bar', '$cache->lookup() returns a value on second encounter of dev/inode pair' );
is( $cache->lookup( 0, 0, 'bar/baz' ) => 'foo/bar', '$cache->lookup() returns the original path of previously cached dev/inode pair' );
