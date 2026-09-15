use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Cwd;
use File::Temp qw[tempdir];
use Path::Tiny;
use JSON::PP;
use Alien::Xrepo::MM;
my $dir = tempdir( CLEANUP => 1 );
my $n   = 0;

sub make_mini_dist {
    my $root = path($dir)->child( 'Exotic-Foo-' . ++$n );
    $root->child( 'lib', 'Exotic' )->mkpath;
    $root->child('Makefile.PL')->spew_utf8("use Alien::Xrepo::MM;\n");
    $root->child( 'lib', 'Exotic', 'Foo.pm' )->spew_utf8(<<'PM');
use v5.40;
use feature 'class';
no warnings 'experimental::class';
use Alien::Xrepo::Runtime;
class Exotic::Foo : isa(Alien::Xrepo::Runtime) {
    method recipe { return { name => 'Exotic-Foo', packages => [] }; }
}
1;
PM
    return $root;
}
subtest 'loads and defaults' => sub {
    my $mm = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo' );
    is $mm->module_name,       'Exotic::Foo', 'module_name';
    is $mm->dist_version,      'v1.0.0',      'dist_version defaults';
    is $mm->license,           'artistic_2',  'license defaults';
    is $mm->xrepo_cache,       0,             'xrepo_cache defaults to 0';
    is $mm->xrepo_update_repo, 0,             'xrepo_update_repo defaults to 0';
    is $mm->xrepo_snapshot,    undef,         'xrepo_snapshot defaults to undef';
    is $mm->xrepo_share_dir,   undef,         'xrepo_share_dir defaults to undef';
    is $mm->requires, {},      'requires defaults to empty';
    is $mm->base_dir,          Cwd::getcwd(), 'base_dir defaults to cwd';
    like dies { Alien::Xrepo::MM->new }, qr[module_name], 'module_name is required';
};
subtest 'dist delegation' => sub {
    my $root = make_mini_dist();
    my $mm   = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo', base_dir => $root->stringify );
    is $mm->_dist->snapshot_path, path($root)->child( 'blib', 'lib', 'auto', 'share', 'dist', 'Exotic-Foo', 'xrepo-snapshot.json' )->stringify,
        'snapshot derives from the module tail';
    is $mm->_dist->script, 'Makefile.PL', 'staleness counts Makefile.PL, not Build.PL';
    like join( ' ', $mm->_dist->inputs( $mm->_engine_mods ) ), qr/Makefile\.PL/, 'Makefile.PL is an input';
    like join( ' ', $mm->_dist->inputs( $mm->_engine_mods ) ), qr/Foo\.pm/,      'module file is an input';
};
subtest 'write_makefile_args translate MB-style properties' => sub {
    my $mm = Alien::Xrepo::MM->new(
        module_name        => 'Exotic::Foo',
        dist_abstract      => 'x',
        dist_author        => 'Sanko Robinson',
        dist_version       => 'v1.0.0',
        license            => 'zlib',
        requires           => { 'Alien::Xrepo::Runtime' => 0, 'File::ShareDir' => '1.00' },
        configure_requires => { 'ExtUtils::MakeMaker'   => 0 },
        build_requires     => { 'Alien::Xrepo::MM'      => 0 },
        test_requires      => { 'Test2::V0'             => 0 }
    );
    my %wm = $mm->_write_makefile_args;
    is $wm{NAME},    'Exotic::Foo', 'NAME';
    is $wm{VERSION}, 'v1.0.0',      'VERSION';
    is $wm{LICENSE}, 'zlib',        'LICENSE';
    is $wm{PREREQ_PM}, { 'Alien::Xrepo::Runtime' => 0, 'File::ShareDir' => '1.00', 'Alien::Xrepo::MM' => 0, 'Test2::V0' => 0 },
        'PREREQ_PM unions requires, build_requires and test_requires';
    is $wm{CONFIGURE_REQUIRES}, { 'ExtUtils::MakeMaker' => 0 }, 'CONFIGURE_REQUIRES';
    is $wm{clean}{FILES}, 'xrepo-mm.json', 'make realclean drops the config';
};
subtest 'postamble hooks pure_all on the xrepo freshness target' => sub {
    my $p = MY::postamble(0);
    like $p, qr[pure_all :: xrepo], 'pure_all depends on xrepo';
    like $p, qr[^xrepo :\r?$]m,     'xrepo target exists';
    ok $p =~ /^xrepo :\r?\n\t/m, 'recipe starts with a raw tab (make rejects space-indented rules)';
    like $p, qr[Alien::Xrepo::MM::run], 'run() decides freshness in Perl';
    like $p, qr[xrepo-mm\.json],        'config is a file, not shell-quoted';
};
subtest 'Write emits the Makefile and the config' => sub {
    my $root = make_mini_dist();
    my $orig = Cwd::getcwd();
    chdir $root->stringify or die "chdir failed";
    my $mm = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo', requires => { 'Alien::Xrepo::Runtime' => 0 }, );
    $mm->Write;
    chdir $orig;
    ok -e $root->child('Makefile'),      'Makefile written';
    ok -e $root->child('xrepo-mm.json'), 'config written';
    my $cfg = JSON::PP::decode_json( $root->child('xrepo-mm.json')->slurp_utf8 );
    is $cfg->{module_name}, 'Exotic::Foo',                               'config module_name';
    is $cfg->{snapshot},    $mm->_dist->snapshot_path,                   'config snapshot is the derived path';
    is $cfg->{share_dir},   path( $cfg->{snapshot} )->parent->stringify, 'config share_dir defaults to the snapshot parent';
    is $cfg->{cache},       0,                                           'config cache';
};
subtest 'xrepo_update_repo folds into the write config' => sub {
    my $root = make_mini_dist();
    my $mm   = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo', base_dir => $root->stringify, xrepo_update_repo => 1, );
    is $mm->xrepo_update_repo, 1, 'property read back';
    $mm->Write;
    my $cfg = JSON::PP::decode_json( $root->child('xrepo-mm.json')->slurp_utf8 );
    is $cfg->{update_repo}, 1, 'update_repo recorded in xrepo-mm.json';
};
subtest 'snapshot_stale rejects a directory masquerading as the snapshot' => sub {
    my $root = make_mini_dist();
    my $mm   = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo', base_dir => $root->stringify );
    my $snap = path( $mm->_dist->snapshot_path );
    $snap->mkpath;
    my $t = time;
    utime( $t + 100, $t + 100, $snap );
    ok $mm->_dist->snapshot_stale( $snap, $mm->_engine_mods ), 'a directory can never be a fresh snapshot';
};
subtest 'run() is a no-op without a config file' => sub {
    my $root = path($dir)->child('empty');
    $root->mkpath;
    my $orig = Cwd::getcwd();
    chdir $root->stringify or die "chdir failed";
    my $out = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$out or plan skip_all => "cannot capture STDOUT: $!";
        eval { Alien::Xrepo::MM::run('xrepo-mm.json') };
        is $@, '', 'no exception';
    }
    chdir $orig;
    like $out, qr[skipping xrepo build], 'prints the skip notice';
};
subtest 'run() short-circuits on a fresh snapshot' => sub {
    my $root = make_mini_dist();
    my $mm   = Alien::Xrepo::MM->new( module_name => 'Exotic::Foo', base_dir => $root->stringify );
    my $snap = path( $mm->_dist->snapshot_path );
    $snap->parent->mkpath;
    $snap->spew_utf8('{}');
    my $t = time;
    utime( $t + 100, $t + 100, $snap );
    $root->child('xrepo-mm.json')
        ->spew_utf8(
        JSON::PP::encode_json( { module_name => 'Exotic::Foo', snapshot => $snap->stringify, share_dir => $snap->parent->stringify, cache => 0, } ) );
    my $orig = Cwd::getcwd();
    chdir $root->stringify or die "chdir failed";
    my $out = '';
    {
        local *STDOUT;
        open STDOUT, '>', \$out or plan skip_all => "cannot capture STDOUT: $!";
        eval { Alien::Xrepo::MM::run('xrepo-mm.json') };
        is $@, '', 'no exception';
    }
    chdir $orig;
    like $out, qr/up to date/, 'snapshot is current; pipeline does not run';
};
#
done_testing;
