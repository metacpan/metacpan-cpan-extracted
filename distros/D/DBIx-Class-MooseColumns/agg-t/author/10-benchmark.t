#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

use FindBin;
use Path::Class;
use lib dir($FindBin::Bin)->parent->parent->subdir('t', 'lib')->stringify;

use Test::DBIx::Class;
use Test::Benchmark;
use String::Random qw(random_string);

fixtures_ok 'basic', 'installed the basic fixtures from configuration files';

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  #TODO is there a way to find where the sub was declared? (other than redirecting and filtering Devel::Peek output)
}

my $read_speed_ratio  = $ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE} ? 0.25 : 0.95;
my $write_speed_ratio = $ENV{DBIC_MOOSECOLUMNS_NON_INLINABLE} ? 0.50 : 0.90;

{
  my $artist1 = Schema->resultset('Artist')->find({ artist_id => 1 });

  is_faster(1 / $read_speed_ratio, -3,
    sub {
      my $dummy = $artist1->phone;
    },
    sub {
      my $dummy = $artist1->address;
    },
    "The read speed of the Moose accessor is at least 95% of the CAG accessor"
  );

  is_faster(1 / $write_speed_ratio, -3,
    sub {
      $artist1->phone(random_string("."));
    },
    sub {
      $artist1->address(random_string("."));
    },
    "The write speed of the Moose accessor is at least 90% of the CAG accessor"
  );
}

done_testing;
