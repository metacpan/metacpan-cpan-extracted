package Cluster::Init::Process;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use Time::HiRes qw(time);
use POSIX qw(:signal_h :errno_h :sys_wait_h);
my $debug=$ENV{DEBUG} || 0;
use Cluster::Init::Util qw(debug NOOP);

use Cluster::Init::DFA::Process qw(:constants);
use base qw(Cluster::Init::DFA::Process Cluster::Init::Util);

sub init 
{
  my $self = shift;
  # $self->Cluster::Init::Util::init;
  # $self->fields qw(pid);
  $self->state(CONFIGURED);
  # $self->idle(IDLE);
  return $self;
}

sub start
{
  my $self=shift;
  $self->event(START);
}

sub stop
{
  my $self=shift;
  $self->event(STOP);
}

sub XXXstate
{
  my ($self,$state)=@_;
  my $oldstate=$self->SUPER::state || "";
  my $newstate=$self->SUPER::state($state);
  kill 'USR2', $$ if $oldstate ne $newstate;
  return $newstate;
}

sub error
{
  my ($self,$data)=@_;
  return ($self,$data) unless $self->{'log'};
  return ($self,$data) unless $data->{'msg'};
  open(LOG,">>$self->{'log'}") || die $!;
  print LOG $data->{msg};
  close LOG;
  return ($self,$data);
}

sub ckmode
{
  my ($self,$data)=@_;
  for ($self->{mode})
  {
    /^wait$/ && (return(WAIT,$data));
    /^respawn$/ && (return(RESPAWN,$data));
    /^once$/ && (return(ONCE,$data));
    /^test$/ && (return(TEST,$data));
    /^off$/ && (return(OFF,$data));
    die "invalid mode: $_";
  }
}

sub ckfreq
{
  my ($self,$data)=@_;
  my $last = $self->{ckfreq}{'last'} || 0;
  my $hits = $self->{ckfreq}{'hits'} || 0;
  my $elapsed = time() - $last;
  $hits++ if $elapsed < 1;
  $hits-- if $elapsed > 1;
  $hits = 0  if $hits < 0;
  debug $self->{tag}." $hits $elapsed";
  $self->{ckfreq}{'last'}=time();
  $self->{ckfreq}{'hits'}=$hits;
  if ($hits > 5)
  {
    warn $self->{tag}." respawning too rapidly: sleeping 60 seconds\n";
    $self->timer(CONTINUE,{at=>time+60},$data);
    return(TOO_RAPID,$data);
  }
  return(CONTINUE,$data);
}

sub xeq
{
  my ($self,$data)=@_;
  my $cmd=$self->{cmd};
  my $tag=$self->{tag};
  $self->sigevent(CHLD,{signal=>'CHLD'}) unless $self->{xeqs};
  $self->{xeqs}++;
  my $pid = fork();
  unless (defined($pid))
  {
    $data->{msg}=$!;
    return(EXECFAILED,$data);
  }
  unless ($pid)
  {
    debug "$tag exec $cmd";
    exec $cmd;
    die $!;
  }
  debug "$tag forked $pid for $cmd";
  $self->{pid}=$pid;
  return(STARTED,$data);
}

sub ckpid
{
  my ($self,$data)=@_;
  my $pid = $self->{pid};
  debug "checking $pid ".$self->{tag};
  affirm { $pid };
  my $waitpid = waitpid($pid, &WNOHANG);
  my $rc = $?;
  unless (kill(0,$pid) == 0)
  {
    # still running 
    debug $self->{tag}." $pid still running";
    return(PROCRUNNING,$data);
  }
  # $pid exited
  debug "$pid returned $rc";
  $self->{rc}=$rc unless $rc == -1;
  return(EXITED,$data);
}

sub ckrc
{
  my ($self,$data)=@_;
  debug $self->{pid}." returned ".$self->{rc};
  return(RC_NONZERO,$data) unless defined $self->{rc};
  return(RC_NONZERO,$data) if $self->{rc};
  return(RC_ZERO,$data);
}

sub STOPPING_enter
{
  my ($self,$oldstate,$newstate,$action,$data)=@_;
  debug __PACKAGE__.": newstate=>'$newstate', action=>'".$newstate."_enter'\n";
  my $tag = $self->{tag};
  my $pid = $self->{pid};
  debug "stopping $tag $pid";
  $self->{sig}=2;
  $self->{timeout}=0;
  $self->timer(TIMEOUT,{at=>time+$self->{timeout}});
}

sub killproc
{
  my ($self,$data)=@_;
  my $tag = $self->{tag};
  my $pid = $self->{pid};
  my $sig = $self->{sig};
  debug "kill $sig,$pid ($tag)";
  kill($sig,$pid);
  $self->{sig}=9 if $sig == 15;
  $self->{sig}=15 if $sig == 2;
  $self->{timeout}+=5;
  $self->timer(TIMEOUT,{at=>time+$self->{timeout}});
  return(NOOP,$data);
}

sub haslevel
{
  my ($self,$cklevel)=@_;
  my $level=$self->{level};
  my @level;
  if ($level eq $cklevel)
  {
    return $level;
  }
  if ($level =~/,/)
  {
    @level = split(',',$level);
  }
  else
  {
    @level = split('',$level);
  }
  return grep /^$cklevel$/, @level;
}

sub done
{
  my ($self,$state)=@_;
  return 1 if $self->state eq DONE;
  return 0;
}

sub pass
{
  my ($self,$state)=@_;
  return 1 if $self->state eq PASS;
  return 0;
}

sub fail
{
  my ($self,$state)=@_;
  return 1 if $self->state eq FAIL;
  return 0;
}

sub configured
{
  my ($self,$state)=@_;
  return 1 if $self->state eq CONFIGURED;
  return 0;
}

sub running
{
  my ($self,$state)=@_;
  return 1 if $self->state eq SETUP;
  return 1 if $self->state eq RUNFG;
  return 1 if $self->state eq RUNBG;
  return 1 if $self->state eq RUNNING;
  return 1 if $self->state eq RUNTEST;
  return 1 if $self->state eq TESTING;
  return 1 if $self->state eq PAUSING;
  return 1 if $self->state eq STOPPING;
  return 0;
}

sub ran
{
  my ($self,$state)=@_;
  return 1 if $self->done;
  return 1 if $self->pass;
  return 1 if $self->fail;
  return 0;
}

1;
