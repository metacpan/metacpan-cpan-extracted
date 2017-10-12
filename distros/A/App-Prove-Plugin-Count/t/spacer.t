use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Capture::Tiny qw( capture );

use App::Prove;

is exception {
    my $app = App::Prove->new;
    $app->process_args( '--norc', '-j1', '-PCount', 'tests' );

    my ( $stdout_get, $stderr_get ) = capture { $app->run };

    is $stderr_get, "", "no error output";

    like $stdout_get, qr{^\[ 1/10\]}m, 'counter [ 1/10]';
    like $stdout_get, qr{^\[ 2/10\]}m, 'counter [ 2/10]';
    like $stdout_get, qr{^\[ 3/10\]}m, 'counter [ 3/10]';
    like $stdout_get, qr{^\[ 4/10\]}m, 'counter [ 4/10]';
    like $stdout_get, qr{^\[ 5/10\]}m, 'counter [ 5/10]';
    like $stdout_get, qr{^\[ 6/10\]}m, 'counter [ 6/10]';
    like $stdout_get, qr{^\[ 7/10\]}m, 'counter [ 7/10]';
    like $stdout_get, qr{^\[ 8/10\]}m, 'counter [ 8/10]';
    like $stdout_get, qr{^\[ 9/10\]}m, 'counter [ 9/10]';
    like $stdout_get, qr{^\[10/10\]}m, 'counter [10/10]';
},
    undef,
    'no exception';

done_testing;

