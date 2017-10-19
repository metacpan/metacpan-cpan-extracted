#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;    # `anchr cover` calls `anchr show2ovlp` to write outputs

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help trimlong)] );
like( $result->stdout, qr{trimlong}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(trimlong)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(trimlong t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(trimlong t/1_4.pac.fasta -v -o stdout)] );
is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ), 3, 'stderr line count' );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{pac4745_7148}s, 'original names' );
unlike( $result->stdout, qr{pac4745_7148:1}s, 'uncovered region' );

$result = test_app(
    'App::Anchr' => [
        qw(trimlong t/1_4.pac.fasta -v -o stdout),
        "--jvm", "'-d64 -server'"
    ]
);
is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ), 3, 'stderr line count' );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stderr, qr{jar-with-dependencies}s, 'path of jrange jar' );

done_testing();
