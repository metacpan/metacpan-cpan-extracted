use strict;
use warnings;

use Test::More tests => 1;

my $module;

BEGIN {
  $module = 'DBIx::Migration';
  use_ok( $module ) or BAIL_OUT "Cannot load module '$module'!";
}
