package BatchSystem::SBS;
use warnings;
use strict;

=head1 NAME

BatchSystem::SBS - a Simple Batch System

=head1 DESCRIPTION

A light, file based batch system.

=head1 SYNOPSIS

=head3 a short example


#edit examples/sbsconfig-examples-1.xml to put your own local machines (it can be a good idea, if you have not a cluster, to enter your local machine with different addresses (localhost, 123.156.78.90, hostname) to see sommething a bit more realistic...

#System status
#in a side term, to see every second the 
watch -n 1 ../scripts/sbs-scheduler-print.pl --config=sbsconfig-examples-1.xml

#to submit or dozen or so scripts on queue 'single'

../scripts/sbs-batch-submit.pl --config=sbsconfig-examples-1.xml  --queue=single --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh

#and on a higher priority queue

../scripts/sbs-batch-submit.pl --config=sbsconfig-examples-1.xml  --queue=single_high --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh  --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh --command=a.sh

#to update

../scripts/sbs-scheduler-update.pl --config=sbsconfig-examples-1.xml

#to check data consistency (and solve main problems

../scripts/sbs-scheduler-check.pl

#to remove a job --config=sbsconfig-examples-1.xml

../scripts/sbs-batch-remove  --config=sbsconfig-examples-1.xml yourjobid


=head3 submiting command

You can submit either comman or scripts.

Script submited on a resource of type 'machine' will be sshed on the host

Once a resource is attributed to a job, the script is transformed, changing the following varaibles (see examples/*.sh)

=over 4

=item $(machinefile} (for cluster type resource)

=item ${nbmachines} (for cluster type resource)

=item ${host} (for machine type resource)

=item ${jobid}

=back 

At submition time, a directory with the job number (incremented integer) is created, where stdout/err will be written.

There will also have a batch.properties file (pids, start time etc. etc.)

=head1 EXPORT


=head1 FUNCTIONS

=head1 METHODS

=head3 my $sbs=BatchSystem::SBS->new();

=head2 Accessors

=head3 $sbs->scheduler

Returns the scheduler (BatchSystem::SBS::DefaultScheduler)

=head3 $sbs->workingDir([$val])

Get set the working directory

=head3 $sbs->

=head3 $sbs->

=head2 Actions


=head3 $sbs->job_submit(command=>cmd, queue=>queuename);

Returns a jobid

=head3 $sbs->job_remove(id=>job_id);

Remove the job from the list, the scheduler, kill processes

=head3 $sbs->job_action(id=>job_id, action=>ACTION);

Send an action to a job. ACTION can be of

=over 4

=item 'KILL': to kill (kill the process if running) one job

=back

=head3 $sbs->job_infoStr(id=>job_id);

Returns a string (or undef if no job exist) with the job info

=head3 $sbs->job_info(id=>job_id);

Returns a hash (or undef if no job exist) with the job info

=head3 $sbs->jobs_dir([clean=>1]);

Get the job directory;

clean=>1 argument will clean the whole job directory

=head3 $sbs->jobs_list()

Returns an n x 4 array (each row contains jobid, queuename, scripts)

=head2 I/O

=head3 $sbs->readConfig(file=>file.xml)

Read its config from an xml file (see examples/ dir)

=head3 $sbs->dataRequest(request=>'req1,req2...')

request data (rpc oriented)

=head1 AUTHOR

Alexandre Masselot, C<< <alexandre.masselot@genebio.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-batchsystem-sbs@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BatchSystem-SBS>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright (C) 2004-2007  Geneva Bioinformatics (www.genebio.com) & Jacques Colinge (Upper Austria University of Applied Science at Hagenberg)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


=cut


use XML::Twig;
use File::Path;
use LockFile::Simple;
use File::Basename;
use File::Copy;
use IO::All;
use Log::StdLog;
use BatchSystem::SBS::DefaultScheduler;
use BatchSystem::SBS::Common qw(lockFile unlockFile);


our $VERSION="0.41";

{
  use Object::InsideOut;

  my @name :Field(Accessor => 'name' );
  my @_configFile :Field(Accessor => '_configFile' );
  my @scheduler :Field(Accessor => 'scheduler');
  my @workingDir :Field(Accessor => 'workingDir');

  our $FHLog;
  my %init_args :InitArgs = (
			    );
  sub _init :Init{
    my ($self, $h) = @_;

  };


  ####################### job

  sub job_submit{
    my $self=shift;
    my %hprms=@_;
    my $cmd=$hprms{command} || $hprms{cmd} || CORE::die "no command argument to job_submit";
    my $queue=$hprms{queue} || CORE::die "no queue argument to job_submit";

    my $jid=$self->__jobs_newid();
    print {*STDLOG} info => "new batch job id [$jid]\n";
    my $dir=$self->jobs_dir()."/$jid";
    print {*STDLOG} info => "job id [$jid]: directory [$dir]\n";

    CORE::die "directory [$dir] already exists" if -d $dir;
    mkdir $dir or CORE::die "cannot mkdir($dir): $!";
    if(-f $cmd){
      my $tmp="$dir/".basename($cmd);
      copy($cmd, $tmp) or CORE::die "cannot copy($cmd, $tmp): $!";
      $cmd=$tmp;
    }
    print {*STDLOG} info => "job id [$jid]: submiting command: $cmd\n";
    $self->scheduler->job_submit(id=>$jid,
				 queue=>$queue,
				 dir=>$dir,
				 command=>$cmd,
				 title=>$hprms{title},
				 on_finished=>$hprms{on_finished},
				);
    print {*STDLOG} info => "job id [$jid]: submited OK\n";
    return $jid;
  }

  sub job_remove{
    my $self=shift;
    my %hprms=@_;
    my $jid=$hprms{id};
    my $isFinished=$hprms{isfinished};
    CORE::die "no id argument to job_remove" unless defined $jid;
    my $deleted=$self->scheduler->job_remove(id=>$jid, isfinished=>$isFinished);
    if($deleted){
      my $dir=$self->jobs_dir()."/$jid";
      rmtree $dir or CORE::die "cannot remove directory [$dir]: $!";
      return 1;
    }else{
      #warn "job [$jid] was not finished\n";
      return 0;
    }
  }

  sub job_action{
    my $self=shift;
    my %hprms=@_;
    my $action=$hprms{action} || CORE::die "no signal argument to job_action";
    my $jid=$hprms{id} ;
    CORE::die "no id argument to job_action" unless defined $jid;

    $self->scheduler->job_action(id=>$jid, action=>$action);
  }

  sub job_infoStr{
    my $self=shift;
    return $self->scheduler->job_info(@_);
  }

  sub job_info{
    my $self=shift;
    return $self->scheduler->job_info(@_);
  }

  ####################### jobs

  sub jobs_dir{
    my $self=shift;
    my %hprms=@_;
    my $d=$self->workingDir()."/list";
    mkdir($d) or CORE::die "cannot mkdir($d)" unless -d $d;
    if($hprms{clean}){
      rmtree($d) || CORE::die "cannot rmtree($d): $!";
      mkdir($d) or CORE::die "cannot mkdir($d)" unless -d $d;
    }
    return $d;
  }


  sub __jobs_newid{
    my $self=shift;
    my %hprms=@_;
    my $f=$self->workingDir()."/jobs-id.txt";
    unless (-f $f){
      open (FD, ">$f") or CORE::die "canot open for writing [$f]: $!";
      print FD "1";
      close FD;
      return "1";
    }
    lockFile("$f") || CORE::die "can't lock [$f]: $!\n"; 
   my $i=io($f)->slurp;
    chomp $i;
    $i++;
    open (FD, ">$f") or CORE::die "canot open for writing [$f]: $!";
    print FD $i;
    close FD;
    unlockFile("$f") || CORE::die "can't unlock [$f]: $!\n";
    return $i;
  }


  ########################## I/O

  sub readConfig{
    my $self=shift;
    my %hprms=@_;


    if ($hprms{file}) {
      my $twig=XML::Twig->new();
      CORE::die "SBS config xml file does not exists" unless -f $hprms{file};
      CORE::die "SBS config xml file is not readable" unless -r $hprms{file};
      $twig->parsefile($hprms{file}) or CORE::die "cannot xml parse file $hprms{file}: $!";
      $self->_configFile($hprms{file});
      return $self->readConfig(twigelt=>$twig->root);
    }
    if (my $rootel=$hprms{twigelt}) {
      foreach (qw(name workingDir)) {
	my $el=$rootel->first_child($_) or CORE::die "must set a /$_ element in xml config file";
	$self->$_($el->text);
      }
      if(my $el=$rootel->first_child('logging')){
	my $fname=$el->first_child('file')->text if $el->first_child('file');
	if($fname){
    mkdir dirname $fname unless -d dirname $fname;
	  unless(open($FHLog, ">>$fname")){
	    die "cannot open log file for appending [$fname]: $!";
	  }
	}else{
	  $FHLog=\*STDERR;
	}
	my $level=$el->first_child('level')?$el->first_child('level')->text:'warn';
	Log::StdLog->import({level=>$level, handle=>$FHLog});
	
      }else{
	#Log::StdLog->import({level=>'warn', handle=>\*STDERR});
      }
      my $el=$rootel->first_child("Scheduler") or CORE::die "no children /Scheduler";
      my $schedulerType=$el->atts->{type} or CORE::die "Scheduler node has not attribute type";
      if($schedulerType eq 'SBS::DefaultScheduler'){
	$self->scheduler(BatchSystem::SBS::DefaultScheduler->new());
	$self->scheduler()->readConfig(twigelt=>$el);
      }else{
	CORE::die "scheduler type=[$schedulerType] is not available";
      }
      return $self;
    }
    CORE::die "neither [file=>] nor [twigelt=>] arg was passed to readConfig";
  }

  sub dataRequest{
    my $self=shift;
    my %hprms=@_;
    my $requests=$hprms{request} or CORE::die "must provide a [request] argument";
    my %reth;
    foreach (split /,/, $requests) {
      if (/^configfile$/i) {
	$reth{configfile}=$self->_configFile();
	next;
      }
      CORE::die "unknown request [$_]";
    }
    return \%reth;
  }
}
1; # End of BatchSystem::SBS
