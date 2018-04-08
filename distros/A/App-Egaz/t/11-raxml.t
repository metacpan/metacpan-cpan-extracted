use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help raxml)] );
like( $result->stdout, qr{raxml}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(raxml)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(raxml t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "raxml not installed", 5
        unless IPC::Cmd::can_run('raxmlHPC')
        or IPC::Cmd::can_run('raxmlHPC-PTHREADS');

    $result = test_app( 'App::Egaz' => [qw(raxml t/YDL184C.fas)] );
    is($result->error, undef, 'threw no exceptions');
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
    like( $result->stdout, qr{S288c}, 'target exists' );

    $result = test_app( 'App::Egaz' => [qw(raxml t/YDL184C.fas --seed 999 --tmp . --outgroup Spar)] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
    like( $result->stdout, qr{Spar:[\d.]+\);$}, 'outgroup at last' );
}

done_testing();
