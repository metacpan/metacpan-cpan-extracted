# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-13 16:45 (EST)
# Function: child half of m/r task (the actual running task)
#
# $Id: Running.pm,v 1.5 2011/01/12 19:18:54 jaw Exp $

package AC::MrGamoo::Task::Running;
use AC::MrGamoo::Config;
use AC::MrGamoo::Debug 'task_run';
use AC::MrGamoo::Iter::File;
use AC::MrGamoo::EUConsole;
use AC::MrGamoo::ReadInput;
use AC::MrGamoo::OutFile;
use AC::MrGamoo::MySelf;
use AC::Daemon;
use Digest::SHA1 'sha1';
use Digest::MD5  'md5';
use File::Path;
use Sys::Syslog;
use Socket;
use JSON;
use strict;

my $STATUSTIME = 5;			# seconds
my $MAXRUN     = 3600;			# override with %attr maxrun
my $SORTPROG   = '/usr/bin/sort';	# override with %attr sortprog or config file
my $GZPROG     = '/usr/bin/gzcat';	# override with %attr gzprog or config file

# in child process
sub _start_task {
    my $me = shift;

    debug("start child task");
    $^T = time();
    _setup_stdio_etal();
    _setup_console( $me );
    _update_status( 'STARTING', 0 );

    # send STDOUT + STDERR to end-user console session
    $me->{R}{eu_print_stderr} = sub { eu_print_stderr( $me, @_ )  };
    $me->{R}{eu_print_stdout} = sub { eu_print_stdout( $me, @_ ) };
    $me->{R}->redirect_io();

    my $n = $me->{request}{outfile} ? @{$me->{request}{outfile}} : 0;
    $me->{R}{func_output}   = sub{ _output_partition($me, $n, @_) };
    $me->{R}{func_progress} = sub{ _maybe_update_status($me, 'RUNNING', @_) };

    eval {
        _setup_outfiles( $me );

        if( $me->{request}{phase}     eq 'map' ){
            _do_map( $me );
        }elsif( $me->{request}{phase} eq 'final' ){
            _do_final( $me );
        }elsif( $me->{request}{phase} =~ /^reduce/ ){
            _do_reduce( $me );
        }else{
            die "unknown map/reduce phase '$me->{request}{phase}'\n";
        }
    };
    if( my $e = $@ ){
        my $myid = my_server_id();
        verbose( "ERROR: $myid - $e" );
        _send_eumsg($me, 'stderr', "ERROR: $myid - $e");
        _update_status( 'FAILED', 0 );
    }

    _close_outfiles( $me );
    _update_status( 'FINISHED', 0 );
    debug("finish child task");
    exit(0);
}

sub _setup_stdio_etal {

    # move socket to parent from STDOUT -> STATUS
    # so user code doesn't trample

    open( STATUS, ">&STDOUT" );
    close STDOUT; open( STDOUT, ">/dev/null");
    close STDIN;  open( STDIN,  "/dev/null");
    select STATUS; $| = 1; select STDOUT;
    $SIG{CHLD} = sub{};
    $SIG{ALRM} = sub{ die "timeout\n" };
    openlog('mrgamoo', 'ndelay, pid', (conf_value('syslog') || 'local4'));

    alarm( $MAXRUN );
}

sub _setup_console {
    my $me = shift;

    debug("setup console: $me->{request}{jobid}, $me->{request}{console}");
    $me->{euconsole} = AC::MrGamoo::EUConsole->new( $me->{request}{jobid}, $me->{request}{console} );
}

sub _send_eumsg {
    my $me   = shift;
    my $type = shift;
    my $msg  = shift;

    return unless $me->{euconsole};
    $me->{euconsole}->send_msg($type, $msg);
}

sub _update_status {
    my $phase = shift;
    my $amt   = shift;

    # send status to parent process
    debug("sending status @ $^T / $phase/$amt");
    print STATUS "$phase $amt\n";
}

sub _maybe_update_status {
    my $me = shift;

    $^T = time();

    return if $^T < ($me->{status_time} + $STATUSTIME);
    $me->{status_time} = $^T;
    _update_status( @_ );
}

sub _setup_outfiles {
    my $me = shift;
    my @out;

    my $gz = $me->attr(undef, 'compress');
    for my $file ( @{$me->{request}{outfile}} ){
        my $f = conf_value('basedir') . '/' . $file;
        my($dir) = $f =~ m|^(.+)/[^/]+$|;

        eval{ mkpath($dir, undef, 0777) };
        push @out, AC::MrGamoo::OutFile->new( $f, $gz );
    }

    $me->{outfd} = \@out;
}

sub _close_outfiles {
    my $me = shift;

    for my $io ( @{$me->{outfd}} ){
        $io->close();
    }
    delete $me->{outfd};
}

sub _output_partition {
    my ($me, $n, $key, $data) = @_;

    # md5 is twice as fast as sha1.
    # anything written  in perl is 10 times slower
    my $hash = unpack('N', md5( $key ));
    my $p    = $hash % $n;
    my $io   = $me->{outfd}[$p];
    $io->output( encode_json( [ $key, $data ] ), "\n" );
}


# end-user's 'print' come here
sub eu_print_stdout {
    my $me = shift;

    _send_eumsg($me, 'stdout', "@_");
}

sub eu_print_stderr {
    my $me = shift;

    _send_eumsg($me, 'stderr', "@_");
}

################################################################

sub _do_map {
    my $me = shift;
    my $mr = $me->{mr};

    debug("doing map");
    my $n        = @{$me->{request}{outfile}};
    my $h_filter = $mr->get_code('filefilter');
    my $h_read   = $mr->get_code('readinput') || { code => \&readinput };
    my $h_map    = $mr->get_code('map');
    my $f_filter = $h_filter ? $h_filter->{code} : undef;
    my $f_read   = $h_read->{code};
    my $f_map    = $h_map->{code};

    my $linen = 0;

    my $maxrun = $me->attr($h_map, 'maxrun');
    alarm( $maxrun ) if $maxrun;

    for my $file (@{$me->{request}{infile}}){
        _maybe_update_status( $me, 'RUNNING', $linen );
        $me->{R}{config}{current_file} = $file;	# in case user wants for debugging

        # filter file list
        if( $f_filter ){
            next unless $f_filter->( $file );
        }

        debug("map file: $file");

        my $f = conf_value('basedir') . '/' . $file;

        open(my $fd, $f) || die "cannot open file '$f': $!\n";

        while(1){
            _maybe_update_status( $me, 'RUNNING', $linen++ );

            # read input
            my($d, $eof) = $f_read->( $fd );
            last if $eof;
            next unless defined $d;

            # map
            my($key, $data) = $f_map->( $d );
            next unless defined $key;
            _output_partition( $me, $n, $key, $data );
        }
    }

    $h_map->{cleanup}->()    if $h_map->{cleanup};
    $h_read->{cleanup}->()   if $h_read->{cleanup};
    $h_filter->{cleanup}->() if $h_filter && $h_filter->{cleanup};
}

sub _do_reduce {
    my $me = shift;
    my $mr = $me->{mr};

    my $n        = @{$me->{request}{outfile}};
    my($stage)   = $me->{request}{phase} =~ m|reduce/(\d+)|;
    my $h_reduce = $mr->get_code('reduce', $stage);
    my $f_reduce = $h_reduce->{code};
    my $rown = 0;

    my $maxrun = $me->attr($h_reduce, 'maxrun');
    alarm( $maxrun ) if $maxrun;

    debug( "doing reduce step $stage" );

    # sort
    my @cmd = _sort_cmd( $me, $h_reduce );
    open(SORT, '-|', @cmd) || die "cannot open sort pipe: $!\n";
    _sort_underway( $me, \*SORT );
    my $iter = AC::MrGamoo::Iter::File->new( \*SORT, sub{ _maybe_update_status($me, 'RUNNING', $rown++) } );

    # reduce
    while( defined(my $k = $iter->key()) ){
        _maybe_update_status( $me, 'RUNNING', $rown++ );
        my($key, $data) = $f_reduce->( $k, $iter );
        _output_partition( $me, $n, $key, $data ) if defined $key;
    }

    $h_reduce->{cleanup}() if $h_reduce->{cleanup};
}

sub _do_final {
    my $me = shift;
    my $mr = $me->{mr};

    my $h_final  = $mr->get_code('final');
    my $linen    = 0;

    if( $h_final ){
        debug("doing final");
        my $maxrun = $me->attr($h_final, 'maxrun');
        alarm( $maxrun ) if $maxrun;

        my $f_final = $h_final->{code};

        # sort
        my @cmd = _sort_cmd( $me, $h_final );
        open(SORT, '-|', @cmd) || die "cannot open sort pipe: $!\n";
        _sort_underway( $me, \*SORT );

        while(<SORT>){
            chomp;
            _maybe_update_status( $me, 'RUNNING', $linen++ );
            my $x = decode_json($_);
            $f_final->( $x->[0], $x->[1] );
        }

        $h_final->{cleanup}() if $h_final->{cleanup};
    }
}

################################################################

sub _sort_cmd {
    my $me = shift;
    my $hc = shift;

    my $gz   = $me->attr(undef, 'compress');
    my $sort = $me->attr($hc,'sortprog') || conf_value('sortprog') || $SORTPROG;
    my @file = map { conf_value('basedir') . '/' . $_ } @{$me->{request}{infile}};

    if( $gz ){
        my $zcat = $me->attr($hc,'gzprog') || conf_value('gzprog') || $GZPROG;
        my $cmd  = $zcat . ' ' . join(' ', @file) . ' | ' . $sort;
        debug("running cmd: $cmd");
        return $cmd;
    }else{
        my @cmd = ($sort, @file);
        debug("running cmd: @cmd");
        return @cmd;
    }
}

sub _sort_underway {
    my $me = shift;
    my $fd = shift;

    my $fn = fileno($fd);
    my $rfd = "\0\0\0\0";

    # send progress updates to master while sort is sorting
    while(1){
        vec($rfd, $fn, 1) = 1;

        select($rfd, undef, undef, 5);
        return if vec($rfd, $fn, 1);
        _maybe_update_status( $me, 'RUNNING', 0);
    }

}

################################################################


1;
