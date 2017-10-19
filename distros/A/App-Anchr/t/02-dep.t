#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

my $result = test_app( 'App::Anchr' => [qw(help dep)] );
like( $result->stdout, qr{dep}, 'descriptions' );

$result = test_app( 'App::Anchr' => [qw(dep t/not_exists)] );
like( $result->error, qr{need no input}, 'need no inputs' );

$result = test_app( 'App::Anchr' => [qw(dep)] );
like( $result->stdout, qr{OK: find}, 'Check basic infrastructures' );

$result = test_app( 'App::Anchr' => [qw(dep --install)] );
like( $result->stdout, qr{install_dep},                'install_dep.sh' );
like( $result->stdout, qr{all dependances installed},  'all dependances installed' );
like( $result->stdout, qr{cpanm},                      'cpanm' );
like( $result->stdout, qr{all Perl modules installed}, 'all Perl modules installed' );

done_testing();
