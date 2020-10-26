#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;

use App::Dazz;

my $result = test_app( 'App::Dazz' => [qw(help group --range 1-4)] );
like( $result->stdout, qr{group}, 'descriptions' );

$result = test_app( 'App::Dazz' => [qw(group --range 1-4)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Dazz' => [qw(group t/not_exists --range 1-4)] );
like( $result->error, qr{need .+input file}, 'need 2 infiles' );

$result = test_app( 'App::Dazz' => [qw(group t/not_exists t/not_exists --range 1-4)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "dazz and its deps not installed", 2
        unless IPC::Cmd::can_run('dazz')
            or IPC::Cmd::can_run('faops')
            or IPC::Cmd::can_run('fasta2DB')
            or IPC::Cmd::can_run('LAshow')
            or IPC::Cmd::can_run('ovlpr');

    my $tempdir = Path::Tiny->tempdir;
    test_app( 'App::Dazz' =>
            [ qw(overlap2 t/1_4.anchor.fasta t/1_4.pac.fasta), "-d", $tempdir->stringify, ] );

    $result = test_app(
        'App::Dazz' => [
            qw(group --png --range 1-4),
            $tempdir->child("anchorLong.db")->stringify,
            $tempdir->child("anchorLong.ovlp.tsv")->stringify,
        ]
    );

    ok( $tempdir->child("group")->is_dir,              'output directory exists' );
    ok( $tempdir->child("group")->child("groups.txt"), 'groups.txt exists' );
}

done_testing();
