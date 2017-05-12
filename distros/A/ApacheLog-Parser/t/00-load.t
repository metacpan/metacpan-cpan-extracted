
use warnings;
use strict;

use Test::More tests => 5;

my $package = 'ApacheLog::Parser';

foreach my $mod ($package, map({$package . '::' . $_} qw(
  SkipList
  Report
))) {
  eval("require $mod");
  my $err = $@;
  ok(! $err, 'load ok');
  if($err) {
    warn $err, "\n";
    BAIL_OUT("cannot load $mod STOP!");
  }
}

foreach my $prog (map({"bin/$_"} qw(loghack cron.loghack))) {
  eval("require './$prog'");
  my $err = $@;
  ok(! $err, 'load ok');
  if($err) {
    warn $err, "\n";
    BAIL_OUT("cannot load $prog STOP!");
  }
}

eval {require version};
diag("Testing $package ", $package->VERSION );

# vim:syntax=perl:ts=2:sw=2:et:sta
