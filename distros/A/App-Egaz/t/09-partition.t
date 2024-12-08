use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help partition)] );
like( $result->stdout, qr{partition}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(partition)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(partition t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(partition t/pseudocat.fa t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(partition t/pseudopig.fa)] );
like( $result->error, qr{More than one sequence in}, 'error' );

{    # real run
    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    Path::Tiny::path($t_path, "pseudocat.fa")->copy(".");

    $result = test_app( 'App::Egaz' => [qw(partition pseudocat.fa) ] );
    is($result->stdout, '', 'nothing sent to stdout');
    is($result->stderr, '', 'nothing sent to sderr');
    ok($tempdir->child('pseudocat.fa[1,18803]')->is_file, 'partitioned file exists');

    $tempdir->child('pseudocat.fa[1,18803]')->remove;

    $result = test_app( 'App::Egaz' => [qw(partition --chunk 5000 --overlap 100 pseudocat.fa) ] );
    ok($tempdir->child('pseudocat.fa[1,5100]')->is_file, 'partitioned file exists');
    ok($tempdir->child('pseudocat.fa[5001,10100]')->is_file, 'partitioned file exists');

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
