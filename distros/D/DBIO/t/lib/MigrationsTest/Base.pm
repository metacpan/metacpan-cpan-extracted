package #hide from pause
  MigrationsTest::Base;

use strict;
use warnings;

# must load before any DBIO* namespaces
use MigrationsTest::RunMode;

sub _skip_namespace_frames { '^MigrationsTest' }

1;
