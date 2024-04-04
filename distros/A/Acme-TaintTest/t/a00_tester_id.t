#!/usr/bin/perl -T

# This test outputs information about the testing machine to help fingerprint it in the test report
# and tries to make the error in tempdir happen, using the most mininal subset of SATest for init

use lib '.'; use lib 't';
use a00_init; t_init("a00_tester");

use v5.14.0;
use strict;
use warnings;

use Cwd;
use Config;
use File::Spec;
use File::Temp;
use POSIX;
use Net::Address::Ethernet qw(get_addresses);

use Scalar::Util qw(tainted);

use Test::More tests => 2;

# ---------------------------------------------------------------------------

# Output various id information for this computer
# in an attempt to have something that uniquely identifies
# the machine that is running these tests
# so future runs on the same tester can be correlated

sub _get_machine_id {
  ## DEBUG - ID the machine so we know which tester is having the problems
  my $machineid = "unknown";
  if (open(my $file, '<', "/etc/machine-id")) { 
    $machineid = <$file>; 
    close $file;
    chomp $machineid;
  }
  return $machineid;
}

sub _get_active_mac_addresses {
    return join("; ", map ($_->{'sEthernet'}, grep ($_->{'iActive'} && $_->{'sEthernet'} && $_->{'sIP'}, get_addresses())));
}

sub _get_uname_string {
  return join("; ", POSIX::uname());
}

my $tname = 'a00_tester';;

sub debug_testtaint {
  my $testtaint = File::Spec->catdir("log", "$tname.XXXXXX");
  if (tainted($testtaint)) {
    diag("catdir tainted '$testtaint'\nFile::Spec ", File::Spec->VERSION, "\nFile::Temp ", File::Temp->VERSION, "\n" . Config::myconfig());
    return 0;
  }
  return 1;
}

diag("\ncwd is ", Cwd::cwd, "\n");
diag "\nINC is '@INC'\nPATH is '$ENV{'PATH'}\n";
diag("\nMachine ID: ", _get_machine_id(), "\nMAC addresses ", _get_active_mac_addresses(), "\nuname: ", _get_uname_string(), "\n");

ok(debug_testtaint(), 'test taint problem with catdir');

# now check the same kind of tempdir call that is failing in SATest
my $workdir = File::Temp::tempdir("$tname.XXXXXX", DIR => "log");
ok((-d $workdir), 'tempdir test');
