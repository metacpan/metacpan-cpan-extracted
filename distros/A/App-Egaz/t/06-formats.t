use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help formats)] );
like( $result->stdout, qr{formats}, 'descriptions' );

$result
    = test_app( 'App::Egaz' => [qw(formats)] );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 10, 'line count' );

done_testing();
