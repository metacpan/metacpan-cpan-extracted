use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help filter)] );
like( $result->stdout, qr{filter}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(filter t/II.connect.tsv -n 2 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );

$result = test_app( 'App::Rangeops' => [qw(filter t/II.connect.tsv -n 3 -r 0.99 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
unlike( $result->stdout, qr{^VI\(}m, 'filtered links' );

done_testing();
