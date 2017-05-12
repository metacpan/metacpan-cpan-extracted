use 5.008000;
use strict;
use warnings;

use Test::More tests => 3;

my $T_CLASS;

BEGIN {
  $T_CLASS = 'Config::Processor';
  use_ok($T_CLASS);
}

can_ok( $T_CLASS, 'new' );
my $config_processor = new_ok($T_CLASS);
