
use Event qw(one_event loop unloop);
use Cluster::Init::DB;
use Cluster::Init::Process;
use Time::HiRes qw(time);

our $cltab="t/cltab";
`cp t/cltab.master $cltab`;

sub lines
{
  $DB::single=1;
  open(F,"<t/out") || die $!;
  my @F=<F>;
  my $lines=$#F + 1;
  return $lines;
}

sub lastline
{
  open(F,"<t/out") || die $!;
  my @F=<F>;
  chomp(my $lastline=$F[$#F]);
  return $lastline;
}

sub step
{
  my $steps=shift;
  for(1..$steps)
  {
    one_event(0);
  }
}

sub run
{
  my $seconds=shift;
  Event->timer(at=>time() + $seconds,cb=>sub{unloop()});
  loop();
}

my $slowdown=1;
sub go
{
  my ($dfa,$state,$timeout)=@_;
  $timeout||=1;
  $timeout*=$slowdown;
  my $debug = $ENV{DEBUG} || 0;
  my $start=time();
  my $stop=$start+$timeout;
  until($dfa->state eq $state)
  {
    # warn "state=".$dfa->state."\n" if $debug > 1;
    step(1);
    if (time > $stop)
    {
      # my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(1);
      my $subline = (caller(0))[2];
      warn "timeout after $timeout secs: $subline wanted $state got ".$dfa->state;
      last;
    }
  }
  # warn "state=".$dfa->state."\n" if $debug > 1;
  if ($dfa->state eq $state)
  {
    # try to adjust for slow CPUs, debug performance, etc.
    my $stop=time();
    my $elapsed=$stop-$start;
    $slowdown*=($elapsed/($timeout*.5)) if $elapsed > ($timeout/2);
    # warn "slowdown $slowdown\n";
    return 1;
  }

  return 0;
}

sub tags
{
  my $db=shift;
  my @cktag = sort @_;
  # warn $db;
  my @all=$db->allclass("Cluster::Init::Process");
  my @tag = sort map {$_->{tag}} @all;
  # warn "@tag";
  return 0 unless @cktag==@tag;
  for(my $i=0;$i<@tag;$i++)
  {
    return 0 unless $tag[$i] eq $cktag[$i];
  }
  return 1;
}

sub waitdown
{
  while(1)
  {
    my $count = `ps -eaf 2>/dev/null | grep perl | grep $0 | grep -v defunct | grep -v runtests | grep -v grep | wc -l`;
    chomp($count);
    # warn "$count still running";
    last if $count==1;
    run(1);
  }
}

sub waitline
{
  my ($line,$timeout)=@_;
  $timeout||=15;
  my $start=time;
  while(1)
  {
    open(F,"<t/out") || die $!;
    my @F=<F>;
    my $lastline=$F[$#F];
    unless ($lastline)
    {
      run(1);
      next;
    }
    chomp($lastline);
    last if $lastline eq $line;
    if ($start + $timeout < time)
    {
      warn "got $lastline wanted $line\n";
      return 0 
    }
    run(1);
  }
  return 1;
}

sub waitstat
{
  my ($init,$group,$level,$state,$timeout)=@_;
  $timeout||=10;
  my $start=time;
  while(1)
  {
    my $out = $init->status();
    # warn $out if $out;
    last if $out =~ /^$group\s+$level\s+$state$/ms;
    # warn "missed";
    return 0 if $start + $timeout < time;
    run(1);
  }
  return 1;
}

sub clwaitstat
{
  my ($clinit,$group,$level,$state,$timeout)=@_;
  $timeout||=10;
  my $start=time;
  while(1)
  {
    my $out = `$clinit -v`;
    # warn $out if $out;
    last if $out =~ /^$group\s+$level\s+$state$/ms;
    return 0 if $start + $timeout < time;
    run(1);
  }
  return 1;
}

1;

__END__
# create a scratch conf
our $utildb = Cluster::Init::DB->new;

$utildb->ins(Cluster::Init::Process->new
    (
     line=>1,
     group=>'foo',
     tag=>'foo1',
     level=>'1',
     mode=>'wait',
     cmd=>'sleep 20'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>2,
     group=>'test',
     tag=>'test1',
     level=>'1',
     mode=>'wait',
     cmd=>'sleep 3'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>3,
     group=>'test',
     tag=>'test2',
     level=>'1',
     mode=>'wait',
     cmd=>'sleep 2'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>4,
     group=>'test',
     tag=>'test3',
     level=>'2',
     mode=>'wait',
     cmd=>'sleep 2'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>5,
     group=>'test',
     tag=>'test4',
     level=>'2',
     mode=>'wait',
     cmd=>'sleep 3'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>6,
     group=>'test',
     tag=>'test5',
     level=>'3',
     mode=>'test',
     cmd=>'true'
    ));

$utildb->ins(Cluster::Init::Process->new
    (
     line=>7,
     group=>'test',
     tag=>'test6',
     level=>'3',
     mode=>'test',
     cmd=>'sleep 1'
    ));

1;
