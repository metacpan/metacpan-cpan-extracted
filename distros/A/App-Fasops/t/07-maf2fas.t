use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help maf2fas)] );
like( $result->stdout, qr{maf2fas}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(maf2fas)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(maf2fas t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(maf2fas t/example.maf -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
like( $result->stdout, qr{S288c\.VIII.+RM11_1a\.scaffold_12.+Spar\.gi_29362578}s, 'name list' );
like( $result->stdout, qr{42072\-42168}, 'change positions' );

$result = test_app( 'App::Fasops' => [qw(maf2fas t/example.maf -l 50 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 8, 'line count' );



done_testing();
