# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1;
use Daemon::DaemonizeLight 'daemonize';

sub run_check {
  eval { daemonize };
  return $@;
}

my $die_val="Dont`t know input parameter ''
Try to restart,start,stop\n";

is(run_check, $die_val, 'check default die'); 


