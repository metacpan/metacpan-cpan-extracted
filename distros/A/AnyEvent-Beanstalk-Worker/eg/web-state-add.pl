#!/usr/bin/env perl
use strict;
use warnings;
use AnyEvent::Beanstalk;
use Data::Dumper;

my $bs = AnyEvent::Beanstalk->new
  (server => 'localhost');

$bs->use('urls')->recv;

my $job = $bs->put({ priority => 100,
                     ttr      => 15,
                     delay    => 1,
                     data     => "http://www.uroulette.com/"})->recv;

print STDERR "job added to queue (" . $job->id . "): " . Dumper($job->data);
