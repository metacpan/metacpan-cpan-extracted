# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jun-15 17:21 (EDT)
# Function: sqlite example storage backend
#
# $Id$

package AC::Yenta::Store::SQLite;
use AC::Yenta::Debug 'sqlite';
use MIME::Base64;
use DBI;
use strict;

my $initsql;

AC::Yenta::Store::Map->add_backend( sql    => 'AC::Yenta::Store::SQLite' );
AC::Yenta::Store::Map->add_backend( sqlite => 'AC::Yenta::Store::SQLite' );

sub new {
    my $class = shift;
    my $name  = shift;
    my $conf  = shift;

    my $file  = $conf->{dbfile};
    unless( $file ){
        problem("no dbfile specified for '$name'");
        return;
    }

    debug("opening sqlite file=$file");

    my $dsn = "dbi:SQLite:dbname=$file";

    my $db = DBI->connect( $dsn, '', '', {
        AutoCommit => 1,
        RaiseError => 1,
    } );

    problem("cannot open sqlite file $file") unless $db;

    _init( $db );

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

    debug("get $map/$sub/$key");

    my $st = _do($me->{db}, 'select value, 1 from ykv where map = ? and sub = ? and key = ?', $map, $sub, $key);

    my($v, $found) = $st->fetchrow_array();
    return unless $found;

    $v = decode_base64($v);

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

    my $st = _do($me->{db}, 'select 1 from ykv where map = ? and sub = ? and key = ?', $map, $sub, $key);
    my($found) = $st->fetchrow_array();

    if( $found ){
        _do($me->{db}, 'update ykv set value = ? where map = ? and sub = ? and key = ?', encode_base64($val), $map, $sub, $key);
    }else{
        _do($me->{db}, 'insert into ykv (map,sub,key,value) values (?,?,?,?)',  $map, $sub, $key, encode_base64($val));
    }

    return 1;
}

sub del {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    debug("del $map/$sub/$key");

    _do($me->{db}, 'delete from ykv where map = ? and sub = ? and key = ?', $map, $sub, $key);

    return 1;
}

sub sync {}

sub range {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;
    my $end = shift;	# undef => to end of map

    my $st;

    if( defined $end ){
        $st = _do($me->{db}, 'select key as k, value as v from ykv where map = ? and sub = ? and key >= ? and key < ?',
                     $map, $sub, $key, $end);
    }else{
        $st = _do($me->{db}, 'select key as k, value as v from ykv where map = ? and sub = ? and key >= ?',
                     $map, $sub, $key);
    }

    my $r = $st->fetchall_arrayref({});

    return @$r;
}

################################################################

sub _init {
    my $db = shift;

    eval {
        for my $sql (split /;/, $initsql){
            $sql =~ s/--\s.*$//gm;              # remove comments
            next unless $sql !~ /^\s*$/;
            _do($db, $sql);
        }
    };
    if(my $e=$@){
        # QQQ?
        problem("error initializing sqlite db: $e");
    }
}

sub _do {
    my $db  = shift;
    my $sql = shift;

    my( $st, $nrow );
    eval {
        debug("sql: $sql");
        $st   = $db->prepare( $sql );
        $nrow = $st->execute( @_ );
    };
    my $e = $@;
    die $e if $e;

    return $st;
}

################################################################

$initsql = <<END;

create table if not exists ykv (
	map	text 	not null,
	sub	text	not null,
	key	text	not null,
	value	text,

	unique(map,sub,key)
);

create index if not exists ykvidx on ykv(map, sub, key);

pragma synchronous = 1;         -- default is full(2)

pragma cache_size  = 100000;    -- default is 2000

vacuum;

analyze;

END
;

1;
