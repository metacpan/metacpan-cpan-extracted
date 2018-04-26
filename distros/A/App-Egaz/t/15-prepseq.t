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
    skip "faops or faToTwoBit or samtools not installed", 12
        unless IPC::Cmd::can_run('faops')
        and IPC::Cmd::can_run('faToTwoBit')
        and IPC::Cmd::can_run('samtools');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app( 'App::Egaz' => [ "prepseq", "$t_path/pseudopig.fa", "-v", ] );
    is( $result->stdout, '', 'no stdout' );
    is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ),
        5, '5 commands executed' );
    like( $result->stderr, qr{outdir}, 'default --outdir' );
    ok( $tempdir->child("pig1.fa")->is_file,       'pig1.fa exists' );
    ok( $tempdir->child("pig2.fa")->is_file,       'pig2.fa exists' );
    ok( $tempdir->child("chr.sizes")->is_file,     'chr.sizes exists' );
    ok( $tempdir->child("chr.2bit")->is_file,      'chr.2bit exists' );
    ok( $tempdir->child("chr.fasta")->is_file,     'chr.fasta exists' );
    ok( $tempdir->child("chr.fasta.fai")->is_file, 'chr.fasta.fai exists' );

    $tempdir->child("chr.sizes")->remove;
    $tempdir->child("chr.2bit")->remove;
    $tempdir->child("chr.fasta")->remove;
    $tempdir->child("chr.fasta.fai")->remove;

    $result = test_app( 'App::Egaz' => [ "prepseq", ".", "-v", ] );
    is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ),
        6, '6 commands executed' );
    ok( $tempdir->child("chr.sizes")->is_file, 'chr.sizes exists' );
    ok( $tempdir->child("chr.2bit")->is_file,  'chr.2bit exists' );

    chdir $cwd;    # Won't keep tempdir
}

SKIP: {
    skip "faops or faToTwoBit or RepeatMasker not installed", 6
        unless IPC::Cmd::can_run('faops')
        and IPC::Cmd::can_run('faToTwoBit')
        and IPC::Cmd::can_run('RepeatMasker');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app(
        'App::Egaz' => [
            "prepseq", "$t_path/pseudopig.fa", "--about", "1000000",
            "--min", "1", "-v", "--repeatmasker", "--gff --parallel 2"
        ]
    );
    ok( !$tempdir->child("pig1.fa")->is_file,   'pig1.fa not exists' );
    ok( $tempdir->child("000.fa")->is_file,     '000.fa exists' );
    ok( $tempdir->child("000.rm.out")->is_file, '000.rm.out exists' );
    ok( $tempdir->child("000.rm.gff")->is_file, '000.rm.gff exists' );
    ok( $tempdir->child("chr.sizes")->is_file,  'chr.sizes exists' );
    ok( $tempdir->child("chr.2bit")->is_file,   'chr.2bit exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
