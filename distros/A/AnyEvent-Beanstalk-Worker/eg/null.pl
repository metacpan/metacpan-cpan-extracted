#!/usr/bin/env perl
use strict;
use warnings;
use feature 'say';

use blib;
use AnyEvent::Beanstalk::Worker;
use AnyEvent;

my $w = AnyEvent::Beanstalk::Worker->new
  ( max_jobs => 10000,
    concurrency => 10000,
    initial_state => 'reserved',
    beanstalk_watch => 'test' );

$w->on(
    reserved => sub {
        my $self = shift;
        my $job  = shift;

        print STDERR "job " . $job->id . " reserved\r";
        $self->finish(delete => $job->id);
    }
);

$w->start;

AnyEvent->condvar->recv;

print STDERR "\n";
