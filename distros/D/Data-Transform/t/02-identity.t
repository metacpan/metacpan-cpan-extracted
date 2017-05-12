#!/usr/bin/perl -w
use strict;
use lib qw(t/);

use TestFilter;
use Test::More tests => 18 + $COUNT_FILTER_INTERFACE + $COUNT_FILTER_STANDARD;

use_ok("Data::Transform::Identity");
test_filter_interface("Data::Transform::Identity");

my $filter = Data::Transform::Identity->new;
isa_ok($filter, 'Data::Transform::Identity');
my @test_fodder = qw(a bc def ghij klmno);

# General test
test_filter_standard(
  $filter,
  [qw(a bc def ghij klmno)],
  [qw(a bc def ghij klmno)],
  [qw(a bc def ghij klmno)],
);

# Specific tests for stream filter

{ my $received = $filter->get( \@test_fodder );
  is_deeply($received, \@test_fodder, "received each item discretely");
}

{ my $sent = $filter->put( \@test_fodder );
  is_deeply($sent, \@test_fodder, "sent each item discretely");
}

{ $filter->get_one_start( \@test_fodder );
  pass("get_one_start didn't die or anything");
}

{ my $pending = $filter->get_pending();
  is_deeply($pending, \@test_fodder, "pending data is correct");
}

for (1 .. @test_fodder)
{ my $received = $filter->get_one();
  is_deeply($received, [ shift @test_fodder ], "get_one() got the right one, baby, uh-huh");
  my $pending = $filter->get_pending();
  if (@test_fodder) {
    is_deeply($pending, \@test_fodder, "pending data is correct");
  } else {
    is($pending, undef, "pending data is empty");
  }
}

{ my $received = $filter->get_one();
  is_deeply($received, [ ], "get_one() returned an empty array on empty buffer");
}

{ my $received = $filter->get([0]);
  is_deeply($received, [ 0 ], "got false value");
}
exit;
