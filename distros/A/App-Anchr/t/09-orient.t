#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;    # `anchr orient` calls `anchr show2ovlp` to write outputs

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help orient)] );
like( $result->stdout, qr{orient}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(orient)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(orient t/1_4.pac.fasta t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app(
    'App::Anchr' => [qw(orient t/1_4.anchor.fasta t/1_4.pac.fasta -r t/not_exists -o stdout)] );
like( $result->error, qr{doesn't exist}, 'restrict file not exists' );

$result = test_app( 'App::Anchr' =>
        [qw(orient t/1_4.anchor.fasta t/1_4.pac.fasta -r t/1_4.2.restrict.tsv -v -o stdout)] );
is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ), 9, 'stderr line count' );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );
like( $result->stdout, qr{pac4745_7148}s, 'original names' );

done_testing();
