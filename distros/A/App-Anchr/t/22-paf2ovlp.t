#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help paf2ovlp)] );
like( $result->stdout, qr{paf2ovlp}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(paf2ovlp)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(paf2ovlp t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(paf2ovlp t/1_4.pac.paf -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 28, 'line count' );
like( $result->stdout, qr{overlap}s, 'overlaps' );

done_testing();
