use Test::More;
use strict;
use warnings;

use Articulate::TestEnv;
use Articulate::Service;
use FindBin;
my $app = app_from_config();

my $verbs = $app->components->{'service'}->enumerate_verbs;

is( ref $verbs, ref [] );

done_testing;
