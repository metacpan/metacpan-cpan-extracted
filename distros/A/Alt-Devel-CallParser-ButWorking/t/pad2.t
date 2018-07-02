use warnings;
use strict;

use Test::More tests => 1;

use Devel::CallParser;

sub f {
  my $arg = shift;

  { my $arg; } # ???
  ok($arg, '$arg stays set after a "my $arg" block');
}

f(1);
