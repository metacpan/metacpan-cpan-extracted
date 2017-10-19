#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help scaffold)] );
like( $result->stdout, qr{scaffold}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(scaffold)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(scaffold t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(scaffold t/merge.fasta t/R1.fq.gz -o stdout)] );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 50, 'line count' );
like( $result->stdout, qr{Colors.+scaffold}s, 'bash contents' );

done_testing();
