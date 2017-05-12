package BatchSystem::SBS::DefaultScheduler;
use warnings;
use strict;
use English;

=head1 NAME

BatchSystem::SBS::DefaultScheduler - a scheduler for the Simple Batch System

=head1 DESCRIPTION

A light, file based batch system.

=head1 SYNOPSIS



=head1 EXPORT


=head1 FUNCTIONS

=head3 scheduling_methodList()

return an array with the name of the different methods

=head1 METHODS

=head3 my $scheduler=BatchSystem::SBS::DefaultScheduler->new();

=head2 Accessors

=head3 $scheduler->

=head2 Misc

=head3 $scheduler->__lockdata()

Lock joblist and resourcedata dump files at once

=head3 $scheduler->__unlockdata()

Unlock joblist and resourcedata dump files at once

=head2 Job action

=head3 $scheduler->job_submit(id=>val, dir=>dir, command=>cmd, queue=>queue)

=head3 $scheduler->job_status(id=>val [,status=>STATUS])

=head3 $scheduler->job_remove(id=>val)

Remove the job #jobid from the list (maybe kill its processe if running

=head3 $scheduler->job_signal(id=>val, signal=>SIG)

Send a signal to a running job

=head3 $scheduler->job_action(id=>val, action=>ACTION)

Send an action to a registered job.

ACTION can be of

=over 4

=item KILL kill the processe or just take the joib out of the queue is it is PENDING

=back

=head3 $scheduler->job_info(id=>val);

returns a hash ref to all the info on the job

=head3 $scheduler->job_infoStr(id=>val);

returns a simple string with a job info

=head3 $sheduler->job_properties(id=>val);

Return a reference to a Util::Properties object, stored into a "batch.properties" files in the job directory;

=head3 $sheduler->job_execute(id=>val);


=head3 $sheduler->__job_execute_scriptmorfer(id=>val, script=>scriptfile)

It is an internal command that transform the submit script (if it was not just a command) into the ready to execute script.

It meas that it will replace expression with the runtime value

=over 4

=item ${jobid}

=item ${machinefile}

=item ${host}

=item ${queue}

=back


=head2 Jobs List action

=head3 $sbs->joblist_index();

Return the job list index file

=head3 $sbs->joblist_size();

return number of jobs in the joblist

=head3 $scheduler->__joblist_dump();

Write the joblist on disk

=head3 $scheduler->__joblist_pump();

Read the joblist from the disk


=head2 Resources

All what concerns the machine & cluster ready to make computations

=head3 $scheduler->resources_check()

Make a coherence check of the resources status (if a resource is attributed to a dead job, for example, it will be freed). This should not be called, except to solve some spurious locking problems - that shoould anyway not exist anymore...

=head3 $scheduler->resources_removenull()

remove null ID job (well, that's not the cleverest piece of code design...)

=head3 $scheduler->resourcesStatus_init()

Synchronize resources defined in the configuration with the one in resourcesStatus()


=head3 $scheduler->__resourcesStatus_dump();

Write the resourcesStatus on disk

=head3 $scheduler->__resourcesStatus_pump();

Read the resourcesStatus from the disk


=head2 Scheduling

=head2 $scheduler->scheduling_update()

Run a scheduler->scheduling_next_reserve() + a submition on returned jobs

=head3 $scheduler->scheduling_method(name)

Set the scehduling method (see BatchSystem::SBS::DefaultScheduler::scheduling_methodList() to have a list of all possible methods)

Scheduling method sorting methods take a list of pending jobs an reorder them by priority (warning: it may happen that the returned list is shorter than the input one (in case there is a limit on the number of submission for one queue, for example).


Scheduling available are:

=over 4

=item fifo

First in/first out

=item lifo

Last in /first out (better be late)

=item random

=item priorityfifo

Based on priority & fifo

=item prioritylimit

based on priority + fifo + maxConcurentJob per queues (if a queue is generated via a regular expression, eaxch queue is counted separately).

=back

=head3 scheduler->scheduling_next_reserve()

Find the next job to be submited, according to the scheduling method_name. It does not start the job, but status it as READY, and reserve the resourceStatus and attribute it the job id

=head2 Queues

=head3 $scheduler->queues_check()

Make a tour of the queue and see that if they are attributed to a job, the job is no ended...

=head3 $scheduler->__queues_exist($qname)

Check if the queue exists. It is not straight forwards because of queue that can be dynamically defined at runtime. In this case, regexp must be checked, and queue duplicated...

For example, if a queue was defined in the config file with name "default_user_\w+", it will be possible to submit to queues "default_user_joe", "default_user_jack" etc. These queues will be dynamically created when $scheduler->__queues_exist($qname) is called


=head3 $scheduler->__queue_validResource($qname, \%resource)

Check if the given resource correspond to the queue needs

=head3 $scheduler->__queue_insert(job=>\%job, queue=>$queuename, resourceStatus=\%resourceStatus);

Insert a job in a queue, deal with all labeling, queue counter etc. etc. 


=head3 $scheduler->__queue_remove(job=>\%job [, jobstatus=>(COMPLETED|ERROR)]);

Remove a job from a queue, deal with all labeling, queue counter etc. etc. 

Default jobstatus is EXIT

=head2 Queues status

stores the queuse status (last acession time...)

=head3 $scheduler->queuesStatus_init()

Synchronize data with dump file


=head2 IO

=head3 $scheduler->readConfig(twigelt=>XML::Twig::Elt)

Read its config from an xml file (see examples/ dir)

=head3 overloading "$scheduler"

just a call to $scheduler->toString()

=head3 $scheduler->toString([skip_joblist=>1],[,skip_resources=>1][,skip_resourcesStatus=>1]

Returns a string with the status for the different components

=head3 $scheduler->dataRequest(request=>'req1,req2...')

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

Copyright (C) 2004-2006  Geneva Bioinformatics (www.genebio.com) & Jacques Colinge (Upper Austria University of Applied Science at Hagenberg)

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

use Carp;
use Data::Serializer;
use File::Basename;
use List::Util qw(first max maxstr min minstr reduce shuffle sum);;
use Util::Properties;
use POSIX ":sys_wait_h";
use Errno qw(EAGAIN);
use Log::StdLog;

our $FHLOG_SCHEDULER;
use BatchSystem::SBS::Common qw(lockFile unlockFile);

my @__joblist :Field(Accessor => '__joblist', 'Type' => 'Hash', Permission => 'private');
my @__resources :Field(Accessor => '__resources', 'Type' => 'Hash', Permission => 'private');
my @__resourcesStatus :Field(Accessor => '__resourcesStatus', 'Type' => 'Hash', Permission => 'private');
my @__queues :Field(Accessor => '__queues', 'Type' => 'Hash', Permission => 'public');
my @__queuesStatus :Field(Accessor => '__queuesStatus', 'Type' => 'Hash', Permission => 'private');
#the list of queue names that where declared at start (check for regular exepression);
my @__queues_orig :Field(Accessor => '__queues_orig', 'Type' => 'HASH', Permission => 'private');
my @__autoupdate :Field(Accessor => '__autoupdate', Permission => 'private');
my @__autoremove :Field(Accessor => '__autoremove', Permission => 'private');

my @joblist_index :Field(Accessor => 'joblist_index');
my @resourcesStatus_index :Field(Accessor => 'resourcesStatus_index');
my @queuesStatus_index :Field(Accessor => 'queuesStatus_index');

my @__jobs_properties  :Field(Accessor => '__jobs_properties', 'Type' => 'Hash', Permission => 'private');

my @__scheduling_method :Field(Accessor => '__scheduling_method', Permission => 'private');
my @__scheduling_methodName :Field(Accessor => '__scheduling_methodName', Permission => 'private');

our $__serializer=Data::Serializer->new(
					serializer => 'Storable',
				       );

our $FINISHED_JOB_STATUS=qr/^(COMPLETED|EXIT|KILLED|ERROR)$/i;
our $RUNNING_JOB_STATUS=qr/^(RESERVED|RUNNING)$/i;

{
  use Object::InsideOut;
  my %init_args :InitArgs = (
			    );
  sub _init :Init{
    my ($self, $h) = @_;
    $self->__joblist({});
    $self->__jobs_properties({});
    $self->__queues_orig({});
  };

  #Automethod:
  #__(joblist|resourcesStatus)_(un)?lock
  #for locking/unlocking the joblist and resourcesStatus dump files
  #__(joblist|resourcesStatus)_(p|d)ump
  #for serializing oblist and resourcesStatus to/from a dump file
  use Carp qw(cluck);
  sub _automethod :Automethod{
    my $self=shift;
    my %hprms=@_;

    my $name=$_;
    if ($name=~/__(joblist|resourcesStatus|queuesStatus)_dump/) {
      my $topic=$1;
      return sub{
	my $nolock=$hprms{nolock};
	$self->__lockdata unless $nolock;
	my $meth1="__".$topic;
	my $meth2=$topic."_index";
	$__serializer->store($self->$meth1(), $self->$meth2()) or CORE::die "dying trying to store __$topic: $!";
	$self->__unlockdata unless $nolock;
	return $self;

	#	my $meth="$topic"."_index";
	#	my $f=$self->$meth();
	#	return $__file_locker->unlock($f) or confess "cannot lock $f: $!";
      }
    } elsif ($name=~/__(joblist|resourcesStatus|queuesStatus)_pump/) {
      my $topic=$1;
      return sub{
	my $nolock=$hprms{nolock};
	$self->__lockdata unless $nolock;
	my $meth1="__".$topic;
	my $meth2=$topic."_index";
	my $f=$self->$meth2();

	if (-f $f) {
	  my $a=$__serializer->retrieve($f) or CORE::die "dying trying to retrieve __$topic in [$f]: $!";
	  $self->$meth1($a);
	} else {
	  $self->$meth1({});
	}
	$self->__unlockdata unless $nolock;
	return $self;
      }
    }
  };
  ########################## ACTIONS

  #locking
  sub __lockdata{
    my $self=shift;
    my %hprms=@_;
    my $f=dirname($self->joblist_index())."/data.locker";
    lockFile($f) or confess "cannot lock $f: $!";
  }
  sub __unlockdata{
    my $self=shift;
    my %hprms=@_;
    my $f=dirname($self->joblist_index())."/data.locker";
    unlockFile($f) or confess "cannot lock $f: $!";
  }


  ############### JOB
  sub job_submit{
    my $self=shift;
    my %hprms=@_;
    my $cmd=$hprms{command} || $hprms{cmd} || CORE::die "no command argument to job_submit";
    my $dir=$hprms{dir} || CORE::die "no dir argument to job_submit";
    my $queue=$hprms{queue} || CORE::die "no queue argument to job_submit";
    my $id=$hprms{id};
    CORE::die "no id argument to job_submit" unless defined $id;
    CORE::die "directoy for job ($id) [$dir] does not exist" unless -d $dir;
    CORE::die "queue [$queue] doe not exist " unless $self->__queues_exist($queue);

    print {*STDLOG} info => "job id [$id]: DefaultScheduler submiting to queue [$queue]\n";
    $self->__lockdata();
    $self->__joblist_pump(nolock=>1);
    carp "CANNOT ADD job [$id]: already exist" if exists $self->__joblist()->{$id};
    $self->__joblist()->{$id}={
			       id=>$id,
			       command=>$cmd,
			       queue=>$queue,
			       title=>$hprms{title},
			       dir=>$dir,
			       on_finished=>$hprms{on_finished},
			       status=>'PENDING',
			       resource=>undef,
			      };
    $self->__joblist_dump(nolock=>1);
    $self->__unlockdata();
  }

  sub job_remove{
    my $self=shift;
    my %hprms=@_;
    my $id=$hprms{id};
    my $isFinished=$hprms{isfinished};

    print {*STDLOG} info => "job id [$id]: trying removed\n";
    CORE::die "no id argument to job_remove" unless defined $id;

    $self->__lockdata();
    $self->__joblist_pump(nolock=>1);
    unless (exists $self->__joblist()->{$id}) {
      warn "CANNOT REMOVE job [$id]: does not exist";
      $self->__unlockdata();
      return 0;
    }
    my $job=$self->__joblist()->{$id};
    if($isFinished && $job->{status}!~$FINISHED_JOB_STATUS){
      warn "CANNOT REMOVE job [$id]: not finished";
      $self->__unlockdata();
      return 0;
    }

    if($job->{status}=~$RUNNING_JOB_STATUS){
      $self->job_signal(id=>$id, signal=>'KILL');
    }
    if ($job->{resource}) {
      $self->__resourcesStatus_pump(nolock=>1);
      $self->__queuesStatus_pump(nolock=>1);

      $self->__queue_remove(job=>$job);
      $self->__queuesstatus_touch(queue=>$job->{queue});
      $job->{status}='KILLED';

      $self->__queuesStatus_dump(nolock=>1);
      $self->__resourcesStatus_dump(nolock=>1);
    }
    print {*STDLOG} info => "job id [$id]: removed\n";
    delete $self->__joblist()->{$id};
    $self->__joblist_dump(nolock=>1);
    $self->__unlockdata();
    return 1;
  }

  sub job_action{
    my $self=shift;
    my %hprms=@_;
    my $action=$hprms{action} || CORE::die "no signal argument to job_action";
    my $id=$hprms{id};
    CORE::die "no id argument to job_action" unless defined $id;
    $self->__lockdata();
    $self->__joblist_pump(nolock=>1);
    if ($action eq 'KILL') {
      if ($self->__joblist->{$id}{status}=~$FINISHED_JOB_STATUS) {
	#nothing to be done
	warn "not anymore possible to KILL batch [$id] with status [".$self->__joblist->{$id}{status}."]";
      } else {
	warn "killing batch [$id]\n";
	my $job=$self->__joblist()->{$id};
	$self->job_signal(id=>$id, signal=>'KILL');
	if ($job->{resource}) {
	  $self->__resourcesStatus_pump(nolock=>1);
	  $self->__queue_remove(job=>$job, jobstatus=>'KILLED');
	  $self->__resourcesStatus_dump(nolock=>1);
	}
	$job->{status}='KILLED';
      }
    } elsif($action=~/^STATUS:(\w+)$/){
      my $st=$1;
      print {*STDLOG} info => "job id [$id]: change status to [$st]\n";
      $self->__joblist->{$id}{status}=$st;
    }else {
      $self->__joblist_dump(nolock=>1);
      $self->__unlockdata();
      CORE::die "no action registered for [$action]";
    }
    $self->__joblist_dump(nolock=>1);
    $self->__unlockdata();

  }
  sub job_signal(){
    my $self=shift;
    my %hprms=@_;
    my $signal=$hprms{signal} || CORE::die "no signal argument to job_signal";
    my $id=$hprms{id};
    CORE::die "no id argument to job_signal" unless defined $id;

    my $pids=$self->job_properties(id=>$id)->prop_get('pids');
    if ($pids && $pids=~/\S/) {
      print STDERR "job [$id] kill $signal $pids\n";
      kill $signal, split /\s+/, $pids;
    }
  }

  sub job_infoStr{
    my $self=shift;
    my %hprms=@_;
    my $id=$hprms{id};
    CORE::die "no id argument to job_submit" unless defined $id;
    my $j=$self->__joblist->{$id};

    return undef unless defined $j;
    return "$j->{id}\t$j->{status}\t$j->\t".($j->{resource} or '')."\t$j->{command}\n";
  }

  sub job_info{
    my $self=shift;
    my %hprms=@_;
    my $id=$hprms{id};
    CORE::die "no id argument to job_submit" unless defined $id;
    my $j=$self->__joblist->{$id};

    return undef unless defined $j;
    my %h=%$j;
    return wantarray?%h:\%h;
  }

  sub job_properties{
    my $self=shift;
    my %hprms=@_;
    CORE::die "no id argument to job_properties" unless defined $hprms{id};
    my $id=$hprms{id};
    return $self->__jobs_properties->{$id} if defined $self->__jobs_properties->{$id};
    my $pfile=$self->__joblist->{$id}{dir}."/batch.properties";
    my $prop=Util::Properties->new();
    $prop->file_isghost(1);
    $prop->file_name($pfile);
    return $self->__jobs_properties->{$id}=$prop;
  }

  sub job_execute{
    my $self=shift;
    my %hprms=@_;
    CORE::die "no id argument to job_execute" unless defined $hprms{id};
    my $id=$hprms{id};
    print {*STDLOG} info => "job id [$id]: DefaultScheduler executing\n";
    my $job=$self->__joblist->{$id} or CORE::die "no job defined for if [$id]";
    my $dir=$job->{dir};

    my $cmd;
    my $isScript;
    if (-f $job->{command}) {
      $cmd=$self->__job_execute_scriptmorfer(id=>$id, script=>$job->{command});
      if($OSNAME=~/win/i){
	if($job->{command}=~/pl$/){
	  $cmd="cmd /C $^X $cmd";
	}else{
	  $cmd="cmd /C $cmd";
	}
      }else{
	unless (-x $cmd){
	  if($job->{command}=~/pl$/){
	    $cmd="$^X $cmd";
	  }else{
	    $cmd="sh $cmd";
	  }
	}
      }
    } else {
      $cmd=$job->{command};
    }
    print {*STDLOG} info => "job id [$id]: DefaultScheduler command [$cmd]\n";
    my $prop=$self->job_properties(id=>$id);
    my $date=CORE::localtime(time);
    $prop->prop_set('start.time', $date);

    #    print STDERR "TODO job_execute: management std(out|err)\n";
    $cmd.=" 1>$dir/stdout 2>$dir/stderr";

    my $queueName=$job->{queue}or CORE::die "cannot __job_execute_scriptmorfer on a job ($id) with no attributed queue";
    my $queue=$self->__queues->{$queueName};
    print {*STDLOG} info => "job id [$id]: DefaultScheduler queue [$queueName]\n";

    my $rtype=$queue->{resource}{type};
    my $mfile=$self->__resources->{$rtype}{$job->{resource}}{machineFile};
    my $host=$self->__resources->{$rtype}{$job->{resource}}{host};
    $cmd="ssh $host $cmd" if $host and $host ne 'localhost';

    #let's rock
  FORK:{
      my $pid;
      if ($pid=fork) {
	$self->__lockdata();
	$self->__joblist_pump(nolock=>1);
	$self->__queuesStatus_pump(nolock=>1);
	my $job=$self->__joblist->{$id};
	unless($self->__joblist->{$id}{status}=~$FINISHED_JOB_STATUS){
	  $job->{status}='RUNNING';
	}
	print {*STDLOG} info => "job id [$id]: status RUNNING\n";
	$self->__queuesstatus_touch(queue=>$job->{queue});
	$self->__queuesStatus_dump(nolock=>1);
	$self->__joblist_dump(nolock=>1);
	$self->__unlockdata();
	my $pids=$prop->prop_get('pids');
	$pids.=" " if $pids;
	$pids.=$pid;
	$prop->prop_set('pids', $pids);
	print {*STDLOG} info => "job id [$id]: DefaultScheduler running with pid [$pid]\n";

	#	if($self->__autoupdate()){
	#	  waitpid($pid, 0);
	#	  $self->scheduling_update;
	#	}
      } elsif (defined $pid) {
	if (system $cmd) {
	  $self->__lockdata();
	  $self->__joblist_pump(nolock=>1);
	  $self->__resourcesStatus_pump(nolock=>1);
	  $self->__queuesStatus_pump(nolock=>1);

	  my $job=$self->__joblist->{$id};
	  $self->__queue_remove(job=>$job, jobstatus=>'ERROR');
	  print {*STDLOG} info => "job id [$id]: status ERROR\n";
	  $self->__queuesstatus_touch(queue=>$job->{queue});

	  $self->__queuesStatus_dump(nolock=>1);
	  $self->__resourcesStatus_dump(nolock=>1);
	  $self->__joblist_dump(nolock=>1);
	  $self->__unlockdata();

	  $self->scheduling_update if $self->__autoupdate();
	} else {
	  $self->__lockdata();
	  $self->__joblist_pump(nolock=>1);
	  $self->__resourcesStatus_pump(nolock=>1);
	  $self->__queuesStatus_pump(nolock=>1);

	  my $job=$self->__joblist->{$id};
	  $self->__queue_remove(job=>$job, jobstatus=>'COMPLETED');
	  print {*STDLOG} info => "job id [$id]: status COMPLETED\n";
	  $self->__queuesstatus_touch(queue=>$job->{queue});

	  $self->__queuesStatus_dump(nolock=>1);
	  $self->__resourcesStatus_dump(nolock=>1);
	  $self->__joblist_dump(nolock=>1);
	  $self->__unlockdata();

	  $self->scheduling_update if $self->__autoupdate();
	  $self->job_remove(id=>$id) if $self->__autoremove();
	}
	exit 0;
      } elsif ($! == EAGAIN) {
	sleep 3;
	redo FORK;
      } else {
	return -1;
      }
    }
  }

  sub __job_execute_scriptmorfer{
    my $self=shift;
    my %hprms=@_;
    CORE::die "no id argument to __job_execute_scriptmorfer" unless defined $hprms{id};
    my $id=$hprms{id};
    my $script=$hprms{script} or CORE::die "no script argument to __job_execute_scriptmorfer";
    CORE::die "[$script] is not a fil" unless -f $script;
    my $contents;
    {
      local $/;
      open (FD, "<$script") or CORE::die "cannot open for reading [$script]";
      $contents=<FD>;
      close FD;
    }

    $contents=~s/\$\{jobid\}/$id/gi;
    my $job=$self->__joblist->{$id};
    my $queueName=$job->{queue}or CORE::die "cannot __job_execute_scriptmorfer on a job ($id) with no attributed queue";
    $contents=~s/\$\{queue\}/$queueName/gi;
    my $queue=$self->__queues->{$queueName};
    my $rtype=$queue->{resource}{type};
    my $mfile=$self->__resources->{$rtype}{$job->{resource}}{machineFile} || '';
    $contents=~s/\$\{machinefile\}/$mfile/gi ;
    my $host=$self->__resources->{$rtype}{$job->{resource}}{host} || '';
    $contents=~s/\$\{host\}/$host/gi;

    if (my $p=$self->__resources->{$rtype}{$job->{resource}}{properties}){
      foreach (keys %$p){
	$contents=~s/\$\{resource\.properties\.$_\}/$p->{$_}/gi;
      }
    }
    $contents=~s/\$\{[\w\.]+\}//g;


    my $nbnodes=0;
    if ($mfile) {
      open (FH, "<$mfile") or CORE::die "cannot open machinefile $mfile: $!";
      while (<FH>) {
	chomp;
	s/#.*//;
        next unless /\S/;
	$nbnodes++;
      }
      close FH;
      $contents=~s/\$\{nbmachines\}/$nbnodes/gi ;
    }
    my $run="$script.run";
    open (FD, ">$run") or CORE::die "cannot open for writing [$run]";
    print FD $contents;
    close FD;
    return $run;
  }

  ############### JOBLIST

  sub joblist_size(){
    my $self=shift;
    return scalar(keys %{$self->__joblist()});
  }


  ############## resources

  sub resourcesStatus_init{
    my $self=shift;
    my %hprms=@_;
    $self->__lockdata();
    if ($hprms{reset}) {
      $self->__resourcesStatus({});
    } else {
      $self->__resourcesStatus_pump(nolock=>1);
    }
    my $rsc=$self->__resources();
    my $rscStatus=$self->__resourcesStatus();
    #check for not existing resource status entries
    while (my($t, $ht)=each %$rsc) {
      while (my($n, $htn)=each %$ht) {
	if (exists $rscStatus->{$t}{$n}) {
	  $rscStatus->{$t}{$n}{__VISITED__}=1;
	} else {
	  $rscStatus->{$t}{$n}={
				type=>$t,
				name=>$n,
				status=>'AVAIL',
				job_id=>undef,
				__VISITED__=>1,
			       }
	}
      }
    }
    #check for  existing resource status entries  ont corresponding to a resource entry
    while (my($t, $ht)=each %$rscStatus) {
      while (my($n, $htn)=each %$ht) {
	if (exists $htn->{__VISITED__}) {
	  delete $htn->{__VISITED__};
	} else {
	  delete $rscStatus->{$t}{$n};
	}
      }
    }
    $self->__resourcesStatus($rscStatus);
    $self->__resourcesStatus_dump(nolock=>1);
    $self->__unlockdata();
  }

  sub resources_check{
    my $self=shift;

    $self->__lockdata();
    $self->__joblist_pump(nolock=>1);
    $self->__resourcesStatus_pump(nolock=>1);
    my $rscStatus=$self->__resourcesStatus();
    foreach my $t (sort keys %$rscStatus) {
      my $ht=$rscStatus->{$t};
      foreach my $n ( sort keys %$ht) {
	my $htn=$ht->{$n};
	my $jid=$htn->{job_id};
	if (defined $jid) {
	  if (! exists $self->__joblist()->{$jid}) {
	    print STDERR "WARNING! resource [$n] is attributed to job [$jid], but this job does not exist anymore\n(releasing resource)\n";
	    undef $htn->{job_id};
	    $htn->{status}='AVAIL';
	  } elsif ($self->__joblist()->{$jid}{status}!~$RUNNING_JOB_STATUS) {
	    print STDERR "WARNING! resource [$n] is attributed to job [$jid], but this job status is [".$self->__joblist()->{$jid}{status}."]\n(releasing resource)\n";
	    undef $htn->{job_id};
	    $htn->{status}='AVAIL';
	    if ($self->__joblist()->{$jid}{status} eq 'READY') {
	      $self->__joblist()->{$jid}{status}='PENDING';
	    }
	  } else {
	    #job has a runn status
	    my $pids=$self->job_properties(id=>$jid)->prop_get('pids');
	    if ($pids=~/\S/) {
	      my $cmdps="ps --no-headers $pids";
	      unless (`$cmdps`=~/\S/){
		print STDERR "WARNING! resource [$n] is attributed to job [$jid], supposing to run pids [$pids] while $cmdps returns nothing\n(releasing resource)\n";
		undef $htn->{job_id};
		$htn->{status}='AVAIL';
		$self->__joblist()->{$jid}{status}='EXIT';
	      }
	    }
	  }
	}
      }
    }
    $self->__resourcesStatus_dump(nolock=>1);
    $self->__joblist_dump(nolock=>1);
    $self->__unlockdata();
  }

  sub resources_removenull{
    my $self=shift;

    $self->__lockdata();
    $self->__joblist_pump(nolock=>1);
    $self->__resourcesStatus_pump(nolock=>1);
    my $hjl=$self->__joblist();
    foreach (sort {$b <=> $a} keys %$hjl) {
      unless($hjl->{$_}{id}){
	warn "null job id defined for [$_]";
	delete $self->__joblist()->{$_};
      }
    }
    $self->__resourcesStatus_dump(nolock=>1);
    $self->__joblist_dump(nolock=>1);
    $self->__unlockdata();
  }



  ############## check coherence

  ########################## scheduling

  my %schedulingSortSub=(
			 fifo=>sub {$_[0]->__scheduling_sort_fifo($_[1])},
			 lifo=>sub {$_[0]->__scheduling_sort_lifo($_[1])},
			 random=>sub {$_[0]->__scheduling_sort_random($_[1])},
			 priorityfifo=>sub {$_[0]->__scheduling_sort_priorityfifo($_[1])},
			 prioritylimit=>sub {$_[0]->__scheduling_sort_prioritylimit($_[1])},
			);

  sub scheduling_methodList{
    return sort keys %schedulingSortSub;
  }

  sub scheduling_method{
    my $self=shift;
    my $set=$_[0];
    my $val=shift;
    if ($set) {
      CORE::die "no schedulingSub for method name [$val]: possible are:(".join('|', scheduling_methodList()).")" unless $schedulingSortSub{$val};
      $self->__scheduling_method($schedulingSortSub{$val});
      $self->__scheduling_methodName($val);
    }
    return $self->__scheduling_methodName;
  }


  sub scheduling_update{
    my $self=shift;
    my @readids=$self->scheduling_next_reserve();
    foreach (@readids) {
      $self->job_execute(id=>$_);
    }
  }

  sub scheduling_next_reserve{
    my $self=shift;
    my ($pendingJobs, $availResources)=$self->__scheduling_next_common_start();
    unless(scalar(@$pendingJobs) && scalar(@$availResources)){
      $self->__scheduling_next_common_end();
      return ();
    }

    my @sortedjobs=$self->__scheduling_method()->($self, $pendingJobs);
    my $nbAvailResources=scalar(@$availResources);
    my @submited;
    foreach my $job (@sortedjobs) {
      my $qname=$job->{queue};
      foreach my $rsc (@$availResources) {
	next unless $rsc->{status}=~/^(AVAIL)$/;
	if ($self->__queue_validResource($qname, $rsc)) {
	  $self->__queue_insert(queue=>$qname, job=>$job, resourceStatus=>$rsc);
	  $nbAvailResources--;
	  push @submited, $job->{id};
	  last;
	} else {
	}
      }
      last unless $nbAvailResources;
    }
    $self->__scheduling_next_common_end();
    return @submited;
  }

  ############## scheduling methods

  sub __scheduling_next_common_start(){
    my $self=shift;
    $self->__lockdata();
    $self->__resourcesStatus_pump(nolock=>1);
    $self->__joblist_pump(nolock=>1);
    $self->__queuesStatus_pump(nolock=>1);
    my $h=$self->__joblist();
    my @pendingJobs;
    foreach (values(%{$self->__joblist()})) {
      if ($_->{status}=~/^(PENDING)$/) {
	if (defined $_->{on_finished}) {
	  my $iddep=$_->{on_finished};
	  if ($self->__joblist->{$iddep}{status}=~$FINISHED_JOB_STATUS) {
	    push @pendingJobs, $_;
	  }
	} else {
	  push @pendingJobs, $_ ;
	}
      }
    }
    my @availResources;
    my $rscStatus=$self->__resourcesStatus();
    while (my($t, $ht)=each %$rscStatus) {
      foreach (values(%$ht)) {
	push @availResources, $_ if $_->{status}=~/^(AVAIL)$/;
      }
    }
    #rebuild the list of queues
    my %qname;
    foreach (@pendingJobs) {
      my $n=$_->{queue};
      next if $qname{$n};
      CORE::die "queue [$n] does not exists" unless $self->__queues_exist($n);
      $qname{$n}=1;
    }
    return (\@pendingJobs, \@availResources);
  }

  sub __scheduling_next_common_end(){
    my $self=shift;
    $self->__resourcesStatus_dump(nolock=>1);
    $self->__joblist_dump(nolock=>1);
    $self->__queuesStatus_dump(nolock=>1);
    $self->__unlockdata();
  }



  ############## dedicated scheduler sorting method

  sub __scheduling_sort_fifo{
    my $self=shift;
    my $in_pendingJobs=shift;
    my @tmp=sort {$a->{id}<=>$b->{id}} @$in_pendingJobs;
    return @tmp;
  }
  sub __scheduling_sort_lifo{
    my $self=shift;
    my $in_pendingJobs=shift;
    my @tmp=sort {$b->{id}<=>$a->{id}} @$in_pendingJobs;
    return @tmp;
  }
  sub __scheduling_sort_random{
    my $self=shift;
    my $in_pendingJobs=shift;
    my @tmp=shuffle @$in_pendingJobs;
    return @tmp;
  }
  sub __scheduling_sort_priorityfifo{
    my $self=shift;
    my $in_pendingJobs=shift;
    my $queues=$self->__queues;
    my @tmp=sort {__scheduling_sort_priorityfifo_cmp($a, $b, $queues)} @$in_pendingJobs;;
    return @tmp;
  }
  sub  __scheduling_sort_priorityfifo_cmp{
    my ($ja, $jb, $queues)=@_;
    my $prio_a=$queues->{$ja->{queue}}->{priority};
    my $prio_b=$queues->{$jb->{queue}}->{priority};
    return (0<=>1) if (!defined $prio_a) && (!defined $prio_b);
    return (0<=>1) unless defined $prio_a;
    return (1<=>0) unless defined $prio_b;
    if ($prio_a eq $prio_b) {
      return $ja->{id} <=> $jb->{id};
    } else {
      return $prio_b <=> $prio_a;
    }
  }
  sub __scheduling_sort_prioritylimit{
    my $self=shift;
    my $in_pendingJobs=shift;
    my $queues=$self->__queues;
    my @tmp=sort {__scheduling_sort_priorityfifo_cmp($a, $b, $queues)} @$in_pendingJobs;

    #count how many job are in each queues;
    my %cptQJob;
    my $rscStatus=$self->__resourcesStatus();
    my $hjl=$self->__joblist();
    foreach my $ht (values %$rscStatus) {
      foreach my $htn (values %$ht) {
	if (defined $htn->{job_id}) {
	  my $jid=$htn->{job_id};
	  $cptQJob{$hjl->{$jid}{queue}}++;
	}
      }
    }
    my @idx;
    my $i=0;
    my $curQPrio;
    my %curQlist;
    my $qstatus=$self->__queuesStatus();
    my @ret;
    foreach my $itmp (0..$#tmp) {
      my $q=$tmp[$itmp]->{queue};
      if (($itmp==$#tmp) || ((defined $curQPrio) && ($curQPrio ne $queues->{$q}{priority}))) {
	#add the last element if we are at the last element
	if ($itmp==$#tmp ) {
	  unless ($queues->{$q}->{maxConcurentJob} && ($cptQJob{$q}||0)>$queues->{$q}->{maxConcurentJob}) {
	    push @{$curQlist{$q}}, $tmp[$itmp];
	  }
	  undef $curQPrio;
	}

	#then we have a ring of queue in @curQPrio;
	my @curRing=sort {($qstatus->{$a}{accesstime}||0) <=> ($qstatus->{$b}{accesstime}||0)} keys %curQlist;
	while (@curRing) {
	  my $q=shift @curRing;
	  my $j=shift @{$curQlist{$q}};
	  push @ret, $j;
	  unless (scalar @{$curQlist{$q}}) {
	    delete $curQlist{$q};
	  } else {
	    #push back the queue at the other end of the ring if the list is not empty
	    push @curRing, $q;
	  }
	}
      }

      $cptQJob{$q}++;
      #don't consider the queue if uit is already above the limit
      next if($queues->{$q}->{maxConcurentJob} && $cptQJob{$q}>$queues->{$q}->{maxConcurentJob});

      $curQPrio=$queues->{$q}{priority};
      push @{$curQlist{$q}}, $tmp[$itmp];
    }
    return @ret;
  }

  ########################## Queues

  sub __queues_exist{
    my $self=shift;
    my $qname=shift;
    if ( exists $self->__queues()->{$qname}) {
      return 1;
    } else {
      my $hqor=$self->__queues_orig;
      foreach my $oq (keys  %$hqor) {
	my $oqre=$hqor->{$oq};
	if ($qname =~ $oqre) {
	  my %q;
	  foreach my $k (keys %{$self->__queues->{$oq}}) {
	    my $v=$self->__queues->{$oq}{$k};
	    $q{$k}=$v;
	  }
	  $self->__queues()->{$qname}=\%q;
	  return 1;
	}
      }
    }
    return 0;
  }
  sub __queue_validResource{
    my $self=shift;
    my $qname=shift;
    my $res=shift;
    unless ($self->__queues->{$qname}{resource}{properties}) {
      return (defined  $self->__queues->{$qname}{resource}{type}) && $self->__queues->{$qname}{resource}{type} eq $res->{type};
    }
    my $qp=$self->__queues->{$qname}{resource}{properties};
    return 0 unless exists $self->__resources->{$res->{type}}{$res->{name}}{properties};
    my $rp=$self->__resources->{$res->{type}}{$res->{name}}{properties};
    foreach (keys %$qp) {
      return 0 unless exists $rp->{$_};
      return 0 unless $rp->{$_} eq $qp->{$_};
    }
    return 1;
  }


  sub __queue_insert{
    my $self=shift;
    my %hprms=@_;
    my $queue=$hprms{queue} or CORE::die "no queue defined for __queue_insert";
    my $job=$hprms{job} or CORE::die "no job defined for __queue_insert";
    my $resourceStatus=$hprms{resourceStatus} or CORE::die "no resourceStatus defined for __queue_insert";

    $job->{resource}=$resourceStatus->{name};
    $job->{status}='READY';
    $resourceStatus->{status}='RESERVED';
    $resourceStatus->{job_id}=$job->{id};
    #TODO count 4 queue
  }

  sub __queue_remove{
    my $self=shift;
    my %hprms=@_;
    my $job=$hprms{job} or CORE::die "no job defined for __queue_remove";
    my $queue=$job->{queue} or CORE::die "no queue could be defined from job  [$job->{id}] in  __queue_remove";
    CORE::die "queue [$queue] does not exist" unless $self->__queues_exist($queue);
    my $resourceStatus=$self->__resourcesStatus->{ $self->__queues->{$job->{queue}}{resource}{type}}{$job->{resource}} or CORE::die "no resourceStatus could be deduce from job [$job->{id}] for __queue_remove";

    my $jobStatus=$hprms{jobstatus}||'EXIT';

    $job->{status}=$jobStatus;
    $resourceStatus->{status}='AVAIL';
    undef $resourceStatus->{job_id};
  }

  ########################## queues status
  sub queuesStatus_init{
    my $self=shift;
    my %hprms=@_;
    $self->__lockdata();
    if ($hprms{reset}) {
      $self->__queuesStatus({});
    } else {
      $self->__queuesStatus_pump(nolock=>1);
    }
    $self->__unlockdata();
  }
  sub __queuesstatus_touch{
    my $self=shift;
    my %hprms=@_;
    my $q=$hprms{queue} or CORE::die "must give a [queue argument]";

    $self->__queuesStatus->{$q}{accesstime}=time;
  }

  ########################## I/O
  sub readConfig{
    my $self=shift;
    my %hprms=@_;
    if ($hprms{file}) {
      my $twig=XML::Twig->new();
      $twig->parsefile($hprms{file}) or die  "cannot xml parse file $hprms{file}: $!";
      return $self->readConfig(twigelt=>$twig->root);
    }
    if (my $rootel=$hprms{twigelt}) {
      if(my $el=$rootel->first_child('logging')){
	  my $fname=$el->first_child('file')->text if $el->first_child('file');
	  if ($fname) {
	    unless(open($FHLOG_SCHEDULER, ">>$fname")){
	      die "cannot open log file for appending [$fname]: $!";
	    }
	  } else {
	    $FHLOG_SCHEDULER=\*STDERR;
	  }
	  my $level=$el->first_child('level')?$el->first_child('level')->text:'warn';
	  Log::StdLog->import({level=>$level, handle=>$FHLOG_SCHEDULER});
      }else{
	Log::StdLog->import({level=>'warn', handle=>\*STDERR});
      }

      my $el=$rootel->first_child('schedulingMethod') or CORE::die "must set a /schedulingMethod element in xml config file";
      $self->scheduling_method($el->text);
      $el=$rootel->first_child('joblistIndex') or CORE::die "must set a /joblistIndex element in xml config file";
      $self->joblist_index($el->text);
      $el=$rootel->first_child('resourcesIndex') or CORE::die "must set a /resourcesIndex element in xml config file";
      $self->resourcesStatus_index($el->text);
      $el=$rootel->first_child('queuesIndex') or CORE::die "must set a /queuesesIndex element in xml config file";
      $self->queuesStatus_index($el->text);

      if ($el=$rootel->first_child('autoupdate')) {
	my $str=$el->text;
	if ($str=~/^y(es)?$/i) {
	  $self->__autoupdate(1);
	} elsif ($str=~/^n(o)?$/i) {
	  $self->__autoupdate(0);
	} else {
	  $self->__autoupdate($str);
	}
      } else {
	$self->__autoupdate(1);
      }
      if ($el=$rootel->first_child('autoremove')) {
	my $str=$el->text;
	if ($str=~/^y(es)?$/i) {
	  $self->__autoremove(1);
	} elsif ($str=~/^n(o)?$/i) {
	  $self->__autoremove(0);
	} else {
	  $self->__autoremove($str);
	}
      } else {
	$self->__autoremove(0);
      }

      my %rsc;
      foreach $el($rootel->get_xpath("resourcesList/oneResource")) {
	my $type=$el->atts->{type} or CORE::die "no type attribute to [resourcesList/oneResource]";
	my $name=$el->first_child('name') && $el->first_child('name')->text or CORE::die "no name field for resource";
	my $properties;
	foreach ($el->get_xpath('property')) {
	  $properties->{$_->atts->{name}}=$_->text;
	}
	CORE::die "duplicate resource name [$name] for type [$type]" if exists $rsc{$type} && exists $rsc{$type}{$name};
	if ($type eq 'cluster') {
	  my $machineFile=$el->first_child('machineFile') && $el->first_child('machineFile')->text or CORE::die "no machineFile field for cluster resource";
	  $machineFile=dirname($hprms{dir})."/$machineFile" unless dirname $machineFile;
	  $rsc{$type}{$name}={
			      name=>$name,
			      machineFile=>$machineFile,
			     };
	  $rsc{$type}{$name}{properties}=$properties if $properties;
	} elsif ($type eq 'machine') {
	  my $host=$el->first_child('host') && $el->first_child('host')->text or CORE::die "no host field for machine resource";
	  $host=dirname($hprms{dir})."/$host" unless dirname $host;
	  $rsc{$type}{$name}={
			      name=>$name,
			      host=>$host,
			     };
	  $rsc{$type}{$name}{properties}=$properties if $properties;
	} else {
	  CORE::die "no resource available for type [$type]\n";
	}
      }
      $self->__resources(\%rsc);

      my %q;
      foreach $el($rootel->get_xpath("queueList/oneQueue")) {
	my $name=$el->first_child('name') && $el->first_child('name')->text or CORE::die "no name field for oneQueue";
	CORE::die "duplicate queue name [$name]" if exists $q{$name};
	my $priority=$el->first_child('priority') && $el->first_child('priority')->text or CORE::die "no priority field for oneQueue (name=$name)";
	my %qrsc;
	foreach ($el->first_child('resource')->children) {
	  next if $_->gi eq 'property';
	  $qrsc{$_->gi}=$_->text;
	}
	my $properties;
	foreach ($el->get_xpath('resource/property')) {
	  $properties->{$_->atts->{name}}=$_->text;
	}
	$qrsc{properties}=$properties if $properties;
	CORE::die "no resource type for oneQueue (name=$name)" unless $qrsc{type};
	$q{$name}={
		   priority=>$priority,
		   resource=>\%qrsc,
		   name_orig=>$name,
		  };
	if ($el->first_child('maxConcurentJob')) {
	  $q{$name}{maxConcurentJob}=$el->first_child('maxConcurentJob')->text+0;
	}
	$self->__queues_orig->{$name}=qr/^$name$/;
      }
      $self->__queues(\%q);
      return $self;
    }
    CORE::die "neither [file=>] nor [twigelt=>] arg was passed to readConfig";
  }
  use overload '""' => sub{return $_[0]->toString};

  sub toString{
    my $self=shift;
    my %hprms=@_;

    my $ret="";

    unless ($hprms{skip_generic}) {
      $ret.="scheduling method=".$self->scheduling_method()."\n";
      $ret.="autoupdate=".($self->__autoupdate()?"yes":"no")."\n";
    }
    $ret.="\n\n" if $ret;
    unless ($hprms{skip_resources}) {
      unless ($hprms{skip_header}) {
	$ret.="#Resources\n#type\tname\tdescr\tproperties\n";
      }
      my $rsc=$self->__resources();
      foreach my $t (sort keys %$rsc) {
	my $ht=$rsc->{$t};
	foreach my $n (sort keys %$ht) {
	  my $htn=$ht->{$n};
	  $ret.="$t\t$n\t".($htn->{machineFile} or $htn->{host});
	  if ($htn->{properties}) {
	    $ret.="\t";
	    foreach (sort keys %{$htn->{properties}}) {
	      $ret.="($_=$htn->{properties}{$_})";
	    }
	  }
	  $ret.="\n";
	}
      }
    }

    $ret.="\n\n" if $ret;
    unless ($hprms{skip_resourcesStatus}) {
      unless ($hprms{skip_header}) {
	$ret.="#ResourcesStatus\n#type\tname\tstatus\tjob_id\n";
      }
      my $rscStatus=$self->__resourcesStatus();
      foreach my $t (sort keys %$rscStatus) {
	my $ht=$rscStatus->{$t};
	foreach my $n ( sort keys %$ht) {
	  my $htn=$ht->{$n};
	  $ret.="$t\t$n\t$htn->{status}\t".((defined $htn->{job_id})?$htn->{job_id}:'')."\n";
	}
      }
    }

    $ret.="\n\n" if $ret;
    unless ($hprms{skip_queues}) {
      unless ($hprms{skip_header}) {
	$ret.="#Queues\n#name\tpriority\tresource\tproperties\n";
      }
      my $q=$self->__queues();
      foreach my $n (sort keys %{$self->__queues_orig}) {
	my $hn=$q->{$n};
	$ret.="$n\t$hn->{priority}\t";
	my $i;
	foreach my $k (sort keys %{$hn->{resource}}) {
	  next if $k eq 'properties';
	  my $v=$hn->{resource}{$k};
	  $ret.= ";" if $i;
	  $i=1;
	  $ret.="$k=$v";
	}
	if ($hn->{resource}{properties}) {
	  $ret.="\t";
	  foreach (sort keys %{$hn->{resource}{properties}}) {
	    $ret.="($_=$hn->{resource}{properties}{$_})";
	  }
	}
	$ret.="\n";
      }
    }

    $ret.="\n\n" if $ret;
    unless ($hprms{skip_queuesStatus}) {
      unless ($hprms{skip_header}) {
	$ret.="#QueuesStatus\n#name\taccesstime\n";
      }
      my $q=$self->__queuesStatus();
      foreach my $n (sort keys %$q) {
	my $hn=$self->__queuesStatus->{$n};
	$ret.="$n\t".($hn->{accesstime}||'__NOTIME__');
	$ret.="\n";
      }
    }



    $ret.="\n\n" if $ret;
    unless ($hprms{skip_joblist}) {
      unless ($hprms{skip_header}) {
	$ret.="#Joblist\n#id\tstatus\tqueue\tresource\ttitle\tdir\tcommand\n";
      }
      my $hjl=$self->__joblist();
      foreach (sort {$b <=> $a} keys %$hjl) {
	$ret.=($hjl->{$_}{id} or 'NOID')."\t".($hjl->{$_}{status} or 'NOSTATUS')."\t".($hjl->{$_}{queue} or 'NOQUEUE')."\t".($hjl->{$_}{resource} or '')."\t".($hjl->{$_}{title} or '')."\t".($hjl->{$_}{dir} or 'NODIR')."\t".basename($hjl->{$_}{command} || 'NOCOMMAND')."\n";
	unless($hjl->{$_}{id}){
	}
      }
    }

    return $ret;
  }

  ############################ string info & command
  sub dataRequest{
    my $self=shift;
    my %hprms=@_;
    my $requests=$hprms{request} or CORE::die "must provide a [request] argument";
    my %reth;
    foreach (split /,/, $requests) {
      if (/^joblist$/i) {
	$reth{joblist}=$self->__joblist();
	next;
      }
      if (/^resources$/i) {
	$reth{resources}=$self->__resources();
	next;
      }
      if (/^resourcesstatus$/i) {
	$reth{resourcesstatus}=$self->__resourcesStatus();
	next;
      }
      if (/^queues$/i) {
	$reth{queues}=$self->__queues();
	next;
      }
      if (/^queuesstatus$/i) {
	my %h;
	my $qs=$self->__queuesStatus();
	foreach (keys %$qs){
	  if(ref($qs->{$_}) eq 'HASH'){
	    my %hh=%{$qs->{$_}};
	    $h{$_}=\%hh;
	    $hh{accesstime}=localtime($hh{accesstime}) if exists $hh{accesstime};
	  }else{
	    $h{$_}=$qs->{$_};
	  }
	}
	$reth{queuesstatus}=\%h;
	next;
      }
      if (s/^joblist\b//i) {
	unless($_){
	  $reth{joblist}=$self->__joblist();
	}else{
	  my $hideCompleted=/\bhidecompleted\b/i;
	  my $hideFinished=/\bhidefinished\b/i;
	  my $displayLast=$1 if /\bdisplaylast=(\d+)/;
	  my %h=%{$self->__joblist()};
	  if($hideFinished){
	    foreach (keys %h){
	      delete $h{$_} if $h{$_}{status}=~$FINISHED_JOB_STATUS;
	    }
	  }elsif($hideCompleted){
	    foreach (keys %h){
	      delete $h{$_} if $h{$_}{status}=~/COMPLETED/;
	    }
	  }

	  if($displayLast){
	    my @idx=sort {$b<=>$a} keys %h;
	    if ($displayLast<scalar(@idx)){
	      delete $h{$idx[$_]} foreach($displayLast..$#idx);
	    }
	  }
	  $reth{joblist}=\%h;
	}
	next;
      }
      CORE::die "unknown request [$_]";
    }
    return \%reth;

  }
}


1; # End of BatchSystem::SBS
