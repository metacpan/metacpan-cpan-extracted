#!/usr/bin/perl -w
# vim:set syntax=perl:
use strict;
use Test;
require "t/utils.pl";

# BEGIN { plan tests => 14, todo => [3,4] }
BEGIN { plan tests => 32 }

use Cluster::Init::Process;
use Cluster::Init::DFA::Process qw(:constants);
# use Data::Dump qw(dump);


### wait
{
  # create dfa
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test',
     tag=>'test1',
     level=>'1',
     mode=>'wait',
     cmd=>'sleep 3'
    );
  go($dfa,CONFIGURED);
  # start 
  $dfa->event(START);
  ok(go($dfa,RUNNING));
  # wait for completion
  my $i=1;
  while($dfa->state ne DONE)
  {
    step(1);
    run(1);
    $i++;
    die if $i > 9;
  }
  ok($i>3);
  ok($dfa->state, DONE);
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->event(START);
  ok(go($dfa,RUNNING));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->destruct;
}

### once
{
  # map {$_->cancel} Event::all_watchers;
  # create dfa
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test',
     tag=>'test1',
     level=>'1',
     mode=>'once',
     cmd=>'sleep 5'
    );
  # start 
  $dfa->event(START);
  ok(go($dfa,DONE));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->event(START);
  ok(go($dfa,RUNBG));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->destruct;
}

### respawn
{
  # cancel outstanding watchers
  # map {$_->cancel} Event::all_watchers;
  # create dfa
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test',
     tag=>'test1',
     level=>'1',
     mode=>'respawn',
     cmd=>'sleep 3'
    );
  # start 
  $dfa->event(START);
  ok(go($dfa, DONE, 5));
  my $oldpid = $dfa->{pid};
  ok($oldpid);
  ok(go($dfa,RUNBG,4));
  ok(go($dfa,DONE,1));
  my $newpid = $dfa->{pid};
  ok($newpid);
  ok($oldpid != $newpid);
  $dfa->destruct;
}

### test pass
{
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test',
     tag=>'test9',
     level=>'1',
     mode=>'test',
     cmd=>'true'
    );
  $dfa->event(START);
  ok(go($dfa, PASS));
  $dfa->event(START);
  ok(go($dfa, SETUP));
  ok(go($dfa, PASS));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->event(START);
  ok(go($dfa, TESTING));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->destruct;
}

### test fail
{
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test1',
     tag=>'test2',
     level=>'1',
     mode=>'test',
     cmd=>'false'
    );
  $dfa->event(START);
  ok(go($dfa,FAIL));
  $dfa->event(START);
  ok(go($dfa,SETUP));
  ok(go($dfa,FAIL));
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  $dfa->destruct;
}

### stop fg
{
  my $dfa=Cluster::Init::Process->new
    (
     group=>'test',
     tag=>'test1',
     level=>'1',
     mode=>'wait',
     cmd=>'sleep 5'
    );
  # setup
  $dfa->event(START);
  ok(go($dfa, SETUP));
  $dfa->event(STOP);
  ok(go($dfa, CONFIGURED));
  # runfg 
  $dfa->event(START);
  ok(go($dfa,RUNFG));
  my $pid = $dfa->{pid};
  ok(kill(0,$pid),1);
  $dfa->event(STOP);
  ok(go($dfa,CONFIGURED));
  ok(kill(0,$pid),0);
  $dfa->destruct;
}

1;
