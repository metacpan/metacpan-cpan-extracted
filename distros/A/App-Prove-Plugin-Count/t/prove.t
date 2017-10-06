use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Capture::Tiny qw( capture );

use App::Prove;

is exception {
    my $app = App::Prove->new;
    $app->process_args( '--norc', '-PCount', 'tests' );

    my ( $stdout_get, $stderr_get ) = capture { $app->run };

    like $stdout_get, qr{\[1/2\] tests[/\\]test1\.t \.\. ok},
        'add test counts to first test';
    like $stdout_get, qr{\[2/2\] tests[/\\]test2\.t \.\. ok},
        'add test counts to second test';
    is $stderr_get, "", "no error output";
},
    undef,
    'no exception';

done_testing;

