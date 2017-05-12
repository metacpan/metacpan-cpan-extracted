use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help concat)] );
like( $result->stdout, qr{concat}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(concat)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(concat t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::Fasops' => [qw(concat t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(concat t/example.fas t/example.name.list -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
is( length( ( grep {/\S/} split( /\n/, $result->stdout ) )[3] ), 239, 'line length' );
like( $result->stdout, qr{\>Spar\n.+\>YJM789\n}s, 'correct name order' );
unlike( $result->stdout, qr{\>YJM789\n.+\>Spar\n}s, 'incorrect name order' );

$result = test_app(
    'App::Fasops' => [qw(concat t/example.fas t/example.name.list --relaxed -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
is( length( ( grep {/\S/} split( /\n/, $result->stdout ) )[2] ),
    length("YJM789") + 1 + 239,
    'line length'
);

$result = test_app(
    'App::Fasops' => [qw(concat t/example.fas t/example.name.list --total 100 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
is( length( ( grep {/\S/} split( /\n/, $result->stdout ) )[3] ), 239 - 63, 'line length' );

done_testing();
