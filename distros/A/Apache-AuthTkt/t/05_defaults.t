# Testing defaults, including parse_conf values

use File::Basename;
use Test::More tests => 15;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

# Load result strings
my $test = 't05';
my %result = ();
$test = "t/$test" if -d "t/$test";
die "missing data dir $test" unless -d $test;
opendir DATADIR, "$test" or die "can't open $test";
for my $f (readdir DATADIR) {
  next if $f =~ m/^\./;
  open FILE, "<$test/$f" or die "can't read $test/$f";
  {
      local $/ = undef;
      $result{$f} = <FILE>;
  }
  close FILE;
  chomp $result{$f};
}
close DATADIR;

# This allows you to specify a test to stop at, dumping the result
my $print = shift @ARGV || 0;
my $t = 4;
sub report {
  my ($data, $file, $inc) = @_;
  $inc ||= 1;
  if ($print == $t) {
    print STDERR "--> $file\n";
    print "$data\n";
    exit 0;
  }
  $t += $inc;
}

my ($at, $at2, $at3, $ticket, $cookie);
my $ts = 1108811260;
my $conf = dirname($0) . "/t05/01_auth_tkt.conf";
my $conf2 = dirname($0) . "/t05/02_auth_tkt.conf";
my $conf3 = dirname($0) . "/t05/03_auth_tkt.conf";
$ENV{REMOTE_ADDR} = '192.168.0.1';

# Setup
ok($at = Apache::AuthTkt->new(conf => $conf), 'conf constructor ok');
is($at->secret, 'bf07982e-a551-43cc-9d41-2f050a22e229', 'secret() ok');
is($at->ignore_ip, 1, '$at has ignore_ip true');
ok($at2 = Apache::AuthTkt->new(conf => $conf2), 'conf constructor ok');
is($at2->secret, 'bf07982e-a551-43cc-9d41-2f050a22e229', 'secret() ok');
is($at2->ignore_ip, 0, '$at has ignore_ip false');
ok($at3 = Apache::AuthTkt->new(conf => $conf3), 'conf constructor ok');
is($at3->secret, 'X,08d307810@R5%&aa49e7e0d9f0c9 ,X530023FB*e0941f1dkjf188797,tdt', 'secret() ok');

# Setup some reference tickets
my $remote_addr_tkt = $at->ticket(ts => $ts, ip_addr => $ENV{REMOTE_ADDR});
my $ignore_addr_tkt = $at->ticket(ts => $ts, ip_addr => undef);
my $ignore_addr_tkt2 = $at->ticket(ts => $ts, ip_addr => '0.0.0.0');
is($ignore_addr_tkt, $ignore_addr_tkt2, 'ignore_addr tickets match');
isnt($remote_addr_tkt, $ignore_addr_tkt, 'reference tickets differ');
#print "remote_addr_tkt: $remote_addr_tkt\n";
#print "ignore_addr_tkt: $ignore_addr_tkt\n";

# TKTAuthIgnoreIP test
$ticket = $at->ticket(ts => $ts);
is($ticket, $ignore_addr_tkt, 'unspecified ip_addr honours IgnoreIP on');
$ticket = $at2->ticket(ts => $ts);
is($ticket, $remote_addr_tkt, 'unspecified ip_addr honours IgnoreIP off');

# Setup some reference cookies
my $cookie1 = $at->cookie(ts => $ts, cookie_name => 'foobar', cookie_domain => 'example.com', cookie_secure => 1);
my $cookie2 = $at2->cookie(ts => $ts, cookie_name => 'fubah', cookie_secure => 0);
#print $cookie2 . "\n";

# Cookie defaults
$cookie = $at->cookie(ts => $ts);
is($cookie, $cookie1, 'cookie defaults honoured from 01_auth_tkt.conf');
$cookie = $at2->cookie(ts => $ts);
is($cookie, $cookie2, 'cookie defaults honoured from 02_auth_tkt.conf');


# vim:ft=perl

