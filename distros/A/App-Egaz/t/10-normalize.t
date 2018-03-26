use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help normalize)] );
like( $result->stdout, qr{normalize}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(normalize)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(normalize t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(normalize t/default.lav)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 357, 'line count' );
like( $result->stdout, qr{normalize-lav 0 0}, 'd stanza matched' );

$result
    = test_app( 'App::Egaz' => [qw(normalize t/partition.t.lav --tlen 18803 -o stdout)] );
my $expect = join "", Path::Tiny::path("t/partition.t.norm.lav")->lines;
is( $result->stdout, $expect, 'matched with expect' );

$result
    = test_app( 'App::Egaz' => [qw(normalize t/partition.q.lav --tlen 18803 --qlen 22929 -o stdout)] );
$expect = join "", Path::Tiny::path("t/partition.q.norm.lav")->lines;
is( $result->stdout, $expect, 'matched with expect' );

done_testing();
