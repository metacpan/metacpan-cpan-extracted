use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help blastmatch)] );
like( $result->stdout, qr{blastmatch}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(blastmatch)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(blastmatch t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "makeblastdb or blastn not installed", 4
        unless IPC::Cmd::can_run('makeblastdb')
        and IPC::Cmd::can_run('blastn');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app(
        'App::Egaz' => [ "blastn", "$t_path/pig2.fa", "$t_path/pseudopig.fa", "-o", "pig.blast", ]
    );
    ok( $tempdir->child("pig.blast")->is_file, 'pig.blast exists' );

    $result = test_app( 'App::Egaz' => [qw(blastmatch pig.blast)] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stderr ) ), 5, 'stderr line count' );
    is( ( scalar grep { !/^#/ } grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
    like( $result->stdout, qr{pig2:1-22929}, 'target exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
