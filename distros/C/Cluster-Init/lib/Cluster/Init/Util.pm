package Cluster::Init::Util;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp;
use Carp::Assert;
# use Storable qw(dclone);
use Event qw(loop unloop unloop_all all_watchers sweep);
use Event;
use Event::Stats;
use Time::HiRes qw(time);
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(&debug &run NOOP);

$Event::DIED = sub {
  Event::verbose_exception_handler(@_);
  Event::unloop_all(0);
};

use constant NOOP => 0;

sub debug
{
  my $debug = $ENV{DEBUG} || 0;
  return unless $debug;
  my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
  my $subline = (caller(0))[2];
  my $msg = join(' ',@_);
  $msg.="\n" unless $msg =~ /\n$/;
  warn time()." $$ $subroutine,$subline: $msg" if $debug;
  if ($debug > 1)
  {
    warn _stacktrace();
  }
  if ($debug > 2)
  {
    Event::Stats::collect(1);
    warn sprintf("%d\n%-35s %3s %10s %4s %4s %4s %4s %7s\n", time,
    "DESC", "PRI", "CBTIME", "PEND", "CARS", "RAN", "DIED", "ELAPSED");
    for my $w (reverse all_watchers())
    {
      my @pending = $w->pending();
      my $pending = @pending;
      my $cars=sprintf("%01d%01d%01d%01d",
      $w->is_cancelled,$w->is_active,$w->is_running,$w->is_suspended);
      my ($ran,$died,$elapsed) = $w->stats(60);
      warn sprintf("%-35s %3d %10d %4d %4s %4d %4d %7.3f\n",
      $w->desc,
      $w->prio,
      $w->cbtime,
      $pending,
      $cars,
      $ran,
      $died,
      $elapsed);
    }
  }
}

sub _stacktrace
{
  my $out="";
  for (my $i=1;;$i++)
  {
    my @frame = caller($i);
    last unless @frame;
    $out .= "$frame[3] $frame[1] line $frame[2]\n";
  }
  return $out;
}

sub dq
{
  my $self=shift;
  my $e=shift;
  unless (ref $e->w)
  {
    debug "skipping $e -- no watcher";
    return 0;
  }
  my $data=$e->w->data || {};
  # warn dump $data;
  my $event=$data->{_dfa_event};
  my $desc= $e->w->desc;
  debug "$desc: isactive: ". $e->w->is_active;
  $self->killwatcher($e->w) unless $e->w->is_active;
  # delete $data->{_dfa_event};
  # $self->history($event,$data);
  unless ($event)
  {
    # my $debug=$ENV{DEBUG};
    # $ENV{DEBUG}=3;
    debug "ouch -- somehow there's no _dfa_event in \$data:\n"
    .(dump $data)."\n"
    .(dump $self)."\n"
    .(dump $e)."\n"
    ;
    # $ENV{DEBUG}=$debug;
    return 0;
  }
  debug "$desc: calling tick($event,$data)";
  $self->tick($event,$data);
}

sub event
{
  my $self=shift;
  my $event=shift;
  debug "queue event $event";
  my $data=shift || {};
  $self->timer($event,{at=>time},$data);
}

sub watcher
{
  my $self=shift;
  my $type=shift;
  my $event=shift;
  debug "create $type $event";
  my $parm=shift || {};
  my $olddata=shift || {};
  my $class=ref($self);
  # make a copy so it doesn't go 'round and 'round
  my $data = _copy($olddata);
  # $data = eval(dump($data));
  my $desc = "$self $type $event";
  unless ($event)
  {
    my $debug=$ENV{DEBUG};
    $ENV{DEBUG}=3;
    debug "oooh -- $type has no event".(dump $self);
    $ENV{DEBUG}=$debug;
    return 0;
  }
  $data->{_dfa_event}=$event;
  $parm->{desc}=$desc;
  $parm->{cb}=[$self,'dq'];
  $parm->{data}=$data;
  # debug $type, $event, $data;
  my $w = Event->$type(%$parm);
  # warn $w;
  $self->watchers($w);
  return $w;
}

# deep copy, but pass blessed and other complex refs through unchanged
sub _copy
{
  my $in=shift;
  my $ref=ref $in;
  return $in unless $ref;
  $ref eq "SCALAR" && do {my $out; $$out=$$in; return $out};
  $ref eq "ARRAY" && do
  {
    my @out = map {_copy($_)} @$in;
    return \@out;
  };
  $ref eq "HASH" && do
  {
    my %out;
    while (my ($key,$val) = each %$in)
    {
      $out{$key}=_copy($val);
    }
    return \%out;
  };
  return $in;
}

sub watchers
{
  my $self=shift;
  my $w=shift;
  if ($w)
  {
    affirm { ref $w };
    push @{$self->{watchers}}, $w;
  }
  my $out="watchers:\n";
  for my $x (@{$self->{watchers}})
  {
    next unless ref $x;
    $out.="\t".$x->desc."\n";
  }
  # warn $out;
  return @{$self->{watchers}};
}

sub killwatcher
{
  my $self=shift;
  my $w=shift;
  if (ref $w)
  {
    debug "killwatcher ".$w->desc;
    # let it finish any pending requests -- primarily catching CHLD
    # sweep() while $w->pending;
    $w->cancel;
    my @watchers = grep {$_ && $_!=$w} $self->watchers;
    $self->{watchers}=\@watchers;
  }
  return $self->watchers;
}

sub idle     { shift->watcher('idle',  @_) }
sub timer    { shift->watcher('timer', @_) }
sub io       { shift->watcher('io',    @_) }
sub var      { shift->watcher('var',   @_) }
sub sigevent { shift->watcher('signal',@_) }

sub fields
{
  my $self=shift;
  my $class = ref $self;
  affirm { $class };
  my @field=@_;
  for my $field (@field)
  {
    next if $self->can($field);
    my $var = $class."::".$field;
    debug "$var";
    no strict 'refs';
    *$field = sub 
    { 
      my $self=shift; 
      my $val=shift;
      $self->{$var}=$val if defined $val;
      return $self->{$var};
    };
  }
}

sub transit
{
  my ($self,$oldstate,$newstate,$action,@arg)=@_;
  my $class = ref $self;
  my $tag = $self->{tag} || "";
  debug "$class: $tag: newstate=>'$newstate', action=>'$action'\n";
  $self->{status}->newstate($self,$self->{name},$self->{level},$newstate) 
    if $self->{status} && $self->{name} && $self->{level};
  if ($action)
  {
    my $method=lc($action);
    my $code='$self->'.$method.'(@arg)';
    unless ($self->can($method))
    {
      warn "$code not implemented\n";
      return undef;
    }
    else
    {
      my ($event,@res) = eval ($code);
      unless(defined $event)
      {
	die "$class: '$code' died: $@\n";
      }
      debug "$class: '$code' returned '$event'\n";
      $self->event($event,@res) if $event; # =~ /^[A-Z]+[A-Z0-9]+$/;
    }
  }
  # $self->timer("foo",{at=>time});
  # $DB::single=1 if $newstate eq "DONE";
  # `strace -o /tmp/t1 -p $$` if $newstate eq "DONE";
}

sub run
{
  my $seconds=shift;
  Event->timer(at=>time() + $seconds,cb=>sub{unloop()});
  loop();
}

sub destruct
{
  my $self=shift;
  my $debug="destruct ";
  $debug.= $self->{tag} || $self;
  $debug.=" ";
  $debug.= $self->{name} || " ";
  $debug.=" ";
  $debug.= $self->{pid} || " ";
  debug $debug;
  if ($self->{pid})
  {
    debug "killing ".$self->{pid};
    kill(-9, $self->{pid});
    kill(9, $self->{pid});
    # the following line is dangerous -- could hang on hung umount
    # requests etc.
    waitpid($self->{pid},0);
  }
  for my $w ($self->watchers)
  {
    $self->killwatcher($w);
  }
  $self->{status}->remove($self,$self->{name}) 
    if $self->{status} && $self->{name};
  return 1;
}

sub DESTROY
{
  my $self=shift;
  $self->destruct;
}

1;
