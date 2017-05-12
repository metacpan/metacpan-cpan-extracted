# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Mar-30 18:39 (EDT)
# Function: interface with Berkeley DB
#
# $Id$

package AC::Yenta::Store::BDBI;
use AC::Yenta::Debug 'bdbi';
use BerkeleyDB;
use POSIX;
use Sys::SigAction 'set_sig_handler';
use strict;

my $TIMEOUT = 30;

AC::Yenta::Store::Map->add_backend( bdb 	=> 'AC::Yenta::Store::BDBI' );
AC::Yenta::Store::Map->add_backend( berkeley 	=> 'AC::Yenta::Store::BDBI' );

my %recovered;

sub new {
    my $class = shift;
    my $name  = shift;
    my $conf  = shift;

    my $file  = $conf->{dbfile};
    unless( $file ){
        problem("no dbfile specified for '$name'");
        return;
    }

    my $dir = $file;
    $dir =~ s|/[^/]+$||;

    # recover only once per dir
    my $recov = ( $conf->{recovery} && !$recovered{$dir} );
    $recovered{$dir} = 1 if $recov;

    if( $recov ){
        unlink $_ for glob "$dir/__*";
    }

    my $flags = $conf->{readonly} ? 0 : (DB_CREATE| DB_INIT_CDB | DB_INIT_MPOOL);

    debug("opening Berkeley dir=$dir, file=$file (recov $recov)");
    my $env = BerkeleyDB::Env->new(
        -Home       => $dir,
        -Flags      => $flags,
       );

    # microsecs
    $env->set_timeout($TIMEOUT * 1_000_000 / 2, DB_SET_LOCK_TIMEOUT) if $env;

    my $db = BerkeleyDB::Btree->new(
        -Filename   => $file,
        -Env        => $env,
        -Flags      => DB_CREATE,
       );

    problem("cannot open db file $file") unless $db;

    # web server will need access
    chmod 0666, $file;

    return bless {
        dir	=> $dir,
        file	=> $file,
        db	=> $db,
        hasenv  => ($env ? 1 : 0),
    }, $class;
}

sub get {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    my $v;
    debug("get $map/$sub/$key");

    $me->_start();
    my $r = $me->{db}->db_get( _key($map,$sub,$key), $v );
    $me->_finish();

    return if $r; # not found

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

    $me->_start();
    my $r = $me->{db}->db_put( _key($map,$sub,$key), $val);
    $me->_finish();

    return !$r;
}

sub del {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    $me->_start();
    $me->{db}->db_del( _key($map,$sub,$key));
    $me->_finish();
}

sub sync {
    my $me  = shift;

    $me->{db}->db_sync();
}

sub range {
    my $me  = shift;
    my $map = shift;
    my $sub = shift;
    my $key = shift;
    my $end = shift;	# undef => to end of map

    my ($k, $v, @k);
    $me->_start();
    my $cursor = $me->{db}->db_cursor();
    $k = _key($map,$sub,$key);
    my $e = _key($map,$sub,$end);
    $cursor->c_get($k, $v, DB_SET_RANGE);

    my $MAX = 100;
    my $max = $MAX;

    while( !$end || ($k lt $e) ){
        debug("range $k");
        last unless $k =~ m|$map/$sub/|;
        $k =~ s|$map/$sub/||;
        push @k, { k => $k, v => $v };
        my $r = $cursor->c_get($k, $v, DB_NEXT);
        last if $r;	# error

        # cursor locks the db
        # close+recreate so other processes can proceed
        unless( $max -- ){
            $cursor->c_close();
            $me->_finish();
            sleep 0;
            $me->_start();
            $cursor = $me->{db}->db_cursor();
            $cursor->c_get($k, $v, DB_SET);
            $max = $MAX;
        }
    }
    $cursor->c_close();
    $me->_finish();

    return @k;
}

################################################################

sub _sig {
    print STDERR "bdbi signal @_\n", AC::Error::stack_trace(), "\n";
    exit(-1);
}

sub _start {
    my $me = shift;

    $me->{alarmold} = alarm($TIMEOUT);
    return unless $me->{hasenv};

    # as long as perl handles the signals, everything gets cleaned up
    # well enough for the locks to be removed
    for my $sig (qw(INT QUIT KILL TERM ALRM)){
        $SIG{$sig} ||= \&_sig;
    }
}

sub _finish {
    my $me = shift;

    alarm($me->{alarmold} || 0);
    $me->{alarmold} = 0;
}


sub _key {
    my $map = shift;
    my $sub = shift;
    my $key = shift;

    return "$map/$sub/$key";
}

1;
