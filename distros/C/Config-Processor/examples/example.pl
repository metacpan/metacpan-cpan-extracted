#!/usr/bin/env perl

use strict;
use warnings;

use Config::Processor;
use Data::Dumper;

my $config_processor = Config::Processor->new(
  dirs       => [qw( examples/etc )],
  export_env => 1,
);

# Load all configuration sections
my $config = $config_processor->load(
  qw( dirs.yml db.json ),

  { myapp => {
      db => {
        connectors => {
          stat_master => {
            host => 'localhost',
            port => '4321',
          },
        },
      },
    },
  },
);

# Print full config tree
print Dumper( $config );
