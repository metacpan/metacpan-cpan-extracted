use v5.40;
use blib;
use Test2::V0 '!subtest', -no_srand => 1;
use Test2::Util::Importer 'Test2::Tools::Subtest' => ( subtest_streamed => { -as => 'subtest' } );
use Test2::Require::AuthorTesting;
use Capture::Tiny qw[capture];
use File::Temp    qw[tempdir];
use Path::Tiny    qw[path];
use Alien::Xrepo;
use experimental 'class';
#
# xrepo keeps added repositories in xmake's global registry. Point XMAKE_GLOBALDIR at a throwaway directory so
# every add/remove below touches only this test's registry, never the user's real repository list.
my $global = path( tempdir( CLEANUP => 1 ) );
local $ENV{XMAKE_GLOBALDIR} = $global->stringify;
my $repo = Alien::Xrepo->new( verbose => 0 );
#
# Local directory runs are offline-safe; the web subtest clones a public repository and only runs as an author test.
sub _have_git {
    my ( undef, undef, $exit ) = capture { system 'git', '--version' };
    return $exit == 0;
}

sub _git (@args) {
    my ( $out, $err, $exit ) = capture { system 'git', @args };
    die "git @args failed (exit $exit): $err" if $exit != 0;
    return $out;
}

# xmake prints local paths with forward slashes even on Windows, so normalize both sides before comparing.
sub _norm ( $path //= '' ) { $path =~ s{\\}{/}gr }

# Return the `    <name> <url> [branch]` line for a repository, if list_repo reported it.
sub _repo_line ( $name, @lines ) {
    return ( grep {/^\s+\Q$name\E(?:\s|$)/} @lines )[0];
}

# Build a minimal xrepo tree (<root>/repo/packages/<letter>/<name>/xmake.lua) that xmake can list and search.
sub _make_repo ( $root, $pkg_name ) {
    my $dir = path($root)->child('repo');
    my $pkg = $dir->child( 'packages', substr( $pkg_name, 0, 1 ), $pkg_name );
    $pkg->mkpath;
    $pkg->child('xmake.lua')->spew(<<~"LUA");
        package("$pkg_name")
            set_homepage("https://example.com/$pkg_name")
            set_description("Alien::Xrepo repository test fixture")
            on_install(function (package) end)
        LUA
    return $dir;
}
#
subtest 'local directory repository' => sub {
    my $source = _make_repo( tempdir( CLEANUP => 1 ), 'alien_repo_dir_test' );
    my $name   = 'alien-dir-test';
    ok $repo->add_repo( $name, $source->stringify ), 'add_repo accepts a local directory';
    my @lines = $repo->list_repo;
    ok my $line = _repo_line( $name, @lines ), 'list_repo shows the added repository';
    like _norm($line), qr{\Q@{[ _norm( $source->stringify ) ]}\E}, 'list_repo reports the directory URL';
    ok scalar( grep { $_ eq 'alien_repo_dir_test' } $repo->search('alien_repo_dir_test') ),
        'search finds a package registered by the local directory repository';
    $repo->update_repo($name);
    ok _repo_line( $name, $repo->list_repo ), 'update_repo leaves a local directory repository registered';
    $repo->rm_repo($name);
    is _repo_line( $name, $repo->list_repo ), F(), 'rm_repo removes the local directory repository';
    ok $source->is_dir, 'rm_repo does not delete the source directory';
    is grep( { $_ eq 'alien_repo_dir_test' } $repo->search('alien_repo_dir_test') ), E(),
        'search no longer finds packages from the removed repository';
};
#
subtest 'local file repository (git bundle)' => sub {
    skip_all 'git is required to build a local bundle fixture' unless _have_git();
    my $root   = path( tempdir( CLEANUP => 1 ) );
    my $source = _make_repo( $root, 'alien_repo_bundle_test' );
    _git '-C', $source->stringify, 'init', '-q';
    _git '-C', $source->stringify, 'add',  '.';
    _git '-C', $source->stringify, '-c',   'user.name=Alien Xrepo', '-c', 'user.email=alien@example.com', 'commit', '-qm', 'repository fixture';
    my $branch = _git( '-C', $source->stringify, 'symbolic-ref', '--short', 'HEAD' );
    $branch =~ s/\s+\z//;
    my $bundle = $root->child('repo.bundle');
    _git '-C', $source->stringify, 'bundle', 'create', $bundle->stringify, '--all';
    ok -f $bundle, 'created a local git bundle to use as a repository file';
    my $name = 'alien-bundle-test';
    ok $repo->add_repo( $name, $bundle->stringify, $branch ), 'add_repo accepts a local file repository';
    my @lines = $repo->list_repo;
    ok my $line = _repo_line( $name, @lines ), 'list_repo shows the local file repository';
    like _norm($line), qr{\Q@{[ _norm( $bundle->stringify ) ]}\E}, 'list_repo reports the file URL';
    like $line,        qr/\Q$branch\E\s*$/,                        'list_repo reports the branch';
    ok scalar( grep { $_ eq 'alien_repo_bundle_test' } $repo->search('alien_repo_bundle_test') ), 'search finds a package cloned from the local file';
    $repo->update_repo($name);
    ok _repo_line( $name, $repo->list_repo ), 'update_repo refreshes a local file repository';
    $repo->rm_repo($name);
    is _repo_line( $name, $repo->list_repo ), F(), 'rm_repo removes the local file repository';
    ok -f $bundle, 'rm_repo does not delete the bundle file';
};
#
subtest 'web repository' => sub {
    skip_all 'git is required to clone a web repository' unless _have_git();
    my $url    = 'https://github.com/GamedevFramework/xmake-repo.git';
    my $branch = 'main';

    # Skip rather than fail when offline: if ls-remote cannot see the branch there is nothing for xmake to clone.
    my ( undef, $err, $exit ) = capture { system 'git', 'ls-remote', '--exit-code', '--heads', $url, $branch };
    skip_all "web repository fixture is unreachable: $err" if $exit != 0;
    my $name = 'alien-web-test';
    ok $repo->add_repo( $name, $url, $branch ), 'add_repo clones a web based repository';
    my @lines = $repo->list_repo;
    ok my $line = _repo_line( $name, @lines ), 'list_repo shows the web repository';
    like $line, qr/\Q$url\E\s+\Q$branch\E\s*$/, 'list_repo reports the web URL and branch';
    ok scalar( grep {/^gamedevframework/} $repo->search('gamedevframework') ), 'search finds packages from the web repository';
    $repo->update_repo($name);
    ok _repo_line( $name, $repo->list_repo ), 'update_repo refreshes the web repository';
    $repo->rm_repo($name);
    is _repo_line( $name, $repo->list_repo ), F(), 'rm_repo removes the web repository';
};
#
done_testing;
