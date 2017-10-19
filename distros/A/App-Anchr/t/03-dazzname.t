#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help dazzname)] );
like( $result->stdout, qr{dazzname}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(dazzname)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(dazzname t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(dazzname t/1_4.anchor.fasta --prefix B-A:D -o stdout)] );
like( $result->error, qr{Can't accept}, 'bad names' );

$result = test_app( 'App::Anchr' => [qw(dazzname t/1_4.anchor.fasta -o B-A:D)] );
like( $result->error, qr{Can't accept}, 'bad names' );

$result = test_app( 'App::Anchr' => [qw(dazzname t/1_4.anchor.fasta -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
like( $result->stdout, qr{read\/1}s, 'default prefix' );
like( $result->stdout, qr{1624.+1626.+6430.+9124}s, 'original orders' );

$result = test_app( 'App::Anchr' => [qw(dazzname --start 10 t/1_4.anchor.fasta -o stdout)] );
unlike( $result->stdout, qr{read\/1\/}s, 'not start from 1' );
like( $result->stdout, qr{read\/10\/}s, 'start from 10' );

done_testing();
