use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result;

$result = test_app( 'App::Fasops' => [qw(help consensus)] );
like( $result->stdout, qr{consensus}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(consensus)] );
like( $result->error, qr{need .+input}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(consensus t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "poa not installed", 4 unless IPC::Cmd::can_run('poa');

    $result = test_app( 'App::Fasops' => [qw(consensus t/refine.fas -o stdout)] );
    is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
    like( $result->stdout, qr{>consensus$}m,   'simple name' );
    like( $result->stdout, qr{>consensus\.I}m, 'fas name' );

    $result = test_app( 'App::Fasops' => [qw(consensus t/refine.fas --outgroup -p 2 -o stdout)] );
    is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
}

done_testing();
