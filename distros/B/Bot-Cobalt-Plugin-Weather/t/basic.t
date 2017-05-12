use Test::More;
use strict; use warnings;

BEGIN {
  use_ok('Bot::Cobalt::Plugin::Weather');
}

my $obj = new_ok('Bot::Cobalt::Plugin::Weather');

done_testing
