use strict;
use warnings;
use Test::More;

use_ok('App::PerlGlue');

my $exit = App::PerlGlue->run('version');
is($exit, 0, 'version command exits successfully');

done_testing;
