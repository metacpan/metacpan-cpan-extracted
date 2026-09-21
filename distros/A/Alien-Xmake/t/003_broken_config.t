use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use File::Temp    qw[tempdir];
use Capture::Tiny qw[capture];
use Cwd           qw[getcwd];
use Alien::Xmake;
#
my $xmake = Alien::Xmake->new;
my $exe   = $xmake->exe;
qx["$exe" g --theme=plain];
my $cwd = getcwd();
#
# A project that can never resolve a toolchain forces xmake into a nonzero exit
# no matter which compilers happen to be installed, which is exactly the state
# the failing CPAN smoke report (c5447a81) hit on a bare Strawberry Perl box.
sub make_broken {
    my $d = tempdir( CLEANUP => 0 );
    chdir $d                                            or die "chdir $d: $!";
    $xmake->create( 't_broken', template => 'console' ) or die 'create failed';
    chdir 't_broken'                                    or die 'chdir t_broken: $!';
    open my $fh, '>', 'xmake.lua' or die "xmake.lua: $!";
    print {$fh} "set_project( 't_broken' )\nset_toolchains( 'nonexistent_monkey' )\n" .
        "target( 't_broken' )\n    set_kind( 'binary' )\n    add_files( 'src/main.cpp' )\n";
    close $fh;
    return $d;
}
#
sub phantom_count ($text) {
    return scalar grep {/^Can't spawn /} split /\n/, $text;
}
#
subtest 'never-resolvable config fails cleanly without phantom warnings' => sub {
    make_broken();
    my $ret;
    my ( $out, $err ) = capture { $ret = $xmake->configure( mode => 'debug' ) };
    ok !$ret, 'configure returns false (no toolchain can ever resolve)';
    is phantom_count($err), 0, "no phantom Can't spawn lines in the streamed path";
    my $compiler = Alien::Xmake::_c_compiler_on_path();
    if ( defined $compiler ) {
        unlike $err, qr[retrying with --toolchain], 'retry hint stays quiet unless verbose';
        my $loud = Alien::Xmake->new( verbose => 1 );
        my ( $l_out, $l_err ) = capture { $loud->configure( mode => 'debug' ) };
        like $l_err, qr[retrying with --toolchain], "verbose: retried once with --toolchain=($compiler)";
        is phantom_count($l_err), 0, 'the verbose path also stays phantom-free';
    }
    else {
        ok 1, 'no compiler on PATH; the retry step is skipped by design';
    }
    note 'stderr excerpt: ' . substr( $err, 0, 120 ) if length $err;
};
#
subtest 'nonzero xmake exits under the spawn wrapper stay ghost-free' => sub {
    make_broken();
    my $ret;
    my ( $out, $err ) = capture { $ret = $xmake->build };
    ok !$ret, 'build on the broken project fails';
    is phantom_count($err), 0, "no phantom Can't spawn lines in the captured path";
};
#
subtest '_spawn passes through child behavior unchanged' => sub {
    my ( $stdout, $stderr, $exit ) = capture { Alien::Xmake::_spawn( $exe, '--version' ) };
    is phantom_count($stderr), 0, 'successful child: no phantom';
    my ( $o2, $e2 ) = capture { Alien::Xmake::_spawn( $exe, 'config', '--toolchain=also-not-real' ) };
    is phantom_count($e2), 0, 'failing child: no phantom, real error survives';
    like $o2, qr[error: the toolchain also-not-real not found!], 'xmake own error text still reaches the terminal';
};
#
chdir $cwd or die "chdir $cwd: $!";
#
done_testing;
