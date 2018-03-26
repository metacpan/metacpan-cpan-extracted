use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help lav2axt)] );
like( $result->stdout, qr{lav2axt}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(lav2axt)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lav2axt t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(lav2axt t/default.lav -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 30, 'line count' );
like( $result->stdout, qr{TCGCTCCACGGCGAAA--TAAGCGCACGAACCGG}, 'sequences' );

$result = test_app( 'App::Egaz' => [qw(lav2axt t/default.relative.lav -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 30, 'line count' );
like( $result->stdout, qr{TCGCTCCACGGCGAAA--TAAGCGCACGAACCGG}, 'sequences' );

SKIP: {
    skip "samtools not installed", 3 unless IPC::Cmd::can_run('samtools');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app( 'App::Egaz' => [ "lav2axt", "$t_path/default.lav", qw(-o default.axt) ] );
    ok( $tempdir->child("default.axt")->is_file, 'axt file exists' );

    system "fasops axt2fas default.axt -o default.fas";
    ok( $tempdir->child("default.fas")->is_file, 'fas file exists' );

    Path::Tiny::path("$t_path/pseudocat.fa")->copy("pseudocat.fa");
    $result = `fasops check default.fas pseudocat.fa --name target -o stdout`;
    unlike( $result, qr{\tFAILED\n}, "fasops check" );

    chdir $cwd;    # Won't keep tempdir
}

done_testing(10);
