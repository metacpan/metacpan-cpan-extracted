use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help prepseq)] );
like( $result->stdout, qr{prepseq}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(prepseq)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(prepseq t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "faops or faToTwoBit not installed", 9
        unless IPC::Cmd::can_run('faops')
        and IPC::Cmd::can_run('faToTwoBit');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app( 'App::Egaz' => [ "prepseq", "$t_path/pseudopig.fa", "-v", ] );
    is( $result->stdout, '', 'no stdout' );
    is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ),
        3, '3 commands executed' );
    like( $result->stderr, qr{outdir}, 'default --outdir' );
    ok( $tempdir->child("pig1.fa")->is_file,   'pig1.fa exists' );
    ok( $tempdir->child("chr.sizes")->is_file, 'chr.sizes exists' );
    ok( $tempdir->child("chr.2bit")->is_file,  'chr.2bit exists' );

    $tempdir->child("chr.sizes")->remove;
    $tempdir->child("chr.2bit")->remove;
    $result = test_app( 'App::Egaz' => [ "prepseq", ".", "-v", ] );
    is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ),
        2, '3 commands executed' );
    ok( $tempdir->child("chr.sizes")->is_file, 'chr.sizes exists' );
    ok( $tempdir->child("chr.2bit")->is_file,  'chr.2bit exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
