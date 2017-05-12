# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 12:29 (EDT)
# Function: file transfers
#
# $Id: Xfer.pm,v 1.2 2011/01/14 22:38:07 jaw Exp $

package AC::MrGamoo::Job::Xfer;
use AC::MrGamoo::Debug 'job_xfer';
use AC::MrGamoo::Config;
use AC::MrGamoo::MySelf;
use AC::Misc;
use strict;

our @ISA = 'AC::MrGamoo::Job::Action';


sub new {
    my $class  = shift;
    my $job    = shift;
    my $info   = shift;
    my $server = shift;

    my $id = unique();

    my $me = bless {
        id	=> $id,
        info	=> $info,
        server	=> $server,
        created => $^T,
    };

    $job->{xfer_pending}{$id} = $me;

    debug("pending xfer $info->{id} => $id on $server");

    return $me;
}

sub start {
    my $me  = shift;
    my $job = shift;

    # send request to server
    my $server   = $me->{server};
    my $filename = $me->{info}{filename};
    debug("starting xfer $me->{id} on $server of $filename");

    my $x = $job->_send_request( $server, "xfer $me->{id}", {
        type		=> 'mrgamoo_filexfer',
        msgidno		=> $^T,
        want_reply	=> 1,
    }, {
        jobid		=> $job->{request}{jobid},
        copyid		=> $me->{id},
        filename	=> $filename,
        dstname		=> ($me->{info}{dstname} || $filename),
        location	=> ($job->{file_info}{$filename}{location} || $me->{info}{location}),
        console		=> $job->{request}{console},
        master		=> my_server_id(),
    } );

    unless( $x ){
        verbose("cannot start xfer");
        $me->failed( $job );
        return;
    }

    # no success cb here. we will either timeout, or get a XferStatus msg.
    $x->set_callback('on_failure', \&_cb_start_xfer_fail, $me, $job );

    $me->started($job, 'xfer');
    $x->start();
}

sub _cb_start_xfer_fail {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;
    my $job = shift;

    $me->failed($job, 'network');
}

# record status rcvd from file xfer
sub update_status {
    my $me   = shift;
    my $job  = shift;
    my $code = shift;

    debug("xfer is $code");

    $me->{status_code} = $code;
    $me->{status_time} = $^T;

    if( $code == 100 ){
        # nop
    }elsif( $code == 200 ){
        $me->finished( $job );
    }else{
        $me->failed( $job, "status $code" );
    }
}

sub failed {
    my $me   = shift;
    my $job  = shift;
    my $why  = shift;

    debug("xfer failed: $why");

    return if $job->something_failed();
    $me->SUPER::failed($job, 'xfer');
    $me->{info}->failed( $me, $job );
    # $job->_try_to_do_something() unless $why eq 'timeout';
}

sub finished {
    my $me   = shift;
    my $job  = shift;

    debug('xfer finish');
    my $server = $me->{server};
    my $file   = $me->{info}{dstname} || $me->{info}{filename};

    $me->SUPER::finished($job, 'xfer');
    $me->{info}->finished( $me, $job );

    # add to server_info.has_files
    # add to file_info, tmp_file

    $job->{server_info}{$server}{has_files}{$file} = 1;
    push @{ $job->{file_info}{$file}{location} }, $server;
    push @{$job->{tmp_file}}, { filename => $file, server => $server };

    my $limit = $job->{plan}{nserver} * 1.5;
    $job->_try_to_do_something()
      if (keys %{$job->{xfer_pending}})
        && (keys %{$job->{xfer_running}} < $limit);	# we go faster, if we can start a few at a time

}


1;
