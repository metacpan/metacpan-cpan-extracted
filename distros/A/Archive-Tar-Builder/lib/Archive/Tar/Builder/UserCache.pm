# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Archive::Tar::Builder::UserCache;

use strict;
use warnings;

sub new {
    my ($class) = @_;

    return bless {
        'users'  => {},
        'groups' => {}
    }, $class;
}

sub lookup {
    my ( $self, $uid, $gid ) = @_;

    unless ( exists $self->{'users'}->{$uid} ) {
        if ( my @pwent = getpwuid($uid) ) {
            $self->{'users'}->{$uid} = $pwent[0];
        }
        else {
            $self->{'users'}->{$uid} = undef;
        }
    }

    unless ( exists $self->{'groups'}->{$gid} ) {
        if ( my @grent = getgrgid($gid) ) {
            $self->{'groups'}->{$gid} = $grent[0];
        }
        else {
            $self->{'groups'}->{$gid} = undef;
        }
    }

    return ( $self->{'users'}->{$uid}, $self->{'groups'}->{$gid} );
}

1;
