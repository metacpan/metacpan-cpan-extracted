#!/usr/bin/perl

use v5.14;
use utf8;

use Test::More;
use App::Cmd::Tester;

use Boxer::CLI;

use strictures 2;
no warnings "experimental::signatures";

my $result = test_app( 'Boxer::CLI' => [qw(help)] );

like( $result->stdout, qr/Available commands:/, 'printed what we expected' );

is( $result->stderr, '', 'nothing sent to sderr' );

is( $result->error, undef, 'threw no exceptions' );

done_testing();
