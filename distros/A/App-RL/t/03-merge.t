use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help merge)] );
like( $result->stdout, qr{merge}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(merge)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(merge t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::RL' => [qw(merge t/I.yml t/II.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 5, 'line count' );
like( $result->stdout, qr{28547\-29194}, 'runlist exists' );

like( $result->stdout, qr{I:.+II:}s, 'chromosomes exist' );

done_testing();
