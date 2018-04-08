use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help multiz)] );
like( $result->stdout, qr{multiz}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(multiz)] );
like( $result->error, qr{need .+input}, 'need inputs' );

$result = test_app( 'App::Egaz' => [qw(multiz t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'inputs not exists' );

$result = test_app( 'App::Egaz' => [qw(multiz t/Q_rubravsQ_aliena t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'inputs not exists' );

$result = test_app( 'App::Egaz' => [qw(multiz t/Q_rubravsQ_aliena --tree t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'inputs not exists' );

SKIP: {
    skip "multiz not installed", 2 unless IPC::Cmd::can_run('multiz');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app( 'App::Egaz' => [ "multiz", "$t_path/Q_rubravsQ_aliena", "-o", "." ] );
    like( $result->stderr, qr{.maf.gz files: \[1\]}, 'STDERR: file count' );
    like( $result->stderr, qr{too few species},      'STDERR: too few species' );
    ok( $tempdir->child("NC_020152.synNet.maf.gz")->is_file, 'maf file exists' );

    chdir $cwd;    # Won't keep tempdir
}

SKIP: {
    skip "multiz not installed", 4 unless IPC::Cmd::can_run('multiz');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app(
        'App::Egaz' => [
            "multiz",                           "$t_path/Q_rubravsQ_aliena",
            "$t_path/Q_rubravsQ_aquifolioides", "$t_path/Q_rubravsQ_baronii", "--tree",
            "$t_path/Quercus.nwk"
        ]
    );
    like( $result->stderr, qr{Q_rubra appears 3 times},              'STDERR: find target' );
    like( $result->stderr, qr{Target chromosomes are \[NC_020152\]}, 'STDERR: target chromosomes' );
    like( $result->stderr, qr{outdir set to \[Q_rubra_n4\]},         'STDERR: set --outdir' );
    like(
        $result->stderr,
        qr{Order of stitch \[Q_aliena Q_aquifolioides Q_baronii\]},
        'STDERR: Order of stitch'
    );
    ok( $tempdir->child("Q_rubra_n4/info.yml")->is_file,         'info.yml exists' );
    ok( $tempdir->child("Q_rubra_n4/steps.csv")->is_file,        'steps.csv exists' );
    ok( $tempdir->child("Q_rubra_n4/NC_020152.maf.gz")->is_file, '.maf.gz exists' );

    my @csv_lines = grep {/\S+/} Path::Tiny::path("Q_rubra_n4/steps.csv")->lines;
    is( scalar @csv_lines, 3, 'csv line count' );
    is( $csv_lines[0], "step,spe1,spe2,maf1,maf2,out1,out2,size,per_size\n", 'csv header' );

    chdir $cwd;    # Won't keep tempdir
}

SKIP: {
    skip "multiz not installed", 3 unless IPC::Cmd::can_run('multiz');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app(
        'App::Egaz' => [
            "multiz", "$t_path/Q_rubravsQ_aliena", "$t_path/Q_rubravsQ_aquifolioides",
            "--target", "Q_rubra"
        ]
    );
    like( $result->stderr, qr{Assigned target \[Q_rubra\] is OK}, 'STDERR: assigned target OK' );

    $result = test_app(
        'App::Egaz' => [
            "multiz",                           "$t_path/Q_rubravsQ_aliena",
            "$t_path/Q_rubravsQ_aquifolioides", "--target",
            "Q_aliena"
        ]
    );
    like( $result->error, qr{Assigned target \[Q_aliena\] isn't OK},
        'STDERR: assigned target NOK' );
    like( $result->error, qr{It should be \[Q_rubra\]}, 'STDERR: correct target' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
