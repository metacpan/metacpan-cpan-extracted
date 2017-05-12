use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help replace)] );
like( $result->stdout, qr{replace}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(replace)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(replace t/not_exists)] );
like( $result->error, qr{need two input files}, 'need infiles' );

$result = test_app( 'App::Fasops' => [qw(replace t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(replace t/example.fas t/replace.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 32, 'line count' );
like( ( split /\n\n/, $result->stdout )[2], qr{\>S288c.+\>query}s, 'correct name order' );

$result = test_app( 'App::Fasops' => [qw(replace t/example.fas t/replace.fail.tsv -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );
unlike( $result->stdout, qr{target|query}, 'not replaced' );
like( $result->stderr, qr{multiply records}, 'error message' );

$result = test_app( 'App::Fasops' => [qw(replace t/example.fas t/replace.remove.tsv -o stdout)] );
print $result->stdout;
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 16, 'line count' );
unlike( $result->stdout, qr{13267\-13287}s, 'block removed' );

done_testing();
