#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;

use App::Dazz;

my $result = test_app( 'App::Dazz' => [qw(help cover --range 1-4)] );
like( $result->stdout, qr{cover}, 'descriptions' );

$result = test_app( 'App::Dazz' => [qw(cover --range 1-4)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Dazz' => [qw(cover t/not_exists --range 1-4)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "dazz and its deps not installed", 3
        unless IPC::Cmd::can_run('dazz')
            or IPC::Cmd::can_run('faops')
            or IPC::Cmd::can_run('fasta2DB')
            or IPC::Cmd::can_run('LAshow')
            or IPC::Cmd::can_run('ovlpr');

    my $tempdir = Path::Tiny->tempdir;
    test_app( 'App::Dazz' =>
            [ qw(overlap2 t/1_4.anchor.fasta t/1_4.pac.fasta), "-d", $tempdir->stringify, ] );

    $result = test_app( 'App::Dazz' =>
            [ qw(cover --range 1-4), $tempdir->child("anchorLong.ovlp.tsv")->stringify, ] );

    ok( $tempdir->child("meta.cover.json"), 'meta.cover.json exists' );
    ok( $tempdir->child("partial.txt"),     'partial.txt exists' );
    ok( $tempdir->child("coverage.yml"),    'coverage.yml exists' );
}

done_testing();
