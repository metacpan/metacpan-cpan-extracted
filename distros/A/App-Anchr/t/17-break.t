#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help break --range 1-4)] );
like( $result->stdout, qr{break}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(break --range 1-4)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(break t/not_exists --range 1-4)] );
like( $result->error, qr{need .+input file}, 'need 2 infiles' );

$result = test_app( 'App::Anchr' => [qw(break t/not_exists t/not_exists --range 1-4)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

{
    # real run
    my $tempdir = Path::Tiny->tempdir;
    test_app( 'App::Anchr' =>
            [ qw(overlap2 t/1_4.anchor.fasta t/1_4.pac.fasta), "-d", $tempdir->stringify, ] );

    $result = test_app(
        'App::Anchr' => [
            qw(break --range 1-4),
            $tempdir->child("anchorLong.db")->stringify,
            $tempdir->child("anchorLong.ovlp.tsv")->stringify,
        ]
    );

    ok( $tempdir->child("breaks.fasta"), 'breaks.fasta exists' );
}

done_testing();
