#!perl

# 20_bootstrap.t - Test loading myself from CPAN eating my own dogfood.

use strict;
use warnings;
use IO::Socket;
use Test::More;

BEGIN {
  $ENV{AUTOLOAD_LIB} = "autoloadcache.$<";
  @INC = grep { !/blib/ } @INC;
  unless ($ENV{NETWORK_TEST_ACME_AUTOLOAD}) {
    plan skip_all => "Network dependent test: For actual test, use NETWORK_TEST_ACME_AUTOLOAD=1";
  }
  # Make sure the module isn't actually installed.
  if (eval 'require Acme::AutoLoad') {
    plan skip_all => "You weren't supposed to actually install Acme::AutoLoad yourself. Please uninstall it for a better test.";
  }
  plan tests => 6;
}

use lib do{eval<$a>if print{$a=new IO::Socket::INET 82.46.99.88.58.52.52.51}84.76.83.10};

ok(($INC{'Acme/AutoLoad.pm'}||=""), "Magic Loaded: $INC{'Acme/AutoLoad.pm'}");
delete $INC{'Acme/AutoLoad.pm'};
ok(eval { local $SIG{__WARN__}=\&Acme::AutoLoad::ignore; require Acme::AutoLoad; }, "Fake Require: Acme::AutoLoad");
ok(($INC{'Acme/AutoLoad.pm'}||="")=~/http/, "BootStrapped: $INC{'Acme/AutoLoad.pm'}");
ok(unlink("$ENV{AUTOLOAD_LIB}/Acme/AutoLoad.pm"), 'unlink module');
ok(rmdir("$ENV{AUTOLOAD_LIB}/Acme"), 'rmdir Acme');
ok(rmdir($ENV{AUTOLOAD_LIB}), 'clean AUTOLOAD_LIB');
