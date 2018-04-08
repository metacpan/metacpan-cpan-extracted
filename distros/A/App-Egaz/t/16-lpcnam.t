use strict;
use warnings;
use Test::More;
use App::Cmd::Tester;

use App::Egaz;

my $result = test_app( 'App::Egaz' => [qw(help lpcnam)] );
like( $result->stdout, qr{lpcnam}, 'descriptions' );

$result = test_app( 'App::Egaz' => [qw(lpcnam)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lpcnam t/not_exists)] );
like( $result->error, qr{need .+input file}, 'need infile' );

$result = test_app( 'App::Egaz' => [qw(lpcnam t/pseudocat t/pseudopig t/not_exists)] );
like( $result->error, qr{doesn't exist}, 'infile not exists' );

SKIP: {
    skip "kent-tools not installed", 12
        unless IPC::Cmd::can_run('axtChain')
        and IPC::Cmd::can_run('chainAntiRepeat')
        and IPC::Cmd::can_run('chainMergeSort')
        and IPC::Cmd::can_run('chainPreNet')
        and IPC::Cmd::can_run('chainNet')
        and IPC::Cmd::can_run('netSyntenic')
        and IPC::Cmd::can_run('netChainSubset')
        and IPC::Cmd::can_run('chainStitchId')
        and IPC::Cmd::can_run('netSplit')
        and IPC::Cmd::can_run('netToAxt')
        and IPC::Cmd::can_run('axtSort')
        and IPC::Cmd::can_run('axtToMaf')
        and IPC::Cmd::can_run('netFilter')
        and IPC::Cmd::can_run('chainSplit');

    my $t_path = Path::Tiny::path("t/")->absolute->stringify;
    my $cwd    = Path::Tiny->cwd;

    my $tempdir = Path::Tiny->tempdir;
    chdir $tempdir;

    $result
        = test_app( 'App::Egaz' =>
            [ "lpcnam", "$t_path/pseudocat", "$t_path/pseudopig", "$t_path/default.lav", "-v", ] );
    is( $result->stdout, '', 'no stdout' );
    is( ( scalar grep {/^CMD/} grep {/\S/} split( /\n/, $result->stderr ) ),
        13, '13 commands executed' );
    ok( $tempdir->child("noClass.net")->is_file,           'noClass.net exists' );
    ok( $tempdir->child("all.chain.gz")->is_file,          'all.chain.gz exists' );
    ok( $tempdir->child("all.pre.chain.gz")->is_file,      'all.pre.chain.gz exists' );
    ok( $tempdir->child("over.chain.gz")->is_file,         'over.chain.gz exists' );
    ok( $tempdir->child("lav.tar.gz")->is_file,            'lav.tar.gz exists' );
    ok( $tempdir->child("psl.tar.gz")->is_file,            'psl.tar.gz exists' );
    ok( $tempdir->child("net.tar.gz")->is_file,            'net.tar.gz exists' );
    ok( $tempdir->child("chain.tar.gz")->is_file,          'chain.tar.gz exists' );
    ok( $tempdir->child("axtNet/cat.net.axt.gz")->is_file, 'cat.net.axt.gz exists' );
    ok( $tempdir->child("mafNet/cat.net.maf.gz")->is_file, 'cat.net.maf.gz exists' );

    chdir $cwd;    # Won't keep tempdir
}

done_testing();
