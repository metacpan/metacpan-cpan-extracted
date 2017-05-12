use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help span)] );
like( $result->stdout, qr{span}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(span)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(span t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::RL' => [qw(span t/brca2.yml --op cover -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{32316461\-32398770}, 'cover' );

$result = test_app( 'App::RL' => [qw(span t/brca2.yml --op fill -n 1000 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{32325076\-32326613}, 'fill' );

$result = test_app( 'App::RL' => [qw(span --op holes --mk t/Atha.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 11, 'line count' );
like( $result->stdout, qr{3914\-3995}, 'runlist exists' );

$result = test_app( 'App::RL' => [qw(span --op excise -n 100 --mk t/Atha.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 11, 'line count' );
unlike( $result->stdout, qr{7157\-7232}, 'runlist excised' );

$result = test_app( 'App::RL' => [qw(span --op trim -n 50 --mk t/Atha.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 11, 'line count' );
unlike( $result->stdout, qr{7157\-7232}, 'runlist excised' );

done_testing();
