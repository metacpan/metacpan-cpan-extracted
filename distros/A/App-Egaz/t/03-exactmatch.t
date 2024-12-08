use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help exactmatch)] );
like( $result->stdout, qr{exactmatch}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(exactmatch)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(exactmatch t/not_exists t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(exactmatch t/not_exists t/pseudopig.fa)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "mummer or sparsemem not installed", 3
        unless IPC::Cmd::can_run('mummer')
        or IPC::Cmd::can_run('sparsemem');

    $result = test_app( 'App::Egaz' => [qw(exactmatch t/pig2.fa t/pseudopig.fa)] );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 1, 'line count' );
    like( $result->stdout, qr{pig2\(\+\):1\-22929}, 'exact position' );

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app(
        'App::Egaz' => [ "exactmatch", "$t_path/pig2.fa", "$t_path/pseudopig.fa", "--debug" ] );
    ok( $tempdir->child("exactmatch.json")->is_file, 'exactmatch.json exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
