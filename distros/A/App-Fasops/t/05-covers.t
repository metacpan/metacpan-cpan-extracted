use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Fasops;

my $result = test_app( 'App::Fasops' => [qw(help covers)] );
like( $result->stdout, qr{covers}, 'descriptions' );

$result = test_app( 'App::Fasops' => [qw(covers)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Fasops' => [qw(covers t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Fasops' => [qw(covers t/example.fas -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 11, 'line count' );
like( $result->stdout, qr{RM11.+S288c.+Spar.+YJM789}s, 'name list' );

$result = test_app( 'App::Fasops' => [qw(covers t/example.fas -n S288c -l 50 -t 10 -o stdout)] );
is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 2, 'line count' );
like( $result->stdout, qr{\-\-\-\s+I:\s+}s, 'one species' );

done_testing();
