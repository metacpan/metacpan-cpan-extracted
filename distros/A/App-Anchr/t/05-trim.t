#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

# 1000 pair of reads
# seqtk sample -s1000 $HOME/data/anchr/e_coli/2_illumina/R1.fq.gz 1000 | pigz > t/R1.fq.gz
# seqtk sample -s1000 $HOME/data/anchr/e_coli/2_illumina/R2.fq.gz 1000 | pigz > t/R2.fq.gz

my $result = test_app( 'App::Anchr' => [qw(help trim)] );
like( $result->stdout, qr{trim}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(trim)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(trim t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(trim t/R1.fq.gz t/R2.fq.gz -a t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'adapter file not exists' );

$result = test_app( 'App::Anchr' => [qw(trim t/R1.fq.gz t/R2.fq.gz -o stdout)] );
is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 67, 'line count' );
like( $result->stdout, qr{scythe.+sickle.+outputs}s, 'bash contents' );

$result = test_app( 'App::Anchr' => [qw(trim t/R1.fq.gz t/R2.fq.gz -b fancy/NAMES -o stdout)] );
like( $result->stdout, qr{fancy\/NAMES}s, 'fancy names' );

$result = test_app( 'App::Anchr' => [qw(trim t/R1.fq.gz t/R2.fq.gz -o stdout --noscythe)] );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) < 70, 'line count' );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 40, 'line count' );
like( $result->stdout, qr{scythe.+sickle.+outputs}s, 'bash contents' );
unlike( $result->stdout, qr{# scythe}s, 'bash contents' );

{    # real run
    my $tempdir = Path::Tiny->tempdir;
    $result = test_app(
        'App::Anchr' => [
            qw(trim t/R1.fq.gz t/R2.fq.gz), "-b",
            $tempdir->stringify . "/R",     "-o",
            $tempdir->child("trim.sh")->stringify,
        ]
    );

    ok( $tempdir->child("trim.sh")->is_file, 'bash file exists' );
    system( sprintf "bash %s", $tempdir->child("trim.sh")->stringify );
    ok( $tempdir->child("R1.fq.gz")->is_file, 'output files exist' );
    ok( $tempdir->child("Rs.fq.gz")->is_file, 'output files exist' );

    #    chdir $tempdir;    # keep tempdir
}

done_testing();
