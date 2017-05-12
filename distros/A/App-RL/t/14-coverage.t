use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help coverage -s t/chr.sizes)] );
like( $result->stdout, qr{coverage}, 'descriptions' );


$result = test_app( 'App::RL' => [qw(coverage)] );
like( $result->error, qr{Mandatory parameter.+size}, 'need --size' );

$result = test_app( 'App::RL' => [qw(coverage -s t/chr.sizes)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(coverage -s t/chr.sizes t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::RL' => [qw(coverage t/S288c.txt -s t/chr.sizes -m 1 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 21, 'line count' );
unlike( $result->stdout, qr{S288c},  'species names' );
unlike( $result->stdout, qr{1\-100}, 'covered' );
like( $result->stdout, qr{1\-150}, 'covered' );

$result = test_app( 'App::RL' => [qw(coverage t/S288c.txt -s t/chr.sizes -m 5 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 23, 'line count' );
unlike( $result->stdout, qr{S288c},  'species names' );
unlike( $result->stdout, qr{1\-100}, 'covered' );
like( $result->stdout, qr{101\-150}, 'depth 1' );
like( $result->stdout, qr{90\-100}, 'depth 2' );

done_testing();
