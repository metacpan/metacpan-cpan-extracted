# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Apr-07 18:09 (EDT)
# Function: direct access (read-only) to yenta data file
#
# $Id$

package AC::Yenta::Direct;
use AC::Yenta::Store::Map;
use AC::Yenta::Store::BDBI;
use AC::Yenta::Store::SQLite;
use AC::Yenta::Store::Tokyo;
use AC::Misc;
use AC::Import;
use strict;

our @EXPORT = 'yenta_direct_get';

sub yenta_direct_get {
    my $file = shift;
    my $map  = shift;
    my $key  = shift;

    my $me = __PACKAGE__->new($map, $file);
    return unless $me;
    return $me->get( $key );
}


sub new {
    my $class = shift;
    my $map   = shift;
    my $file  = shift;

    my $db = AC::Yenta::Store::Map->new( $map, undef, { dbfile => $file, readonly => 1 } );
    return unless $db;

    return bless { db => $db }, $class;
}

sub get {
    my $me  = shift;
    my $key = shift;

    my $db = $me->{db};
    return $db->get($key);
}

sub allkeys {
    my $me  = shift;

    return $me->getrange( '', '' );
}

sub getrange {
    my $me  = shift;
    my $lo  = shift;
    my $hi  = shift;

    my $db = $me->{db};

    return map { $_->{k} } $db->range( ($lo||''), ($hi||'') );
}

1;
