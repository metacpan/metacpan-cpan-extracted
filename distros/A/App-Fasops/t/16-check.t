use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help check)] );
like( $result->stdout, qr{check}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(check)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(check t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::Fasops' => [qw(check t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "samtools not installed", 4 unless IPC::Cmd::can_run('samtools');

    $result
        = test_app(
        'App::Fasops' => [qw(check t/Arabid_thaliana.pair.fas t/NC_000932.fa -o stdout)] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 3, 'line count' );
    like( $result->stdout, qr{\tOK.+\tOK.+\tFAILED$}s, 'two OK and one FAILED' );

    $result
        = test_app( 'App::Fasops' =>
            [qw(check t/Arabid_thaliana.pair.fas t/NC_000932.fa --name Arabid_thaliana -o stdout)]
        );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
    like( $result->stdout, qr{\tOK.+\tOK$}s, 'two OK' );
}

done_testing(8);
