package Test2::Require::NotWindows;

use strict;
use warnings;
use base qw( Test2::Require );

sub skip
{
  return 'Test unreliable on windows' if $^O eq 'MSWin32';
  return;
}

1;
