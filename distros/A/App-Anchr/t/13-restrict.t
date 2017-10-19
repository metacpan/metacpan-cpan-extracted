#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help restrict)] );
like( $result->stdout, qr{restrict}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(restrict)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(restrict t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(restrict t/1_4.ovlp.tsv t/1_4.restrict.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 36, 'line count' );
unlike( $result->stdout, qr{pac.+pac}, 'no long-long overlaps' );

$result = test_app( 'App::Anchr' => [qw(restrict t/1_4.ovlp.tsv t/1_4.2.restrict.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 28, 'line count' );
unlike( $result->stdout, qr{pac.+pac}, 'no long-long overlaps' );
unlike( $result->stdout, qr{pac7556_20928}, 'no pac7556_20928' );

done_testing();
