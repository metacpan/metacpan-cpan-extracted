use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help sort)] );
like( $result->stdout, qr{sort}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(sort t/II.links.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 15, 'line count' );
unlike( $result->stdout, qr{^[VX]\w+\(}m, 'chromosome II first' );

done_testing();
