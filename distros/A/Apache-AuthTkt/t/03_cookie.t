# Test ticket()

use File::Basename;
use Test::More tests => 11;
BEGIN { use_ok( Apache::AuthTkt ) }
use strict;

# Load result strings
my $test = 't03';
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

my ($at, $ticket, $cookie);
my $ts = 1108811260;
my $conf = dirname($0) . "/t01/mod_auth_tkt.conf";
$ENV{REMOTE_ADDR} = '192.168.0.1';

# Setup
ok($at = Apache::AuthTkt->new(conf => $conf), 'conf constructor ok');
is($at->secret, '0e1d79e1-c18b-43c5-bfd6-a396e13bf39c', 'secret() ok');

# Get ticket
my @targs = (ts => $ts, uid => 'gavin', tokens => 'finance,admin,it');
$ticket = $at->ticket(@targs);
report $ticket, 'ticket';
is($ticket, $result{ticket}, 'ticket ok');

# Get default cookie
$cookie = $at->cookie(@targs);
report $cookie, 'defaults';
is($cookie, $result{defaults}, 'default cookie ok');

# Explicit cookie_name
$cookie = $at->cookie(@targs, cookie_name => 'choc_chip');
report $cookie, 'cookie_name';
is($cookie, $result{cookie_name}, 'explicit cookie_name ok');

# Explicit cookie_domain
$cookie = $at->cookie(@targs, cookie_domain => 'www.openfusion.com.au');
report $cookie, 'cookie_domain1';
is($cookie, $result{cookie_domain1}, 'cookie_domain 1 ok');

$cookie = $at->cookie(@targs, cookie_domain => '.openfusion.com.au');
report $cookie, 'cookie_domain2';
is($cookie, $result{cookie_domain2}, 'cookie_domain 2 ok');

# Explicit cookie_path
$cookie = $at->cookie(@targs, cookie_path => '/secret');
report $cookie, 'cookie_path';
is($cookie, $result{cookie_path}, 'cookie_path ok');

# cookie_secure
$cookie = $at->cookie(@targs, cookie_secure => 1);
report $cookie, 'cookie_secure';
is($cookie, $result{cookie_secure}, 'cookie_secure ok');

# multiple
$cookie = $at->cookie(@targs, cookie_name => 'anzac', cookie_domain => 'www.openfusion.com.au', cookie_secure => 1);
report $cookie, 'multiple';
is($cookie, $result{multiple}, 'multiple ok');


# vim:ft=perl
