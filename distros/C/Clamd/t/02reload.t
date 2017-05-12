use strict;
use Test;
BEGIN { plan tests => 3 }
use Clamd;

do "t/mkconf.pl";

# start clamd
my $pid = fork;
die "Fork failed" unless defined $pid;
if (!$pid) {
    exec "$ENV{CLAMD_PATH}/clamd -c clamav.conf";
    die "Clamd failed to start: $!";
}
for (1..10) {
  last if (-e "clamsock");
  if (kill(0 => $pid) == 0) {
    die "Clamd appears to have died";
  }
  sleep(1);
}

my $clamd = Clamd->new(port => "clamsock");
ok($clamd);
ok($clamd->reload);

ok(kill(9 => $pid), 1);
waitpid($pid, 0);
unlink("clamsock");

