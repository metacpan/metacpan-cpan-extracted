package Cluster::Init::Daemon;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use IO::Socket;
use IPC::LDT;
use Event;
my $debug=$ENV{DEBUG} || 0;
use Cluster::Init::Util qw(debug NOOP);

use Cluster::Init::Group;
use Cluster::Init::Process;
use Cluster::Init::Status;

use Cluster::Init::DFA::Daemon qw(:constants);
use base qw(Cluster::Init::DFA::Daemon Cluster::Init::Util);

#our %action = DFA_ACTIONS;

sub init 
{
  my $self = shift;
  # $self->Cluster::Init::Util::init;
  $self->fields qw(server client ldt);
  $self->state(START);
  # $self->idle(to=>$self,min=>10,max=>20,data=>IDLE);
  $self->idle(IDLE);
  $self->idle(WRITETIME,{min=>30,max=>45});
  $self->{status}=Cluster::Init::Status->new
  (
    clstat=>$self->conf('clstat')
  );
  # debug dump $self;
  return $self;
}

sub writestat
{
  my $self=shift;
  my $status=$self->{status};
  $status->writestat(@_);
  return '';
}

sub conf
{
  my $self=shift;
  my $var=shift;
  return $self->{conf}->get($var);
}

sub bye
{
  debug "bye bye";
  Event::unloop();
  return 1;
}

sub read_cltab
{
  my $self=shift;
  my $data=shift;
  my $rc = $self->{conf}->read_cltab;
  unless ($rc)
  {
    $data->{msg}=$self->{conf}->{msg};
    return (CLTAB_NOK,$data);
  }
  return (CLTAB_OK,$data);
}

sub start_listener
{
  my $self=shift;
  if ($debug > 4)
  {
    require NetServer::Portal;
    NetServer::Portal->default_start();  # creates server
    warn "NetServer::Portal listening on port ".(7000+($$ % 1000))."\n";
    $Event::DebugLevel=$debug;
  }
  unlink $self->conf('socket');
  my $server = new IO::Socket::UNIX (
    Local => $self->conf('socket'),
    Type => SOCK_STREAM,
    Listen => SOMAXCONN
  );
  if ($server)
  {
    $self->server($server);
    $self->io(SOCKETIO, {fd=>$server});
    return "";
  }
  else
  {
    return (SOCKET_ERROR);
  }
}

sub watch_client
{
  my $self=shift;
  my $server=$self->server();
  my $client = $server->accept();
  $self->client($client);
  my $ldt=new IPC::LDT(handle=>$client, objectMode=>1);
  $self->ldt($ldt);
  $self->io(CLIENTIO, {fd=>$client,repeat=>0});
  return (NOOP);
}

sub getcmd
{
  my $self=shift;
  debug "getting command";
  my $ldt = $self->ldt;
  my ($data)=$ldt->receive;
  debug dump $data;
  my $group = $data->{group} if $data->{group};
  my $level = $data->{level} if defined($data->{level});
  unless (defined($group) && defined($level))
  {
    return (CMDERR);
  }
  if ($level eq ":::SHUTDOWN:::")
  {
    debug "got shutdown";
    return (SHUTDOWN);
  }
  else
  {
    return (TELL,{group=>$group,level=>$level});
  }
}

sub tellgroup
{
  my $self=shift;
  my $data=shift;
  my $group=$data->{group};
  my $level=$data->{level};
  my $conf=$self->{conf};
  debug "tellgroup $group $level";
  # first, destroy any groups which are no longer in cltab
  # THIS IS NOT A GRACEFUL SHUTDOWN
  for my $oldgroup ( keys %{$self->{groups}} )
  {
    debug "checking $oldgroup";
    next if $conf->group($oldgroup);
    debug "destroying $oldgroup";
    # debug `ps -eaf | tail`;
    $self->{groups}{$oldgroup}->destruct;
    delete $self->{groups}{$oldgroup};
    # debug `ps -eaf | tail`;
  }
  # now make sure this group is in cltab
  unless ( $self->{groups}{$group} || $conf->group($group) )
  {
    return (GROUP_NOK,{msg=>"no such group: $group"});
  }
  # make sure group has a DFA
  unless ($self->{groups}{$group})
  {
    debug "creating $group";
    my $dfa = Cluster::Init::Group->new
    (
      group=>$group, 
      conf=>$conf,
      status=>$self->{status}
    );
    $self->{groups}{$group}=$dfa;
  }
  $self->{groups}{$group}->tell($level);
  $data->{msg}="level transition started";
  return (GROUPTOLD,$data);
}

sub haltall
{
  my $self=shift;
  my $data=shift;
  for my $group (keys %{$self->{groups}})
  {
    debug "halting $group";
    $self->{groups}{$group}->halt;
  }
  $data->{msg}="all groups halting";
  $self->timer(HALTTIME,{at=>time+5},$data);
  return (HALTED,$data);
}

sub putres
{
  my $self=shift;
  my $data=shift;
  debug dump $data;
  my $ldt = $self->ldt;
  my $client = $self->client;
  $data->{msg}="result unknown" unless $data->{msg};
  debug "responding ".$data->{msg};
  $ldt->send($data);
  $self->ldt(0);
  close $client;
  return (NOOP,$data);
}

1;
