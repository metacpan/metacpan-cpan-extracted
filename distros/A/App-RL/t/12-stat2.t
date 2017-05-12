use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help stat2 -s t/chr.sizes)] );
like( $result->stdout, qr{stat2}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(stat2)] );
like( $result->error, qr{Mandatory parameter.+size}, 'need --size' );

$result = test_app( 'App::RL' => [qw(stat2 -s t/chr.sizes)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(stat2  -s t/chr.sizes t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::RL' => [qw(stat2  -s t/chr.sizes t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result
    = test_app(
    'App::RL' => [qw(stat2 --op intersect t/intergenic.yml t/repeat.yml -s t/chr.sizes -o stdout)]
    );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 18, 'line count' );
is( ( scalar( split ",", ( split( /\n/, $result->stdout ) )[1] ) ), 8, 'field count' );
like( $result->stdout, qr{36721},   'sum exists' );
like( $result->stdout, qr{I.+XVI}s, 'chromosomes exist' );

$result
    = test_app( 'App::RL' =>
        [qw(stat2 --op intersect t/intergenic.yml t/repeat.yml -s t/chr.sizes --all -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
is( ( scalar( split ",", ( split( /\n/, $result->stdout ) )[1] ) ), 7, 'field count' );
like( $result->stdout, qr{36721}, 'sum exists' );
unlike( $result->stdout, qr{I.+XVI}s, 'chromosomes do not exist' );

$result
    = test_app( 'App::RL' =>
        [qw(stat2 --op intersect t/Atha.yml t/Atha.trf.yml -s t/Atha.chr.sizes --all --mk -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 6, 'line count' );
is( ( scalar( split ",", ( split( /\n/, $result->stdout ) )[1] ) ), 8, 'field count' );
like( $result->stdout, qr{116}, 'intersection exists' );

done_testing();
