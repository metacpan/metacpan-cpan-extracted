use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Capture::Tiny qw( capture );

use App::Prove;

is exception {
    my $app = App::Prove->new;
    $app->process_args( '--norc', '-j1', '-PCumulativeTimer', 'tests' );
    my ( $stdout_get, $stderr_get ) = capture { $app->run };

    my ($test1_time)
        = $stdout_get =~ /tests[\\\/]test1\.t \.\. ok\s+(\d+) ms/;
    my ($test2_time)
        = $stdout_get =~ /tests[\\\/]test2\.t \.\. ok\s+(\d+) ms/;
    ok $test1_time < $test2_time, 'cumulative elapsed time';

    is $stderr_get, "", "no error output";
},
    undef,
    'no exception';

done_testing;

