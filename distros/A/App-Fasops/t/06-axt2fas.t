use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help axt2fas)] );
like( $result->stdout, qr{axt2fas}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(axt2fas)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(axt2fas t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(axt2fas t/example.axt -t Scer-S288c)] );
like( $result->error, qr{alphanumeric}, 'check --tname' );

$result = test_app( 'App::Fasops' => [qw(axt2fas t/example.axt -q RM11-1a)] );
like( $result->error, qr{alphanumeric}, 'check --qname' );

$result = test_app( 'App::Fasops' => [qw(axt2fas t/example.axt -s t/RM11_1a.chr)] );
like( $result->error, qr{doesn't exist}, 'check --size' );

$result = test_app( 'App::Fasops' => [qw(axt2fas t/example.axt -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );
like( $result->stdout, qr{target\.I.+query\.scaffold_14.+target\.I.+query.scaffold_17}s,
    'name list' );

$result
    = test_app( 'App::Fasops' => [qw(axt2fas t/example.axt -t S288c -q RM11_1a -l 100 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 4, 'line count' );
like( $result->stdout, qr{S288c\.I.+RM11_1a\.scaffold_17}s, 'change names' );

$result = test_app( 'App::Fasops' =>
        [qw(axt2fas t/example.axt -t S288c -q RM11_1a -s t/RM11_1a.chr.sizes -o stdout)] );
like( $result->stdout, qr{3634-3714.+22732-22852}s, 'change positions' );

done_testing(11);
