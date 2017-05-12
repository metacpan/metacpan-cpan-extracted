use strict;
use warnings;
use Test::More;

use_ok 'App::envfile';
my $envf = new_ok 'App::envfile';
isa_ok $envf, 'App::envfile';

done_testing;
