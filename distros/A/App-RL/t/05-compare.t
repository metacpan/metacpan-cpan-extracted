use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help compare)] );
like( $result->stdout, qr{compare}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(compare)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(compare t/not_exists)] );
like( $result->error, qr{need two or more input files}, 'need infiles' );

$result = test_app( 'App::RL' => [qw(compare t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result
    = test_app( 'App::RL' => [qw(compare --op intersect t/intergenic.yml t/repeat.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 17, 'line count' );
like( $result->stdout, qr{878539\-878709}, 'runlist exists' );
like( $result->stdout, qr{I:.+XVI:}s, 'chromosomes exist' );

$result = test_app( 'App::RL' => [qw(compare --op intersect --mk t/Atha.yml t/Atha.trf.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{1071\-1272}, 'runlist exists' );

$result = test_app( 'App::RL' => [qw(compare --op xor --mk t/Atha.yml t/Atha.trf.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{1025\-1070}, 'runlist exists' );

done_testing();
