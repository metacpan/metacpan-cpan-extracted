################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;
use Convert::Binary::C::Cached;

$^W = 1;

BEGIN {
  plan tests => 11;
}

my $CCCFG = require 'tests/include/config.pl';

eval { require Data::Dumper }; $Data_Dumper = $@;
eval { require IO::File };     $IO_File = $@;

if( $Data_Dumper or $IO_File ) {
  my $req;
  $req = 'IO::File' if $IO_File;
  $req = 'Data::Dumper' if $Data_Dumper;
  $req = 'Data::Dumper and IO::File' if $Data_Dumper && $IO_File;
  skip( "caching requires $req", 0 ) for 1 .. 11;
  exit;
}
else { ok(1) }

eval { my @dummy = times };
if( $@ ) {
  print "# no times() funtion, trying Time::HiRes...\n";
  eval {
    require Time::HiRes;
    *main::mytime = \&Time::HiRes::time;
    $required_time = 5;
    $time_per_test = 1;
  };
  if( $@ ) {
    print "# can't load Time::HiRes, using time()...\n";
    *main::mytime = sub { time };
    $required_time = 20;
    $time_per_test = 4;
  }
}
else {
  print "# using times() for timing...\n";
  *main::mytime = sub { my @t = times; $t[0]+$t[1] };
  $required_time = 5;
  $time_per_test = 1;
}

$cache = 'tests/cache.cbc';

-e $cache and unlink $cache;

# check "normal" C::B::C object
$tests = 5;
$next_test_time = 0;
$iterations = 0;
$start_time = mytime();
$fail = 0;
do {
  eval {
    $c = new Convert::Binary::C %$CCCFG;
    $c->parse_file( 'tests/include/include.c' );
  };
  $@ and $fail = 1 and last;
  $iterations++;
  $elapsed_time = mytime() - $start_time;

  # this is just to prevent the user from stopping the test
  if( $elapsed_time >= $next_test_time and $tests > 0 ) {
    $tests--;
    $next_test_time += $time_per_test;
    ok(1);
  }
} while( $elapsed_time < $required_time );

ok(1) while $tests-- > 0;

ok( $fail, 0, "failed to perform reference speed test ($@)" );

print "# uncached: $iterations iterations in $elapsed_time seconds\n";

# create cache file
eval {
  $c = new Convert::Binary::C::Cached Cache => $cache, %$CCCFG;

  $c->parse_file( 'tests/include/include.c' );
};
ok($@,'',"failed to create cache file for speed test");

# not ok if cache file doesn't exist now
ok( -e $cache );

# check cached object (this should be a lot faster)
$start_time = mytime();
eval {
  for( 1 .. $iterations ) {
    $c = new Convert::Binary::C::Cached Cache => $cache, %$CCCFG;
    $c->parse_file( 'tests/include/include.c' );
  }
};

ok( $@, '', "failed to perform cached speed test ($@)" );

$cached_time = mytime() - $start_time;
$speedup = $cached_time < 0.001 ? 1000 : $elapsed_time / $cached_time;

print "# cached: $iterations iterations in $cached_time seconds\n";
print "# speedup is $speedup\n";

# a speedup of 2 is acceptable
ok( $speedup > 2 );

-e $cache and unlink $cache;
