use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help lav2psl)] );
like( $result->stdout, qr{lav2psl}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(lav2psl)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lav2psl t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result
    = test_app( 'App::Egaz' => [qw(lav2psl t/default.lav -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 10, 'line count' );
like( $result->stdout, qr{2144\t1422\t0\t0\t30\t94\t28\t164\t\-}, 'last line matched' );

my $expect = join "", grep {/^\d/} Path::Tiny::path("t/default.psl")->lines;
is( $result->stdout, $expect, 'matched with expect' );

done_testing();
