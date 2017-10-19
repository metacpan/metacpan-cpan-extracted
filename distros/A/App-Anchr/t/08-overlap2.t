#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;   # `anchr overlap2` calls `anchr show2ovlp` to write outputs

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help overlap2)] );
like( $result->stdout, qr{overlap2}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(overlap2)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(overlap2 t/1_4.anchor.fasta t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

{    # real run
    my $tempdir = Path::Tiny->tempdir;
    $result = test_app( 'App::Anchr' =>
            [ qw(overlap2 t/1_4.anchor.fasta t/1_4.pac.fasta), "-d", $tempdir->stringify, ] );

    ok( $tempdir->child("anchorLong.db")->is_file,       'dazz DB exists' );
    ok( $tempdir->child("anchorLong.ovlp.tsv")->is_file, 'result file exists' );
}

done_testing();
