use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help names)] );
like( $result->stdout, qr{names}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(names)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(names t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(names t/example.fas -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
like( $result->stdout, qr{S288c\s+YJM789\s+RM11\s+Spar}, 'name list' );

$result = test_app( 'App::Fasops' => [qw(names t/example.fas -c -o stdout)] );
like( $result->stdout, qr{S288c\t3.+Spar\t3}s, 'name count' );

done_testing();
