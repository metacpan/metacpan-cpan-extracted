# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Apr-22 13:49 (EDT)
# Function: network requests - delete file, abort task
#
# $Id: Request.pm,v 1.2 2011/01/14 22:38:06 jaw Exp $

package AC::MrGamoo::Job::Request;
use AC::MrGamoo::Debug 'job_request';
use strict;

our @ISA = 'AC::MrGamoo::Job::Action';

sub new {
    my $class = shift;
    my $job   = shift;

    my $me = bless { @_ }, $class;

    $job->{request_pending}{$me->{id}} = $me;
    return $me;
}

sub start {
    my $me  = shift;
    my $job = shift;

    debug("starting request $me->{info}");
    delete $job->{request_pending}{$me->{id}};

    my $x = $job->_send_request( $me->{server}, $me->{info}, $me->{proto}, $me->{request});

    unless( $x ){
        verbose("cannot start request");
        return;
    }

    $x->set_callback('on_success', \&_cb_start_req,  $me, $job, 1);
    $x->set_callback('on_failure', \&_cb_start_req,  $me, $job, 0);

    $job->{request_running}{$me->{id}} = $me;
    $x->start();
}

sub _cb_start_req {
    my $io  = shift;
    my $evt = shift;
    my $me  = shift;
    my $job = shift;
    my $ok  = shift;

    debug("request finished $me->{info}");
    delete $job->{request_running}{$me->{id}};

    $job->_try_to_do_something()
      if $ok
        && (keys %{$job->{request_pending}})
        && (keys %{$job->{request_running}} < 5);	# we go faster, if we can start a few at a time

}

1;
