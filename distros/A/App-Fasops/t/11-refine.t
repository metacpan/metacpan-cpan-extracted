use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result;

$result = test_app( 'App::Fasops' => [qw(help refine)] );
like( $result->stdout, qr{refine}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(refine)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(refine t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(refine t/example.fas --msa none -o stdout)] );
is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );

$result = test_app( 'App::Fasops' => [qw(refine t/example.fas --msa none -p 2 -o stdout)] );
is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );

$result = test_app( 'App::Fasops' => [qw(refine t/refine2.fas --msa none -o stdout)] );
is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 6, 'line count' );

$result = test_app( 'App::Fasops' => [qw(refine t/example.fas --msa none --chop 10 -o stdout)] );
is( scalar( grep {/\S/} split( /\n/, $result->stdout ) ), 24, 'line count' );
like( ( split /\n\n/, $result->stdout )[2], qr{185276-185332}, 'new header' );    # 185273-185334
like( ( split /\n\n/, $result->stdout )[2], qr{156668-156724}, 'new header' );    # 156665-156726
like( ( split /\n\n/, $result->stdout )[2], qr{3670-3727},     'new header' );    # (-):3668-3730
like( ( split /\n\n/, $result->stdout )[2], qr{2102-2159},     'new header' );    # (-):2102-2161

done_testing();
