use Time::HiRes qw(tv_interval gettimeofday);
use Test::More skip_all => "need to deal with forking tests";
use Cache::BDB;
use strict;

my $kids = 5; # number of children to spawn
my $iterations = 1; # number of times each kid should do its thing
my $rows = 10; # number of rows each child should write, then read

my %options1 = (
	cache_root => './t/03',
	cache_file => "two.db",
	namespace => "Cache::BDB::envlock1",
	env_lock => 1,
	default_expires_in => 100,
    );	
    
my %options2 = (
	cache_root => "./t/03",
	cache_file => "two.db",
	namespace => "Cache::BDB::envlock2",
	env_lock => 1,
	default_expires_in => 100,
    );	

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

my $c = Cache::BDB->new(%options2);
diag("found " . $c->count() . " records");
is($c->count(), $rows);

sub run_child {
    my %options1 = (
	cache_root => "./t/03", 
	cache_file => "two.db",
	namespace => "Cache::BDB::envlock1",
	env_lock => 1,
	default_expires_in => 100,
    );	
    
    my %options2 = (
	cache_root => "./t/03", 
	cache_file => "two.db",
	namespace => "Cache::BDB::envlock2",
	env_lock => 1,
	default_expires_in => 100,
    );	

    my $t0 = [gettimeofday];
    my $c1 = Cache::BDB->new(%options1);
    my $c2 = Cache::BDB->new(%options2);

    for (0 .. $iterations) {
	for (my $j = 1; $j <= $rows; $j++) {
	    my $r = $j x 4;
	    
	    my $rv1 = $c1->set($j, { $j => $r} );
	    diag("$$ faild to write $j => $r") if $rv1;
	    is($rv1, '');

	    my $rv2 = $c2->set($j, { $j => $r} );
	    diag("$$ faild to write $j => $r") if $rv2;
	    is($rv2, '');
	    
	    $rv1 = $c1->get($j);
	    diag("$$ faild to read $j => $r") unless
		is_deeply($rv1, { $j => $r});

	    $rv2 = $c2->get($j);
	    diag("$$ faild to read $j => $r") unless
		is_deeply($rv2, { $j => $r});

	}
    }
    my $t1 = [gettimeofday];
    diag("$$: " . tv_interval($t0, $t1) .  " seconds");
    exit;
}

