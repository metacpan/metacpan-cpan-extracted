#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help kunitigs)] );
like( $result->stdout, qr{kunitigs}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(kunitigs)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Anchr' => [qw(kunitigs t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Anchr' => [qw(kunitigs t/R1.fq.gz t/environment.json -o stdout)] );
ok( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ) > 50, 'line count' );
like( $result->stdout, qr{Colors.+Build}s, 'bash contents' );

done_testing();
