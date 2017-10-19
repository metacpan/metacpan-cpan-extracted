#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

#use App::Cmd::Tester;
use App::Cmd::Tester::CaptureExternal;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help contained)] );
like( $result->stdout, qr{contained}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(contained)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(contained t/1_4.pac.fasta t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(contained t/1_4.anchor.fasta --prefix anchor -v -o stdout)] );
is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ), 3, 'stderr line count' );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
unlike( $result->stdout, qr{anchor576_1624}s, 'original names' );
like( $result->stdout, qr{anchor_0\/1\/}s, 'renamed' );

$result = test_app( 'App::Anchr' => [qw(contained t/contained.fasta -v -o stdout)] );
is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ), 3, 'stderr line count' );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{infile_0\/}s, 'renamed' );

done_testing();
