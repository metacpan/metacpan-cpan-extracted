use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help subset)] );
like( $result->stdout, qr{subset}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(subset)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(subset t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::Fasops' => [qw(subset t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(subset t/example.fas t/example.name.list -o stdout)] );

is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 12, 'line count' );
like( ( split /\n\n/, $result->stdout )[0], qr{\>Spar.+\>YJM789}s, 'correct name order' );
unlike( ( split /\n\n/, $result->stdout )[0], qr{\>YJM789.+\>Spar}s, 'incorrect name order' );

$result
    = test_app(
    'App::Fasops' => [qw(subset t/example.fas t/example.name.list -o stdout --first --required)] );

is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 18, 'line count' );
like( ( split /\n\n/, $result->stdout )[0], qr{\>S288c.+\>Spar.+\>YJM789}s, 'correct name order' );
unlike( ( split /\n\n/, $result->stdout )[0], qr{\>YJM789.+\>Spar}s, 'incorrect name order' );

done_testing();
