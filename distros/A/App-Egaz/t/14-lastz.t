use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help lastz)] );
like( $result->stdout, qr{lastz}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(lastz)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lastz t/not_exists)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lastz t/not_exists t/pseudopig.fa)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "lastz not installed", 6 unless IPC::Cmd::can_run('lastz');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app( 'App::Egaz' => [ "lastz", "$t_path/pseudocat.fa", "$t_path/pseudopig.fa", ] );
    ok( $tempdir->child("[pseudocat]vs[pseudopig].0.lav")->is_file, 'lav file exists' );

    my $expect = join "", grep {/\s+l /} Path::Tiny::path("$t_path/default.lav")->lines;
    my $lav    = join "", grep {/\s+l /} Path::Tiny::path("[pseudocat]vs[pseudopig].0.lav")->lines;
    is( $lav, $expect, 'matched with expect' );

    $result = test_app(
        'App::Egaz' => [
            "lastz", "$t_path/pseudocat.fa", "$t_path/pseudopig.fa", "--set", "set01", "-C", "0",
            "-v"
        ]
    );
    ok( $tempdir->child("[pseudocat]vs[pseudopig].1.lav")->is_file, 'second lav file exists' );
    like( $result->stderr, qr{set01},          '--set passed' );
    like( $result->stderr, qr{C=0},            '-C passed' );
    like( $result->stderr, qr{matrix/similar}, '-Q passed' );

    chdir $cwd;    # Won't keep tempdir
}

SKIP: {
    skip "lastz not installed", 2 unless IPC::Cmd::can_run('lastz') and IPC::Cmd::can_run('egaz');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    test_app(
        'App::Egaz' => [ "lastz", "$t_path/pseudocat", "$t_path/pseudopig", "--tp", "--qp", ] );
    ok( $tempdir->child("[cat]vs[pig1].3.norm.lav")->is_file, 'normalized lav file exists' );
    ok( $tempdir->child("[cat]vs[pig2].5.norm.lav")->is_file, 'normalized lav file exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing(12);
