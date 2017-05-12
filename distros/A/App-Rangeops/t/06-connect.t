use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Rangeops;

my $result = test_app( 'App::Rangeops' => [qw(help connect)] );
like( $result->stdout, qr{connect}, 'descriptions' );

$result = test_app( 'App::Rangeops' => [qw(connect t/II.clean.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 6, 'line count' );
like( $result->stdout, qr{II.+\tVI.+\tXII}, 'multilateral links' );

done_testing();
