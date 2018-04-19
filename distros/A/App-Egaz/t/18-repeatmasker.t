use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help repeatmasker)] );
like( $result->stdout, qr{repeatmasker}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(repeatmasker)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(repeatmasker t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

$result = test_app( 'App::Egaz' => [qw(repeatmasker t/not_exists t/pseudopig.fa)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "RepeatMasker or faops not installed", 6
        unless IPC::Cmd::can_run('RepeatMasker')
        and IPC::Cmd::can_run('faops');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result = test_app( 'App::Egaz' => [ "repeatmasker", "$t_path/pseudocat.fa", "--verbose", ] );

    is( $result->error, undef, 'threw no exceptions' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stderr ) ), 1, 'stderr line count' );
    is( ( scalar grep {/\S/} split( /\n/, $result->stdout ) ), 0, 'no stdout' );
    ok( $tempdir->child("pseudocat.fa")->is_file,     'pseudocat.fa exists' );
    ok( $tempdir->child("pseudocat.fa.out")->is_file, 'pseudocat.fa.out exists' );
    is( `faops size $t_path/pseudocat.fa`, `faops size pseudocat.fa`, 'same length' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
