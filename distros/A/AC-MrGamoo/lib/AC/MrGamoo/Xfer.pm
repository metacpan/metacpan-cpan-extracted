# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Dec-14 17:49 (EST)
# Function: get file from remote scriblr
#
# $Id: Xfer.pm,v 1.7 2011/01/14 22:24:30 jaw Exp $

package AC::MrGamoo::Xfer;
use AC::MrGamoo::Debug 'xfer';
use AC::MrGamoo::Config;
use AC::MrGamoo::Protocol;
use AC::MrGamoo::EUConsole;
use AC::MrGamoo::PeerList;
use Digest::SHA1;
use File::Path;
use Socket;
use strict;

require 'AC/protobuf/std_reply.pl';
require 'AC/protobuf/scrible.pl';

our @ISA = 'AC::DC::IO::Forked';

my $TIMEOUT    = 3600;	# QQQ
my $BUFSIZ     = 65536;
my $STATUSTIME = 5;
my $MAXRUNNING = 4;	# QQQ - configurable?
my %REGISTRY;

################################################################

# schedule periodic "cronjob"
AC::DC::Sched->new(
    info	=> "xfer periodic",
    freq	=> 5,
    func	=> \&periodic,
   );

################################################################


sub new {
    my $class   = shift;
    my $srcname = shift;	# on remote system
    my $dstname = shift;	# on local system
    my $loc     = shift;
    my $req     = shift;	# APCMRMFileXfer

    if( $REGISTRY{$req->{copyid}} ){
        verbose("ignoring duplicate xfer $req->{copyid}");
        return $REGISTRY{$req->{copyid}};
    }

    $dstname = conf_value('basedir') . '/' . $dstname;
    my $tmpfile = $dstname . ".$$";

    # mkpath
    my($dir) = $dstname =~ m|^(.+)/[^/]+$|;
    eval{ mkpath($dir, undef, 0755) };

    my $me = $class->SUPER::new( \&_run_child,
                                 [ $srcname, $dstname, $tmpfile, $loc, $req ],
                                 info     => "xfer $loc:$srcname",
                                 request  => $req,
                                 rbufsize => 65536,
                                );

    return unless $me;
    $REGISTRY{$req->{copyid}} = $me;
    debug("xfer requesting $loc:$srcname => $dstname, id $req->{copyid}");

    return $me;
}

sub start {
    my $me = shift;

    my $nrun = 0;
    for my $t (values %REGISTRY){
        $nrun ++ if $t->{fd};
    }

    if( $nrun >= $MAXRUNNING ){
        $me->{_queueprio}    = $^T;
        debug("queue xfer $me->{request}{copyid}");
        return 1;
    }

    $me->_start();

}

sub _start {
    my $me = shift;

    debug("start xfer $me->{request}{copyid}");

    $me->timeout_rel($TIMEOUT);
    $me->set_callback('timeout',  \&timeout);
    $me->set_callback('shutdown', \&shutdown);

    $me->SUPER::start();
}

sub _run_child {
    my $srcname = shift;	# on remote system
    my $dstname = shift;	# on local system
    my $tmpfile = shift;
    my $loc     = shift;
    my $req     = shift;


    exit(0) if -f $dstname;
    my $con = AC::MrGamoo::EUConsole->new( $req->{jobid}, $req->{console} );
    $con->send_msg('debug', "retrieving file $loc:$srcname");

    # RSN - remove scriblr::client
    my $ok;
    if( get_peer_addr_from_id($loc) ){
        $ok = _get_file( $req, $loc, $srcname, $tmpfile );
    }else{
        verbose("cannot locate server: $loc");
    }

    if( $ok ){
        rename $tmpfile, $dstname;
        exit 0;
    }
    exit 1;
}

sub timeout {
    my $me = shift;
    debug("xfer timeout");
    $me->shut();
}

sub shutdown {
    my $me = shift;

    delete $REGISTRY{$me->{request}{copyid}};

    debug("exitval = $me->{exitval}");
    if( !$me->{exitval} ){
        $me->run_callback('on_success');
    }else{
        $me->run_callback('on_failure');
    }

    periodic(1);	# try to start another xfer
}

sub _send_status_update {
    my $req = shift;

    debug('send xfer status');
    AC::MrGamoo::API::Xfer::tell_master( $req, 100, 'Working...' );
}


sub _get_file {
    my $oreq    = shift;
    my $loc     = shift;
    my $srcname = shift;	# on remote system
    my $tmpfile = shift;


    my($addr, $port) = get_peer_addr_from_id( $loc );
    unless( $addr ){
        debug("cannot find addr for $loc");
        return;
    }

    debug("connecting to $addr:$port");

    my $req = AC::MrGamoo::Protocol->encode_request( {
        type		=> 'scribl_get',
        msgidno		=> $$,
        want_reply	=> 1,
    }, { filename => $srcname } );

    my $p;
    eval {
        # connect
        my $s = AC::MrGamoo::Protocol->connect_to_server( inet_aton($addr), $port );
        return unless $s;

        # send req
        AC::MrGamoo::Protocol->write_request($s, $req);

        # get response
        my $buf = AC::MrGamoo::Protocol->read_data($s, AC::MrGamoo::Protocol->header_size(), 30);
        $p      = AC::MrGamoo::Protocol->decode_header($buf);
        $p->{data} = AC::MrGamoo::Protocol->read_data($s, $p->{data_length}, 1);
        $p->{data} = AC::MrGamoo::Protocol->decode_reply($p);

        debug("recvd response $p->{data}{status_code}");
        return unless $p->{data}{status_code} == 200;

        # stream file to disk
        my $size = $p->{content_length};
        debug("recving file ($size B)");

        my $fd;
        unless( open( $fd, "> $tmpfile" ) ){
            verbose("cannot open output file '$tmpfile': $!");
            return;
        }

        my $chk  = _sendfile($oreq, $fd, $s, $size);
        my $sha1 = $p->{data}{hash_sha1};
        die "SHA1 check failed\n" if $sha1 && $sha1 ne $chk;
    };
    if(my $e=$@){
        debug("error: $e");
        return;
    }

    return $p;
}

sub _sendfile {
    my $req   = shift;
    my $out   = shift;
    my $in    = shift;
    my $size  = shift;

    my $t;

    my $sha1 = Digest::SHA1->new();

    while($size){
        my $buf;
        my $len = $size > $BUFSIZ ? $BUFSIZ : $size;
        alarm( 1 );
        my $i = sysread($in, $buf, $len);
        die "read failed: $!\n" unless $i > 0;
        $size -= $i;
        $i = syswrite($out, $buf);
        die "write failed: $!\n" unless $i > 0;
        $sha1->add($buf);

        # periodically tell master we are still  copying
        if( time() - $t > $STATUSTIME ){
            _send_status_update( $req );
            $t = time();
        }
    }
    alarm(0);

    return $sha1->b64digest();
}

sub report {

    my $txt;

    for my $t (values %REGISTRY){
        my $status = $t->{fd} ? 'running' : 'queued';
        $txt .= "$t->{request}{copyid} $status\n";
    }

    return $txt;
}

sub periodic {
    my $quick = shift;

    # how many xfers are running?
    my $nrun = 0;
    for my $t (values %REGISTRY){
        $nrun ++ if $t->{fd};
    }

    return if $quick && $nrun >= $MAXRUNNING;

    # queued? send status, maybe start

    for my $t (sort { $a->{_queueprio} <=> $b->{_queueprio} } values %REGISTRY){
        next if $t->{fd};

        _send_status_update( $t->{request} ) unless $quick;

        if( $nrun < $MAXRUNNING ){
            $t->_start();
            $nrun ++;
        }
    }
}


1;
