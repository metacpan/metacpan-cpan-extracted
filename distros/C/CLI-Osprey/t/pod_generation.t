use strict;
use warnings;

use Test::More;

use lib 't/lib';

use PodApp;

my $app = PodApp->new;

my( undef, $usage ) = $app->parse_options;

my $pod = $usage->option_pod;

like $pod, qr/some description pod/, 'description_pod is present';
like $pod, qr/some extra pod/, 'extra_pod is present';

done_testing();
