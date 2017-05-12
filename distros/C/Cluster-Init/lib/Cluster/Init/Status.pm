package Cluster::Init::Status;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use Cluster::Init::Util qw(debug);


sub new
{
  my $class=shift;
  $class = (ref $class || $class);
  my $self={@_};
  bless $self, $class;
}

sub newstate
{
  my ($self,$obj,$name,$level,$state)=@_;
  my $class=ref $obj;
  $self->{state}{$class}{$name}=$state;
  $self->{level}{$class}{$name}=$level;
  $self->writestat;
}

sub remove
{
  my ($self,$obj,$name)=@_;
  my $class=ref $obj;
  delete $self->{state}{$class}{$name};
  delete $self->{level}{$class}{$name};
  $self->writestat;
}

sub writestat
{
  my $self=shift;
  return unless $self->{'clstat'};
  my $clstat = $self->{'clstat'};
  my $tmp = "$clstat.".time();
  open(TMP,">$tmp") || die $!;
  for my $class (keys %{$self->{state}})
  {
    for my $name (keys %{$self->{state}{$class}})
    {
      my $state = $self->{state}{$class}{$name};
      my $level = $self->{level}{$class}{$name};
      print TMP "$class $name $level $state\n";
    }
  }
  close TMP;
  rename($tmp,$clstat) || die $!;
  return '';
}

sub DESTROY
{
  my $self=shift;
  unlink $self->{clstat};
}


1;
