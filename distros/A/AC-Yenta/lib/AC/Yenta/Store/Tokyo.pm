# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 18:39 (EDT)
# Function: interface with Tokyo cabinet
#
# $Id$

package AC::Yenta::Store::Tokyo;
use AC::Yenta::Debug 'tokyo';
use strict;

# does not work on sparc (tests sigbus)
# new version does not compile with gcc 3.4.3
#
# faster average performance than BDB
# worse worst-case performance than BDB

BEGIN {
    # only if we have it (not on sparc)
    eval {
        require TokyoCabinet;

        AC::Yenta::Store::Map->add_backend( tcb 	=> 'AC::Yenta::Store::Tokyo' );
        AC::Yenta::Store::Map->add_backend( tokyo 	=> 'AC::Yenta::Store::Tokyo' );
    };
};

sub new {
    my $class = shift;
    my $name  = shift;
    my $conf  = shift;

    my $file  = $conf->{dbfile};
    unless( $file ){
        problem("no dbfile specified for '$name'");
        return;
    }

    debug("opening Tokyo DB file=$file");

    my $db = TokyoCabinet::BDB->new();
    my $flags = $conf->{readonly} ? ($db->OREADER | $db->ONOLCK) : ($db->OWRITER | $db->OCREAT);
    if(!$db->open($file, $flags)){
        #my $ecode = $db->ecode();
        #printf STDERR ("open error: %s\n", $db->errmsg($ecode));
        problem("cannot open db file $file");
    }

    # web server will need access
    chmod 0666, $file;

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
    my $v = $me->{db}->get( _key($map,$sub,$key) );

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

    my $r = $me->{db}->put( _key($map,$sub,$key), $val);
    return 1;
}

sub del {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    $me->{db}->out( _key($map,$sub,$key));
}

sub sync {
    my $me  = shift;

    $me->{db}->sync();
}

sub range {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;
    my $end = shift;	# undef => to end of map

    my $cur = TokyoCabinet::BDBCUR->new($me->{db});

    my @k;

    my $e = _key($map,$sub,$end);

    my $k = _key($map,$sub,$key);
    my $r = $cur->jump($k);

    while( $cur->key() ){
        my $k = $cur->key();
        my $v = $cur->val();

        last if $end && ($k ge $e);

        debug("range $k");

        last unless $k =~ m|$map/$sub/|;
        $k =~ s|$map/$sub/||;
        push @k, { k => $k, v => $v };
        $cur->next();
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
