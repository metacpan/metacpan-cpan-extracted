use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Raw qw(import);
use Cwd ();

use_ok('Chandra::Pack');

my $tmpdir = Cwd::abs_path(tempdir(CLEANUP => 1));
my $is_darwin = $^O eq 'darwin';

# Helper: create a minimal script
sub make_script {
    my ($dir, $name, $content) = @_;
    $content ||= "use strict;\nuse warnings;\nprint 1;\n";
    my $path = file_join($dir, $name);
    file_spew($path, $content);
    return $path;
}

# ── Missing script ───────────────────────────────────────────────────

eval { Chandra::Pack->new(script => file_join($tmpdir, 'nope.pl')) };
like($@, qr/not found/, 'croaks for missing script');

# ── Script is a directory ────────────────────────────────────────────

{
    my $dir = file_join($tmpdir, 'fakescript');
    file_mkdir($dir);
    eval { Chandra::Pack->new(script => $dir) };
    like($@, qr/not a file/i, 'croaks when script is a directory');
}

# ── Invalid platform ────────────────────────────────────────────────

{
    my $script = make_script($tmpdir, 'plat.pl');
    my $p = Chandra::Pack->new(script => $script, platform => 'amiga');
    eval { $p->build };
    like($@, qr/Unsupported platform.*amiga/i, 'croaks on invalid platform');
}

# ── No dependencies (minimal script) ────────────────────────────────

{
    my $script = make_script($tmpdir, 'minimal.pl', "print 'hello';\n");
    my $p = Chandra::Pack->new(script => $script);
    my @deps = $p->scan_deps;
    is(scalar @deps, 0, 'no deps for trivial script');
}

# ── Script with no use/require ───────────────────────────────────────

{
    my $script = make_script($tmpdir, 'nomod.pl', <<'CODE');
my $x = 42;
print $x * 2;
CODE
    my $p = Chandra::Pack->new(script => $script);
    my @deps = $p->scan_deps;
    is(scalar @deps, 0, 'no deps when no use/require');
}

# ── Pragmas excluded from deps ──────────────────────────────────────

{
    my $script = make_script($tmpdir, 'pragmas.pl', <<'CODE');
use strict;
use warnings;
use utf8;
use constant FOO => 1;
use feature 'say';
CODE
    my $p = Chandra::Pack->new(script => $script);
    my @deps = $p->scan_deps;
    is(scalar @deps, 0, 'pragmas not counted as deps');
}

# ── Special characters in app name ───────────────────────────────────

SKIP: {
    skip 'macOS pack build tests only on darwin', 2 unless $is_darwin;

    my $script = make_script($tmpdir, 'special.pl');
    my $out = file_join($tmpdir, 'special_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'My App! (v2.0) [beta]',
        output   => $out,
        platform => 'macos',
    );
    my $result = $p->build;
    ok($result->{success}, 'build with special chars succeeds');
    # Safe name strips special chars
    ok(file_is_dir(file_join($out, 'MyAppv20beta.app')), 'special chars stripped from dir name');
}

# ── Empty app name fallback ──────────────────────────────────────────

SKIP: {
    skip 'macOS pack build tests only on darwin', 2 unless $is_darwin;

    my $script = make_script($tmpdir, 'empty_name.pl');
    my $out = file_join($tmpdir, 'empty_name_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => '!!!',
        output   => $out,
        platform => 'macos',
    );
    my $result = $p->build;
    ok($result->{success}, 'build with all-special-char name succeeds');
    ok(file_is_dir(file_join($out, 'App.app')), 'falls back to App');
}

# ── No icon ──────────────────────────────────────────────────────────

SKIP: {
    skip 'macOS pack build tests only on darwin', 2 unless $is_darwin;

    my $script = make_script($tmpdir, 'noicon.pl');
    my $out = file_join($tmpdir, 'noicon_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'NoIcon',
        output   => $out,
        platform => 'macos',
    );
    my $result = $p->build;
    ok($result->{success}, 'build without icon succeeds');
    my $plist = file_slurp(file_join($out, 'NoIcon.app', 'Contents', 'Info.plist'));
    unlike($plist, qr/CFBundleIconFile/, 'plist has no icon key when no icon');
}

# ── Missing icon file ignored ────────────────────────────────────────

SKIP: {
    skip 'macOS pack build tests only on darwin', 1 unless $is_darwin;

    my $script = make_script($tmpdir, 'bad_icon.pl');
    my $out = file_join($tmpdir, 'bad_icon_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'BadIcon',
        icon     => file_join($tmpdir, 'nonexistent.png'),
        output   => $out,
        platform => 'macos',
    );
    my $result = $p->build;
    ok($result->{success}, 'build with missing icon file still succeeds');
}

# ── No assets ────────────────────────────────────────────────────────

{
    my $script = make_script($tmpdir, 'noassets.pl');
    my $out = file_join($tmpdir, 'noassets_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'NoAssets',
        output   => $out,
        platform => 'linux',
    );
    my $result = $p->build;
    ok($result->{success}, 'build without assets succeeds');
    ok(!file_is_dir(file_join($out, 'NoAssets', 'usr', 'share', 'assets')),
       'no assets dir when none specified');
}

# ── Deep module paths ────────────────────────────────────────────────

{
    my $script = make_script($tmpdir, 'deep.pl', "use File::Spec::Functions;\n");
    my $p = Chandra::Pack->new(script => $script);
    my @deps = $p->scan_deps;
    my %mods = map { $_->{module} => 1 } @deps;
    ok($mods{'File::Spec::Functions'}, 'deep module path found');
}

# ── Build for all three platforms ────────────────────────────────────

{
    my $script = make_script($tmpdir, 'multi.pl');
    for my $plat (qw(macos linux windows)) {
        my $out = file_join($tmpdir, "multi_$plat");
        file_mkdir($out);
        SKIP: {
            skip 'macOS pack build tests only on darwin', 3 if $plat eq 'macos' && !$is_darwin;

            my $p = Chandra::Pack->new(
                script   => $script,
                name     => 'Multi',
                output   => $out,
                platform => $plat,
            );
            my $result = $p->build;
            ok($result->{success}, "build for $plat succeeds");
            is($result->{platform}, $plat, "result platform is $plat");
            ok($result->{path}, "result has path for $plat");
        }
    }
}

# ── Exclude all deps ────────────────────────────────────────────────

{
    my $script = make_script($tmpdir, 'excl.pl', "use Carp;\n");
    my $p = Chandra::Pack->new(
        script  => $script,
        exclude => ['Carp'],
    );
    my @deps = $p->scan_deps;
    is(scalar @deps, 0, 'all deps excluded');
}

# ── Launcher content correctness ─────────────────────────────────────

SKIP: {
    skip 'macOS pack build tests only on darwin', 2 unless $is_darwin;

    my $script = make_script($tmpdir, 'launch.pl');
    my $out = file_join($tmpdir, 'launch_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'LaunchTest',
        output   => $out,
        platform => 'macos',
    );
    $p->build;
    my $launcher = file_slurp(file_join($out, 'LaunchTest.app', 'Contents', 'MacOS', 'launchtest'));
    like($launcher, qr/Resources/, 'launcher references Resources');
    like($launcher, qr/PERL5LIB/, 'launcher sets PERL5LIB');
}

# ── Size reporting ───────────────────────────────────────────────────

{
    my $script = make_script($tmpdir, 'sized.pl');
    my $out = file_join($tmpdir, 'sized_out');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'Sized',
        output   => $out,
        platform => 'windows',
    );
    my $result = $p->build;
    ok($result->{size} > 0, 'size is positive');
}

done_testing;
