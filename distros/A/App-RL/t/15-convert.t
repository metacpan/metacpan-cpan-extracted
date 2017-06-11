use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::RL;

my $result = test_app( 'App::RL' => [qw(help convert)] );
like( $result->stdout, qr{convert}, 'descriptions' );

$result = test_app( 'App::RL' => [qw(convert)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::RL' => [qw(convert t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::RL' => [qw(convert t/repeat.yml -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 28, 'line count' );
like( $result->stdout, qr{II:327069-327703}, 'first chromosome' );

done_testing();
