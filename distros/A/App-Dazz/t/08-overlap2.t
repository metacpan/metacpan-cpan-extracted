#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;   # `dazz overlap2` calls `dazz show2ovlp` to write outputs

use App::Dazz;

my $result = test_app( 'App::Dazz' => [qw(help overlap2)] );
like( $result->stdout, qr{overlap2}, 'descriptions' );

$result = test_app( 'App::Dazz' => [qw(overlap2)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Dazz' => [qw(overlap2 t/1_4.anchor.fasta t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "dazz and its deps not installed", 2
        unless IPC::Cmd::can_run('dazz')
            or IPC::Cmd::can_run('faops')
            or IPC::Cmd::can_run('fasta2DB')
            or IPC::Cmd::can_run('LAshow')
            or IPC::Cmd::can_run('ovlpr');

    my $tempdir = Path::Tiny->tempdir;
    $result = test_app( 'App::Dazz' =>
            [ qw(overlap2 t/1_4.anchor.fasta t/1_4.pac.fasta), "-d", $tempdir->stringify, ] );

    ok( $tempdir->child("anchorLong.db")->is_file,       'dazz DB exists' );
    ok( $tempdir->child("anchorLong.ovlp.tsv")->is_file, 'result file exists' );
}

done_testing();
