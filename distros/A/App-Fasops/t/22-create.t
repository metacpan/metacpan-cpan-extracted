use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help create -g t/genome.fa)] );
like( $result->stdout, qr{create}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(create -g t/genome.fa)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(create -g t/genome.fa t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "samtools not installed", 4 unless IPC::Cmd::can_run('samtools');

    $result
        = test_app(
        'App::Fasops' => [qw(create t/I.connect.tsv -g t/genome.fa -o stdout)]
    );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
    like( $result->stdout, qr{tgtgtgggtgtggtgtgg}m, 'revcom sequences' );

    $result
        = test_app(
        'App::Fasops' => [qw(create t/I.connect.tsv -g t/genome.fa --name S288c -o stdout)]
    );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
    like( $result->stdout, qr{S288c}m, 'default names' );
}

done_testing();
