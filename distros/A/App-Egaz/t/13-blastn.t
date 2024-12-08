use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help blastn)] );
like( $result->stdout, qr{blastn}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(blastn)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(blastn t/not_exists)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(blastn t/not_exists t/pseudopig.fa)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "makeblastdb or blastn not installed", 5
        unless IPC::Cmd::can_run('makeblastdb')
        and IPC::Cmd::can_run('blastn');

    $result = test_app( 'App::Egaz' => [qw(blastn t/pig2.fa t/pseudopig.fa --verbose)] );
    is( $result->error, undef, 'threw no exceptions' );
    is( ( scalar grep { !/^#/ } grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
    ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 1, 'line count with comments' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stderr ) ), 2, 'stderr line count' );
    like( $result->stdout, qr{pig2\tpig2}, 'target exists' );
}

done_testing();
