use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help mergecsv)] );
like( $result->stdout, qr{mergecsv}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(mergecsv)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(mergecsv t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(mergecsv t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result
    = test_app( 'App::Fasops' => [qw(mergecsv t/links.copy.csv t/links.count.csv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 5, 'line count' );
unlike( $result->stdout, qr{,count\n}, 'field count absents' );

$result
    = test_app( 'App::Fasops' => [qw(mergecsv t/links.copy.csv t/links.count.csv -c -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 5, 'line count' );
like( $result->stdout, qr{,count\n}, 'field count presents' );

done_testing();
