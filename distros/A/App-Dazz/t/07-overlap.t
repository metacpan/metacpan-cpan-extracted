#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal; # `dazz overlap` calls `dazz show2ovlp` to write outputs

use App::Dazz;

my $result = test_app( 'App::Dazz' => [qw(help overlap)] );
like( $result->stdout, qr{overlap}, 'descriptions' );

$result = test_app( 'App::Dazz' => [qw(overlap)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Dazz' => [qw(overlap t/1_4.pac.fasta t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "dazz and its deps not installed", 7
        unless IPC::Cmd::can_run('dazz')
            or IPC::Cmd::can_run('faops')
            or IPC::Cmd::can_run('fasta2DB')
            or IPC::Cmd::can_run('LAshow')
            or IPC::Cmd::can_run('ovlpr');

    $result = test_app('App::Dazz' => [ qw(overlap t/1_4.pac.fasta -v -o stdout) ]);
    is((scalar grep {/^CMD/} grep {/\S/} split(/\n/, $result->stderr)), 5, 'stderr line count');
    is((scalar grep {/\S/} split(/\n/, $result->stdout)), 18, 'line count');
    like($result->stdout, qr{overlap}s, 'overlaps');
    like($result->stdout, qr{pac4745_7148}s, 'original names');

    $result = test_app('App::Dazz' => [ qw(overlap t/1_4.pac.fasta --idt 0.8 --len 2500 --serial -o stdout) ]);
    is((scalar grep {/\S/} split(/\n/, $result->stdout)), 4, 'line count');
    unlike($result->stdout, qr{pac4745_7148}s, 'serials');

    $result = test_app('App::Dazz' => [ qw(overlap t/1_4.pac.fasta --idt 0.8 --len 2500 --all -o stdout) ]);
    is((scalar grep {/\S/} split(/\n/, $result->stdout)), 42, 'line count');
}

done_testing();
