
use Time::HiRes qw(tv_interval gettimeofday);
use Test::More skip_all => "need to deal with forking tests";
use Data::Dumper;
use Cache::BDB;
use File::Path qw(rmtree);

use strict;

my $kids = 15; # number of children to spawn
my $iterations = 15; # number of times each kid should do its thing
my $rows = 120; # number of rows each child should write, then read

my %options = (
	cache_root => './t/03',
	cache_file => "one.db",
	namespace => "Cache::BDB::lock",
#	default_expires_in => 10,
);	
END {

}

# create a cache object so the environment is already in place, but then undef
# it so we don't give each child multiple handles

my @pids = ();
for(my $i = 0; $i <= $kids; $i++) {
    if(my $pid = fork() ) {
	push @pids, $pid;
    } else {
	run_child();
    }
}

diag("spawned $kids children " . join(', ', @pids));

foreach my $kid (@pids) {
    waitpid($kid, 0);
    diag("$kid done");
}

my $r = Cache::BDB->new(%options);
diag("found " . $r->count() . " records");
is($r->count(), $rows);

sub run_child {
  my $t0 = [gettimeofday];
  
  my %results;
  my $c = Cache::BDB->new(%options);

  my @ids;

  for my $it (0 .. $iterations) {
    for (my $j = 1; $j <= $rows; $j++) {
      #	my $r = ($j ** $it)  x 4;
#      sleep 1 if $$ % 2 == 0;      

      my $lk = $c->{__db}->cds_lock;
#      diag("$$: locked, setting row $j");
      
      my $rv = $c->set($j, $$);
      $lk->cds_unlock();
#      diag("$$: unlocked");
      #diag("$$: set $j");
      push @ids, $j;
      
    }
  }
  

  diag("$$: getting $rows rows $iterations times");
  for(0 .. $iterations) {
    for(@ids) {
      
      my $rv = $c->get($_);
      #diag("$$: got $rv for $_") unless $$ eq $rv;
      $results{$$}->{$_} = $rv;
    }
  }
  
  my $t1 = [gettimeofday];
  diag("$$: finished in " . tv_interval($t0, $t1) .  " seconds");
  #    diag(Dumper \%results);
  exit 0;
}

