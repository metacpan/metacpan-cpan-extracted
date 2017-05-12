package Cluster::Init::Group;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use POSIX qw(:signal_h :errno_h :sys_wait_h);
my $debug=$ENV{DEBUG} || 0;
use Cluster::Init::Util qw(debug run NOOP);

use Cluster::Init::Kernel;
use Cluster::Init::Process;
use Cluster::Init::DFA::Group qw(:constants);
use base qw(Cluster::Init::DFA::Group Cluster::Init::Util);

sub init 
{
  my $self = shift;
  # $self->Cluster::Init::Util::init;
  # $self->fields qw();
  $self->state(CONFIGURED);
  $self->{db}= Cluster::Init::Kernel->db;
  # $self->idle(to=>$self,min=>10,max=>20,data=>IDLE);
  $self->idle('idle');
  # debug dump $self;
  $self->{name}=$self->{group};
  return $self;
}

sub tell
{
  my $self=shift;
  my $level=shift;
  my $data={level=>$level};
  $self->event(TELL,$data);
}

sub halt
{
  my $self=shift;
  $self->event(HALT);
}

# Assumes that changed processes and processes from other runlevels
# have already been stopped, and retired or changed processes have
# already been garbage collected.  All we need to do now is ensure
# that all of our new processes are in state DONE, PASS, or FAIL.

sub startnext
{
  my ($self,$data)=@_;
  my $conf=$self->{conf};
  affirm { $conf };
  my $db=$self->{db};
  my $group=$self->{group};
  my $level=$data->{level};
  # set $self->{level} to $data->{level} here only!  $self->{level}
  # shows current level; $data->{level} shows destination level while
  # stopping old level
  $self->{level}=$level;
  # we'll always get handed a copy of the latest version of the db;
  # integrate and use it
  my (@newproc) = $conf->group($group);
  #debug "\@newproc = ", dump @newproc;
  for my $newproc (@newproc)
  {
    debug $newproc->{tag};
    unless ($newproc->haslevel($level))
    {
      debug $newproc->{tag}." doesn't have level $level";
      # may have to kill these deliberately; because they have CHLD
      # watchers in them, they will never go out of scope otherwise
      # XXX no longer issue -- CHLD watchers not started until xeq
      # $newproc->destruct;
      next;
    }
    my $tag = $newproc->{tag};
    debug "starting $tag level $level";
    # by the time we get to this point, if tag matches, then we must
    # assume that cmd and mode match
    my ($oldproc) = $db->get('Cluster::Init::Process', {tag=>$tag});
    if ($oldproc)
    {
      affirm { $oldproc->{mode} eq $newproc->{mode} };
      affirm { $oldproc->{cmd} eq $newproc->{cmd} };
      next if $oldproc->ran;
      return(NOOP,$data) if $oldproc->running;
      # $DB::single=1;
      # $db->del($oldproc);
      $oldproc->start;
      return(NOOP,$data);
    }
=comment
    # Oh, but create new process objects, so we don't cross references
    # between conf and db; otherwise watchers may never go out of
    # scope, DESTROY is never called when we retire processes, and other
    # bad things.  XXX not needed since switch to Conf
    my $proc=$newproc->new
    (
      line=>$newproc->{line},
      group=>$newproc->{group},
      tag=>$newproc->{tag},
      level=>$newproc->{level},
      mode=>$newproc->{mode},
      cmd=>$newproc->{cmd}
    );
=cut
    my $proc = $newproc;
    # warn $tag;
    $db->ins($proc);
    $proc->start;
    my $w=$self->var(PROC,{var=>\$proc->{state}, poll=>'w'},$data);
    $proc->watchers($w);
    # $DB::single=1;
    return(NOOP,$data);
  }
  return(ALL_STARTED,$data);
}

sub ckproc
{
  my ($self,$data)=@_;
  my $db=$self->{db};
  my $group=$self->{group};
  # use $self->{level} here rather than $data->{level}; we want to
  # check against current rather than destination level (though they
  # should be the same)
  my $level=$self->{level};
  my (@proc) = $db->get('Cluster::Init::Process', {group=>$group});
  my ($done,$pass,$fail,$configured,$other,$total)=(0,0,0,0,0,0);
  for my $proc (@proc)
  {
    next unless $proc->haslevel($level);
    $total++;
    debug $proc->{tag}. " ". $proc->state;
    if ($proc->done){$done++;next}
    if ($proc->pass){$pass++;next}
    if ($proc->fail){$fail++;next}
    if ($proc->configured){$configured++;next}
    $other++;
  }
  debug "done $done pass $pass fail $fail configured $configured other $other total $total";
  return(NOOP,$data) if $other;
  return(ANY_FAILED,$data) if $fail;
  return(ALL_DONE,$data) unless $total;
  return(ALL_PASSED,$data) if $pass == $total;
  return(ALL_DONE,$data) if $done + $pass == $total;
  return(NOOP,$data) if $configured == $total;
  die "should never get here";
}

# Stop processes from other runlevels.
sub stopold
{
  my ($self,$data)=@_;
  my $db=$self->{db};
  my $group=$self->{group};
  my $level=$data->{level};
  affirm { defined($level) };
  my (@proc) = $db->get('Cluster::Init::Process', {group=>$group});
  for my $proc (@proc)
  {
    next if $proc->haslevel($level);
    next if $proc->configured;
    next if $proc->{kickme};
    my $tag = $proc->{tag};
    debug "stopping $tag level $level";
    # slap a kickme sign on this thing
    my $w=$self->timer(KICKME,{at=>time,interval=>1},$proc);
    $proc->watchers($w);
  }
  $self->timer(TIMEOUT,{at=>time+1},$data);
  return(NOOP,$data);
}

# stop all processes in group
sub haltgrp
{
  my ($self,$data)=@_;
  my $db=$self->{db};
  my $group=$self->{group};
  my (@proc) = $db->get('Cluster::Init::Process', {group=>$group});
  for my $proc (@proc)
  {
    next if $proc->configured;
    next if $proc->{kickme};
    my $tag = $proc->{tag};
    debug "halting $tag";
    # slap a kickme sign on this thing
    my $w=$self->timer(KICKME,{at=>time,interval=>1},$proc);
    $proc->watchers($w);
  }
  $self->timer(TIMEOUT,{at=>time+1},$data);
  return(NOOP,$data);
}

sub destruct
{
  my $self=shift;
  my $db=$self->{db};
  my $group=$self->{group};
  if ($db)
  {
    for my $proc ($db->get('Cluster::Init::Process', {group=>$group}))
    {
      $self->retire($proc);
    }
  }
  $self->SUPER::destruct;
  return 1;
}

sub kick
{
  my ($self,$proc)=@_;
  $proc->stop;
  return(NOOP);
}

sub ckstop
{
  my ($self,$data)=@_;
  my $db=$self->{db};
  my $group=$self->{group};
  my $level=$data->{level};
  affirm { defined($level) };
  my (@proc) = $db->get('Cluster::Init::Process', {group=>$group});
  for my $proc (@proc)
  {
    next if $proc->haslevel($level);
    next if $proc->configured;
    $self->timer(TIMEOUT,{at=>time+1},$data);
    return(NOOP,$data);
  }
  return(OLD_STOPPED,$data);
}
  
sub ckhalt
{
  my ($self,$data)=@_;
  my $db=$self->{db};
  my $group=$self->{group};
  my (@proc) = $db->get('Cluster::Init::Process', {group=>$group});
  my $stillthere;
  for my $proc (@proc)
  {
    debug "trying to halt: ".$proc->{tag}." ".$proc->state;
    $proc->stop;
    $self->retire($proc) if $proc->configured;
    $stillthere++;
  }
  if ($stillthere)
  {
    $self->timer(TIMEOUT,{at=>time+1},$data);
    return(NOOP,$data);
  }
  return(ALL_HALTED,$data);
}
  
# Garbage collect old, retired, or changed processes.  Assumes old
# processes have already been stopped gracefully.  Note that we don't
# try to do a soft stop here -- procs will get kill -9 if their
# cltab entry has been changed or deleted; might want to improve
# this in the future.  For now, the workaround is to always do a
# 'tell' to stop processes before editing cltab.
sub garbage_collect
{
  my ($self,$data)=@_;
  my $conf=$self->{conf};
  my $db=$self->{db};
  my $group=$self->{group};
  my $level=$data->{level};
  my (@oldproc) = $db->get('Cluster::Init::Process', {group=>$group});
  for my $oldproc (@oldproc)
  {
    my $tag = $oldproc->{tag};
    my ($newproc) = $conf->tag($tag);
    # deleted
    $self->retire($oldproc) unless $newproc;
    # changed 
    $self->retire($oldproc) if $newproc->{mode} ne $oldproc->{mode};
    $self->retire($oldproc) if $newproc->{cmd} ne $oldproc->{cmd};
    next if $oldproc->haslevel($level);
    # old level 
    $self->retire($oldproc);
  }
  return(CLEAN,$data);
}

sub retire
{
  my ($self,$proc)=@_;
  my $db=$self->{db};
  $proc->destruct;
  $db->del($proc);
}

sub XXXDONE_enter
{
  warn "in state DONE";
  $DB::single=1;
}

1;
