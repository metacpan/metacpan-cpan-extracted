#!/usr/bin/perl

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Archive::Tar::Builder::UserCache ();

use Test::More ( 'tests' => 4 );

sub find_unused_ids {
    my ( $uid, $gid );

    for ( $uid = 99999; getpwuid($uid); $uid-- ) { }
    for ( $gid = 99999; getgrgid($gid); $gid-- ) { }

    return ( $uid, $gid );
}

#
# Test Archive::Tar::Builder internal methods
#
{
    my $cache = Archive::Tar::Builder::UserCache->new;

    my ( $unused_uid, $unused_gid ) = find_unused_ids();

    #
    # Test $cache->lookup()
    #
    my ( $root_name,   $root_group )   = $cache->lookup( 0,           0 );
    my ( $unused_name, $unused_group ) = $cache->lookup( $unused_uid, $unused_gid );

    #
    # I realize some stupid systems may actually not name root, 'root'...
    # I'm looking at you, OS X with your Directory Services...
    #
    # The root group name isn't frequently 'root' outside of the Linux circles,
    # by the by.
    #
    like( $root_name => qr/^(_|)root$/, '$cache->lookup() can locate known existing user name' );
    ok( defined $root_group, '$cache->lookup() can locate known existing group name ' . "'$root_group'" );

    ok( !defined($unused_name),  '$cache->lookup() returns undef on unknown UID' );
    ok( !defined($unused_group), '$cache->lookup() returns undef on unknown GID' );
}
