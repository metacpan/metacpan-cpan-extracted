#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.
# qsub -hold_jid array_job_id -N name mail.pl

use warnings;
use strict;

use Data::Dumper;
use Carp;
use Mail::Sendmail;

my $address = shift;

my %mail = (
  To      => $address,
  From    => "$ENV{USER}\@$ENV{HOSTNAME}",
  Message => 'Completed job at ' . localtime,
  Subject => "$ENV{JOB_NAME} job_id:$ENV{JOB_ID}/sge_task_id:$ENV{SGE_TASK_ID} COMPLETED",

);
sendmail(%mail) or die $Mail::Sendmail::error;

print STDERR "Mail OK. Log says:\n", $Mail::Sendmail::log, "\n";
