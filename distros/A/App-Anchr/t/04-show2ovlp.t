#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help show2ovlp)] );
like( $result->stdout, qr{show2ovlp}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(show2ovlp)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(show2ovlp t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(show2ovlp t/1_4.renamed.fasta t/1_4.show.txt -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 50, 'line count' );
like( $result->stdout, qr{overlap}s, 'overlaps' );

$result = test_app(
    'App::Anchr' => [qw(show2ovlp t/1_4.renamed.fasta t/1_4.show.txt -r t/not_exists -o stdout)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' =>
        [qw(show2ovlp t/1_4.renamed.fasta t/1_4.show.txt -r t/1_4.replace.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 50, 'line count' );
like( $result->stdout, qr{pac7556_20928}s, 'original name' );

done_testing();
