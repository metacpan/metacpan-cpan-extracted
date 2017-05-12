#
# BioStudio functions for paralellization
#
# SGE commands
#
#$ -l h_rt=14400
#$ -l ram.c=5G
#$ -pe pe_slots 1
#$ -cwd
#$ -V
#$ -P gentech-rnd.p

=head1 NAME

Bio::BioStudio::Parallel

=head1 VERSION

Version 3.00

=head1 DESCRIPTION

=head1 AUTHOR

Sarah Richardson <smrichardson@lbl.gov>.

=cut

package Bio::BioStudio::Parallel;

require Exporter;

use autodie qw(open close);
use IPC::Open2;
use English qw( -no_match_vars );
use base qw(Exporter);

use strict;
use warnings;

our $VERSION = '3.00';

our @EXPORT_OK = qw(
  safeopen
  cleanup
  filedump
  runscript
  assemblecmd
  taskfarm
);
our %EXPORT_TAGS = (BS => \@EXPORT_OK);


=head1 FUNCTIONS

=head2 safeopen

run a command and wait for it to finish. return the output handle as a string.

=cut

sub safeopen
{
  my ($cmd) = @_;
  my ($inh, $outh) = (undef, undef);
  my $pid = open2($outh, $inh, $cmd) || die "oops on $cmd: $OS_ERROR";
  waitpid $pid, 0;
  my $parse = <$outh>;
  return $parse;
}

=head2 cleanup

=cut

sub cleanup
{
  my ($patharr) = @_;
  my @paths = grep {-e $_} @{$patharr};
  foreach my $path (@paths)
  {
    unlink $path;
  }
  return 1;
}

=head2 filedump

Dump a string to a filepath.

=cut

sub filedump
{
  my ($path, $data) = @_;
  open my $FH, '>', $path;
  print {$FH} $data;
  close $FH;
  return;
}

=head2 runscript

given path to executable, a set of arguments as hash, and the file that should
be created on success, run a command

=cut

sub runscript
{
  my ($script, $args, $nextfile) = @_;
  my $command = assemblecmd($script, $args);
  safeopen($command);

  if (! -e $nextfile)
  {
    my $errormsg = "\nBSERROR: No $nextfile result! Dying.\n";
    croak $errormsg;
  }
  return 1;
}

=head2 assemblecmd

given a path to an executable and a set of arguments as a hash, generate a
command

=cut

sub assemblecmd
{
  my ($script, $args) = @_;
  my $command = $script;
  my @flags = sort keys %{$args};
  foreach my $flag (@flags)
  {
    $command .= q{ -} . $flag . q{ } . $args->{$flag};
  }
  return $command;
}

=head2 taskfarm

given a list of tasks and a job name, start a bunch of taskfarmer workers and a
client

=cut

sub taskfarm
{
  my ($jobstr, $jobname, $key, $nodes) = @_;

  $nodes = $nodes || 16;
  my @CLEANUP;
  my $tmp_path = Bio::BioStudio::ConfigData->config('tmp_path');
  my $tmp_pref = $tmp_path . $key;
  my $SGEFLAGS = "-l ram.c=5.25G -pe pe_fill $nodes -cwd -V";
  # Create the queue file that lists the tasks for the queue
  #
  my $queuefile = $tmp_pref  . '_tasklist_' . $jobname . '.txt';
  filedump($queuefile, $jobstr);
  push @CLEANUP, $queuefile;

  # Create worker request files that create workers for the queue.
  #
  my $workerfile = $tmp_pref . '_worker_' . $jobname . '.sh';
  my $queuename = $jobname . '_queue';
  my $workercmd = "\#!/bin/bash -l\nmpirun -n $nodes ";
  $workercmd .= "tfmq-worker -q $queuename\n";
  filedump($workerfile, $workercmd);
  push @CLEANUP, $workerfile;

  # Submit the request for the workers and capture the sge job id.
  #
  my $jname = $jobname;
  my $workerqsub = "qsub $SGEFLAGS -N $jname ";
  $workerqsub .= '-o ' . $tmp_path . $jobname . q{_o\$JOB_ID.txt };
  $workerqsub .= '-e ' . $tmp_path . $jobname . q{_e\$JOB_ID.txt };
  $workerqsub .= $workerfile;
  my $workerparse = safeopen($workerqsub);

  # Start a client. Capture the job id and wait for completion.
  #
  my $clientcmd = "tfmq-client -i $queuefile -q $queuename";
  safeopen($clientcmd);

  return \@CLEANUP;
}

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2015, BioStudio developers
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

* The names of Johns Hopkins, the Joint Genome Institute, the Joint BioEnergy 
Institute, the Lawrence Berkeley National Laboratory, the Department of Energy, 
and the BioStudio developers may not be used to endorse or promote products 
derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE DEVELOPERS BE LIABLE FOR ANY DIRECT, INDIRECT,
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut