use strict;
use warnings;
use Test::More 0.88;

use App::Software::License;

local @ARGV = ('--holder=FooBar');

my $app = App::Software::License->new_with_options;

like $app->notice, qr/^\QThis software is Copyright (c)\E/i,
  'Copyright notice generated';

done_testing;
