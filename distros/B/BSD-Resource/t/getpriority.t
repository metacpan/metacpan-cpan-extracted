#
# getpriority.t
#

use BSD::Resource;

$debug = 1;

print "1..3\n";

# AIX without BSD libs has 0..39 priorities, not -20..20.

my $okpriosub_std = sub { -20 <= $_[0] && $_[0] <= 20 };
my $okpriosub_aix = sub {   0 <= $_[0] && $_[0] <= 39 };
my $okpriosub = sub { &$okpriosub_std($_[0]) || ($^O eq 'aix' && &$okpriosub_aix($_[0]))};

$nowprio1 = getpriority(PRIO_PROCESS, 0);

print "# nowprio1 = $nowprio1\n" if ($debug);

print 'not ' unless (&$okpriosub($nowprio1));
print "ok 1\n";

$nowprio2 = getpriority(PRIO_PROCESS);

print "# nowprio2 = $nowprio2\n" if ($debug);

print 'not ' unless ($nowprio1 == $nowprio2 && &$okpriosub($nowprio2));
print "ok 2\n";

$nowprio3 = getpriority();

print "# nowprio3 = $nowprio3\n" if ($debug);

print 'not ' unless ($nowprio2 == $nowprio3 && &$okpriosub($nowprio3));
print "ok 3\n";

# eof
