use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help vars)] );
like( $result->stdout, qr{vars}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(vars)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(vars t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

# # population
# $result
#     = test_app( 'App::Fasops' => [qw(vars t/example.fas -o stdout)] );
# is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 5, 'line count' );
# unlike( $result->stdout, qr{,count\n}, 'field count absents' );

# population
$result = test_app( 'App::Fasops' => [qw(vars t/example.fas -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 80, 'line count' );

$result = test_app( 'App::Fasops' => [qw(vars t/example.fas --nocomplex -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 73, 'line count' );

$result = test_app( 'App::Fasops' => [qw(vars t/example.fas --nosingle -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 17, 'line count' );

# outgroup
$result = test_app( 'App::Fasops' => [qw(vars t/example.fas --outgroup -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 48, 'line count' );

$result = test_app( 'App::Fasops' => [qw(vars t/example.fas --outgroup --nocomplex -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 40, 'line count' );

$result = test_app( 'App::Fasops' => [qw(vars t/example.fas --outgroup --nosingle -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 17, 'line count' );

# annotation
$result = test_app(
    'App::Fasops' => [
        qw(vars t/NC_007942.maf.gz.fas.gz --anno t/anno.yml -l 30000 --nosingle --nocomplex -o stdout)
    ]
);
is( ( scalar grep {/1$/} grep {/\S/} split( /\n/, $result->stdout ) ), 18, 'line count' );

done_testing();
