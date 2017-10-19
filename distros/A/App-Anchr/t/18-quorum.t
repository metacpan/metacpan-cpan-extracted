#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help quorum)] );
like( $result->stdout, qr{quorum}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(quorum)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(quorum t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(quorum t/R1.fq.gz t/R2.fq.gz -a t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'adapter file not exists' );

$result = test_app( 'App::Anchr' => [qw(quorum t/R1.fq.gz t/R2.fq.gz -o stdout)] );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 150, 'line count' );
like( $result->stdout, qr{masurca.+Estimating}s, 'bash contents' );

done_testing();
