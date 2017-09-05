use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Capture::Tiny qw( capture );

use App::Prove;
use App::Prove::Plugin::RandomSeed;

is exception {
    my $app = App::Prove->new;
    App::Prove::Plugin::RandomSeed->load( { app_prove => $app, args => [] } );

    my ( $stdout_get, $stderr_get ) = capture { $app->_shuffle };
    like $stdout_get, qr/Randomized with seed \d+/, "get random seed";
    is $stderr_get, "", "no error output";

    my ($seed) = $stdout_get =~ /\d+/;

    App::Prove::Plugin::RandomSeed->load(
        { app_prove => $app, args => [$seed] } );
    my ( $stdout_set, $stderr_set ) = capture { $app->_shuffle };
    is $stderr_set, $stderr_get, 'set random seed';
    is $stderr_get, "", "no error output";
},
    undef,
    'no exception';

done_testing;

