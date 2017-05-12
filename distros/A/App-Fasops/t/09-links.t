use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help links)] );
like( $result->stdout, qr{links}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(links)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(links t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(links t/example.fas --pair -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 18, 'line count' );
like( $result->stdout, qr{S288c.+\tYJM789}, 'name list' );

$result = test_app( 'App::Fasops' => [qw(links t/example.fas --best -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 9, 'line count' );
like( $result->stdout, qr{S288c.+\tYJM789}, 'name list' );

$result = test_app( 'App::Fasops' => [qw(links t/example.fas -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
like( $result->stdout, qr{S288c.+\tYJM789.+\tRM11.+Spar}, 'names in one line' );

done_testing();
