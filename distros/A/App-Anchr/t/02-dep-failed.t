#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Anchr;

$ENV{PATH} = '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin';

diag("The following warnings are expected.");

my $result;
$result = test_app( 'App::Anchr' => [qw(dep)] );
like( $result->stdout, qr{Failed}, 'Check basic infrastructures' );

done_testing();
