# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 18:39 (EDT)
# Function: interface with LevelDB
#
# $Id$

package AC::Yenta::Store::LevelDB;
use AC::Yenta::Debug 'ldb';
use strict;

# does not support concurrent access
# does not work on sparc


BEGIN {
    # only if we have it (no LevelDB on sparc)
    eval {
        require Tie::LevelDB;
        AC::Yenta::Store::Map->add_backend( ldb 	=> 'AC::Yenta::Store::LevelDB' );
        AC::Yenta::Store::Map->add_backend( leveldb 	=> 'AC::Yenta::Store::LevelDB' );
    };
};

my %OPEN;

sub new {
    my $class = shift;
    my $name  = shift;
    my $conf  = shift;

    my $file  = $conf->{dbfile};
    unless( $file ){
        problem("no dbfile specified for '$name'");
        return;
    }

    debug("opening LevelDB file=$file");
    my $db = $OPEN{$file} || Tie::LevelDB::DB->new( $file );
    $OPEN{$file} = $db;

    problem("cannot open db file $file") unless $db;

    # web server will need access
    chmod 0777, $file;

    return bless {
        file	=> $file,
        db	=> $db,
    }, $class;
}

sub get {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    my $v;
    debug("get $map/$sub/$key");
    my $v = $me->{db}->Get( _key($map,$sub,$key) );

    return unless $v; # not found

    if( wantarray ){
        return ($v, 1);
    }
    return $v;
}

sub put {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;
    my $val = shift;

    debug("put $map/$sub/$key");

    my $r = $me->{db}->Put( _key($map,$sub,$key), $val);
    return 1;
}

sub del {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    $me->{db}->Delete( _key($map,$sub,$key));
}

sub sync {
    my $me  = shift;

}

sub range {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;
    my $end = shift;	# undef => to end of map

    my $it = $me->{db}->NewIterator();

    my @k;

    my $e = _key($map,$sub,$end);

    my $k = _key($map,$sub,$key);
    my $r = $it->Seek($k);

    while( $it->Valid() ){
        my $k = $it->key();
        my $v = $it->value();

        last if $end && ($k ge $e);

        debug("range $k");
        last unless $k =~ m|$map/$sub/|;
        $k =~ s|$map/$sub/||;
        push @k, { k => $k, v => $v };
        $it->Next();
    }

    return @k;
}

################################################################

sub _key {
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    return "$map/$sub/$key";
}

1;
