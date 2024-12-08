use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help blastlink)] );
like( $result->stdout, qr{blastlink}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(blastlink)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(blastlink t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "makeblastdb or blastn not installed", 5
        unless IPC::Cmd::can_run('makeblastdb')
        and IPC::Cmd::can_run('blastn');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app(
        'App::Egaz' => [
            "blastn",                    "$t_path/Q_rubra.multi.fas",
            "$t_path/Q_rubra.multi.fas", "-o",
            "Q_rubra.blast",
        ]
    );
    ok( $tempdir->child("Q_rubra.blast")->is_file, 'Q_rubra.blast exists' );

    $result = test_app( 'App::Egaz' => [qw(blastlink Q_rubra.blast)] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stderr ) ), 2, 'stderr line count' );
    is( ( scalar grep { !/^#/ } grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
    like( $result->stdout, qr{90542-116412.+135434-161304}, 'forward match' );
    like( $result->stdout, qr{135434-161304.+90542-116412}, 'reverse match' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
