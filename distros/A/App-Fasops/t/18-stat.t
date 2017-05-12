use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;
use Spreadsheet::XLSX;

my $result = test_app( 'App::Fasops' => [qw(help stat)] );
like( $result->stdout, qr{stat}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(stat)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(stat t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

# population
$result = test_app( 'App::Fasops' => [ qw(stat t/example.fas -o stdout) ] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
like( $result->stdout, qr{,6\n}, 'indels without outgroup' );

$result = test_app( 'App::Fasops' => [ qw(stat t/example.fas -l 50 -o stdout) ] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
like( $result->stdout, qr{,6\n}, 'indels without outgroup' );

# outgroup
$result = test_app( 'App::Fasops' => [ qw(stat t/example.fas --outgroup -o stdout) ] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
like( $result->stdout, qr{,3\n}, 'indels with outgroup' );

done_testing();
