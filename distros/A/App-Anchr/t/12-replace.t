#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help replace)] );
like( $result->stdout, qr{replace}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(replace)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(replace t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(replace t/1_4.ovlp.tsv t/1_4.replace.tsv -r -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 50, 'line count' );
unlike( $result->stdout, qr{pac6425_4471}, 'replaced' );
like( $result->stdout, qr{falcon_read\/12\/0_4471}, 'replaced' );

$result = test_app( 'App::Anchr' => [qw(replace t/1_4.ovlp.tsv t/1_4.replace.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 50, 'line count' );
like( $result->stdout, qr{pac6425_4471}, 'not replaced' );
unlike( $result->stdout, qr{falcon_read\/12\/0_4471}, 'not replaced' );

done_testing();
