package Cluster::Init::DB;
use strict;
use warnings;
#
# an in-memory object database
#
# objects must be hashes
# 
# @itemrefs = $db->ins($hashobj);
# @itemrefs = $db->upd($class,$filterhash,$valuehash);
# @itemrefs = $db->get($class,$filterhash);
# @itemrefs = $db->del($class,$filterhash);
#

use Data::Dump qw(dump);
use Carp::Assert;
use Storable qw(dclone);

sub new
{
  my $class=shift;
  $class = (ref $class || $class);
  my %parms=@_;
  my $self=\%parms;
  $self->{nextid}=1;
  $self->{_mtime}=0;
  bless $self, $class;
}

sub ins
{
  my ($self,$obj)=@_;
  # warn dump($obj);
  # warn dump(ref($obj));
  die 'usage: $db->ins($hashobj)' 
    unless ref($obj);
  my $class = ref($obj);
  my @out;
  my $id = $self->{nextid}++;
  $self->{db}{$class}{$id} = $obj;
  $self->{db}{$class}{$id}{_mtime}=time;
  $self->{_mtime}=time;
  return $self->{db}{$class}{$id};
}

sub upd
{
  my $self=shift;
  my $class=shift;
  my $filter;
  if (ref($class))
  {
    $filter=$class;
    $class=ref($class);
  }
  else
  {
    $filter=shift;
  }
  my $value=shift;
  die 'usage: $db->upd( { $class,$filterhash | $obj } , $valuehash )' 
    unless ref($filter) && ref($value);
  # warn dump $filter;
  my @out;
  for my $item ($self->get($class,$filter))
  {
    for my $var (keys %$value)
    {
      $item->{$var}=$value->{$var};
    }
    $item->{_mtime}=time;
    push @out, $item;
  }
  $self->{_mtime}=time;
  return @out;
}

sub get
{
  my ($self,$class,$filter)=@_;
  die 'usage: $db->get($class,$filterhash)'
    unless ref($filter);
  return $self->getordel($class,$filter);
}

sub del
{
  my $self=shift;
  my $class=shift;
  my $filter;
  if (ref($class))
  {
    $filter=$class;
    $class=ref($class);
  }
  else
  {
    $filter=shift;
  }
  die 'usage: $db->del({$class,$filterhash}|{$obj})'
    unless ref($filter);
  return $self->getordel($class,$filter,'delete');
}

sub getordel
{
  my ($self,$class,$filter,$delete)=@_;
  # warn "$class ". dump($filter);
  my @out;
  for my $id (keys %{$self->{db}{$class}})
  {
    my $match=1;
    my $item=$self->{db}{$class}{$id};
    next unless $item;
    # see if this item reference is the same as the filter reference
    unless ($item eq $filter)
    {
      # look for a value match instead
      for my $var (keys %$filter)
      {
	# item doesn't contain this var -- no match
	do { $match=0;last } unless exists($item->{$var});
	# accept if both are undef
	next unless (defined($filter->{$var}) || defined($item->{$var}));
	# bail if only one is undef
	unless (defined($filter->{$var}) && defined($item->{$var}))
	{
	  $match=0;
	  last;
	}
	unless ($filter->{$var} eq $item->{$var})
	{
	  # item contains var but the value doesn't match
	  # ...so check for a regex match
	  if (ref($filter->{$var}) eq 'Regexp')
	  {
	    next if $item->{$var} =~ $filter->{$var};
	  }
	  # okay, give up
	  $match=0;
	  last;
	}
      }
    }
    next unless $match;
    if ($delete)
    {
      # hang onto the item reference so we can return it
      push @out, $item;
      # ...then delete the item
      delete $self->{db}{$class}{$id};
      $self->{_mtime}=time;
    }
    else
    {
      push @out, $item if $item;
    }
  }

  # warn dump (@out);
  # warn "returning ".scalar(@out)." items";
  return @out;
}

sub allclass
{
  my ($self,$class)=@_;
  die 'usage: $db->all($class)' unless $class;
  my @out;
  for my $id (keys %{$self->{db}{$class}})
  {
    push @out, $self->{db}{$class}{$id};
  }
  return @out;
}

1;
