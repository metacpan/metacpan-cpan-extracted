use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help slice)] );
like( $result->stdout, qr{slice}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(slice)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(slice t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::Fasops' => [qw(slice t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(slice t/slice.fas t/slice.yml -n S288c -l 2 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 6, 'line count' );
like( $result->stdout, qr{13301\-13400.+2511\-2636}s, 'sliced' );

done_testing();
