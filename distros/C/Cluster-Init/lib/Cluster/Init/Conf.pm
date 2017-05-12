package Cluster::Init::Conf;
use strict;
use warnings;
use Data::Dump qw(dump);
use Time::HiRes qw(time);
use Carp::Assert;
# use Cluster::Init::DB;
use Cluster::Init::Util qw(debug);
# use Cluster::Init::Daemon;
# use base qw(Cluster::Init::Util);


sub new
{
  my $class = shift;
  my $self = {@_};
  bless $self, $class;
  affirm { $self->{cltab} };
  affirm { $self->{context} };
  $self->{'socket'}||="/var/run/clinit/clinit.s";
  $self->{'clstat'}||="/var/run/clinit/clstat";
  $self->{'log'}||="/var/run/clinit/log";
  return $self;
}

# read cltab process entries by line number
sub line
{
  my $self=shift;
  my $line=shift;
  $self->read_cltab;
  my $raw=${$self->{raw}}[$line];
  my $proc = Cluster::Init::Process->new(%$raw);
  return $proc;
}

# read first cltab process entry
sub firstline
{
  my $self=shift;
  $self->read_cltab;
  my @raw = @{$self->{raw}};
  for (my $i=1; $i < @raw; $i++)
  {
    my $raw=$raw[$i];
    next unless $raw;
    my $proc = Cluster::Init::Process->new(%$raw);
    $self->{prevline}=$i;
    return $proc;
  }
  return undef;
}

# read next cltab process entry
sub nextline
{
  my $self=shift;
  my $line=$self->{prevline} || 1;
  $self->read_cltab;
  my @raw = @{$self->{raw}};
  for (my $i=$line; $i < @raw; $i++)
  {
    my $raw=$raw[$i];
    next unless $raw;
    my $proc = Cluster::Init::Process->new(%$raw);
    $self->{prevline}=$i;
    return $proc;
  }
  return undef;
}


# return highest line number in cltab
sub max
{
  my $self=shift;
  $self->read_cltab;
  my @raw = @{$self->{raw}};
  return @raw - 1;
}

# does not set prevline
# read cltab process entry by tag name
sub tag
{
  my $self=shift;
  my $tag=shift;
  $self->read_cltab;
  my @raw = @{$self->{raw}};
  my $raw;
  for $raw (@raw)
  {
    next unless $raw;
    next unless $raw->{tag} eq $tag;
    my $proc = Cluster::Init::Process->new(%$raw);
    return $proc;
  }
  return undef;
}

# does not set prevline
# read cltab process entries by group name
sub group
{
  my $self=shift;
  my $group=shift;
  affirm { $group };
  $self->read_cltab;
  my @raw = @{$self->{raw}};
  # warn dump "@raw";
  my @proc;
  for my $raw (@raw)
  {
    next unless $raw;
    next unless $raw->{group} eq $group;
    my $proc = Cluster::Init::Process->new(%$raw);
    push @proc, $proc;
  }
  return @proc;
}

# get a configuration variable
sub get
{
  my $self=shift;
  my $var=shift;
  # cltab overrides everything
  $self->read_cltab;
  return $self->{$var};
}

sub read_cltab
{
  my $self=shift;
  my $cltab = $self->{'cltab'};
  unless (-f $cltab)
  {
    warn "file not found: $cltab\n";
    $self->{msg}="file not found: $cltab\n";
    $self->{ok}=1;
    return $self->{ok};
  }
  my $mtime=(stat($cltab))[9] || die $!;
  $self->{'cltab_mtime'} = 0 unless $self->{'cltab_mtime'};
  return $self->{ok} unless $mtime >  $self->{'cltab_mtime'};
  $self->{'cltab_mtime'} = $mtime;
  debug "reading cltab $cltab, PWD is $ENV{PWD}";
  my @tag;
  $self->{ok}=1;
  $self->{raw}=[];
  open(ITAB,"<$cltab") || die $!;
  while(<ITAB>)
  {
    next if /^#/;
    next if /^\s*$/;
    chomp;
    # deal with master config items
    if (/^:::(.+?):(.+)$/)
    {
      my ($var,$val) = ($1,$2);
      $self->{$var}=$val;
      debug "$var = $val";
      next;
    }
    # clients don't need to deal with anything past here
    next unless $self->{'context'} eq 'server';
    my ($group,$tag,$level,$mode,$cmd) = split(':',$_,5);
    debug "$group $tag $level $mode $cmd";
    if (grep /^$tag$/, @tag)
    {
      debug "entry has duplicate tag: $tag";
      $self->{msg}="entry has duplicate tag: $tag";
      $self->{ok}=0;
      next;
    }
    push @tag, $tag;
    my $raw = 
    {
      line=>$.,
      group=>$group,
      tag=>$tag,
      level=>$level,
      mode=>$mode,
      cmd=>$cmd
    };
    ${$self->{raw}}[$.]=$raw;
  }
  debug dump $self->{raw};
  close ITAB;
  return $self->{ok};
}

1;
