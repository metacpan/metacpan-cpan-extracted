use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Raw qw(import);
use Cwd ();

use_ok('Chandra::Pack');

my $tmpdir = Cwd::abs_path(tempdir(CLEANUP => 1));

# ── Create a fake script and modules for testing ─────────────────────

my $script = file_join($tmpdir, 'app.pl');
file_spew($script, <<'SCRIPT');
use strict;
use warnings;
use Chandra::App;
use Cpanel::JSON::XS;

my $app = Chandra::App->new(title => 'Test');
$app->run;
SCRIPT

# Create a fake asset directory
my $assets_dir = file_join($tmpdir, 'assets');
file_mkdir($assets_dir);
file_spew(file_join($assets_dir, 'style.css'), 'body { color: red; }');
file_spew(file_join($assets_dir, 'logo.png'), 'FAKEPNG');
my $sub_dir = file_join($assets_dir, 'images');
file_mkdir($sub_dir);
file_spew(file_join($sub_dir, 'bg.png'), 'FAKEPNG2');

# Create a fake icon
my $icon = file_join($tmpdir, 'icon.png');
file_spew($icon, 'FAKEPNG');

# ── Constructor ──────────────────────────────────────────────────────

{
    my $p = Chandra::Pack->new(script => $script);
    isa_ok($p, 'Chandra::Pack');
    is($p->script, $script, 'script accessor');
    is($p->version, '0.0.1', 'default version');
    ok($p->name, 'name derived from script');
    ok($p->identifier, 'default identifier generated');
    ok($p->platform, 'platform detected');
    is($p->perl, $^X, 'default perl is current');
}

{
    my $p = Chandra::Pack->new(
        script     => $script,
        name       => 'Test App',
        version    => '2.0.0',
        icon       => $icon,
        assets     => $assets_dir,
        output     => $tmpdir,
        identifier => 'com.test.app',
    );
    is($p->name, 'Test App', 'custom name');
    is($p->version, '2.0.0', 'custom version');
    is($p->icon, $icon, 'icon set');
    is($p->assets, $assets_dir, 'assets set');
    is($p->identifier, 'com.test.app', 'custom identifier');
}

# Missing script croaks
eval { Chandra::Pack->new() };
like($@, qr/script.*required/i, 'croak on missing script');

# Non-existent script croaks
eval { Chandra::Pack->new(script => '/no/such/file.pl') };
like($@, qr/not found/i, 'croak on non-existent script');

# ── Dependency Scanning ──────────────────────────────────────────────

{
    my $p = Chandra::Pack->new(script => $script);
    my @deps = $p->scan_deps;
    ok(scalar @deps > 0, 'found dependencies');

    my %mods = map { $_->{module} => 1 } @deps;
    ok($mods{'Chandra::App'}, 'found Chandra::App dep');

    # All deps have file paths
    for my $dep (@deps) {
        ok($dep->{file}, "dep $dep->{module} has file path");
        ok(file_is_file($dep->{file}), "dep $dep->{module} file exists");
    }

    # Scanning again returns cached results
    my @deps2 = $p->scan_deps;
    is(scalar @deps2, scalar @deps, 'cached deps same count');
}

# Exclude option
{
    my $p = Chandra::Pack->new(
        script  => $script,
        exclude => ['Cpanel::JSON::XS'],
    );
    my @deps = $p->scan_deps;
    my %mods = map { $_->{module} => 1 } @deps;
    ok(!$mods{'Cpanel::JSON::XS'}, 'excluded module not in deps');
}

# Include option
{
    my $p = Chandra::Pack->new(
        script  => $script,
        include => ['Carp'],
    );
    my @deps = $p->scan_deps;
    my %mods = map { $_->{module} => 1 } @deps;
    ok($mods{'Carp'}, 'included module found in deps');
}

# ── Info.plist Generation ────────────────────────────────────────────

{
    my $p = Chandra::Pack->new(
        script     => $script,
        name       => 'My App',
        version    => '1.2.3',
        identifier => 'com.test.myapp',
    );
    my $plist = $p->_generate_plist;
    like($plist, qr/CFBundleName/, 'plist has CFBundleName');
    like($plist, qr/My App/, 'plist has app name');
    like($plist, qr/com\.test\.myapp/, 'plist has identifier');
    like($plist, qr/1\.2\.3/, 'plist has version');
    like($plist, qr/CFBundleExecutable/, 'plist has executable key');
    like($plist, qr/NSHighResolutionCapable/, 'plist has retina flag');
    like($plist, qr/<\?xml/, 'plist has XML header');
    like($plist, qr/<\/plist>/, 'plist has closing tag');
}

# ── Launcher Generation ─────────────────────────────────────────────

{
    my $p = Chandra::Pack->new(script => $script);

    my $mac = $p->_generate_launcher_macos;
    like($mac, qr/^#!\/bin\/bash/, 'macos launcher is bash');
    like($mac, qr/PERL5LIB/, 'macos launcher sets PERL5LIB');
    like($mac, qr/exec/, 'macos launcher execs perl');
    like($mac, qr/script\.pl/, 'macos launcher runs script.pl');

    my $linux = $p->_generate_launcher_linux;
    like($linux, qr/^#!\/bin\/bash/, 'linux launcher is bash');
    like($linux, qr/PERL5LIB/, 'linux launcher sets PERL5LIB');
    like($linux, qr/usr\/share\/script\.pl/, 'linux launcher path correct');

    my $win = $p->_generate_launcher_windows;
    like($win, qr/\@echo off/i, 'windows launcher has echo off');
    like($win, qr/PERL5LIB/, 'windows launcher sets PERL5LIB');
    like($win, qr/script\.pl/, 'windows launcher runs script.pl');
}

# ── Desktop Entry Generation ────────────────────────────────────────

{
    my $p = Chandra::Pack->new(script => $script, name => 'Test App');
    my $desktop = $p->_generate_desktop;
    like($desktop, qr/\[Desktop Entry\]/, 'desktop has header');
    like($desktop, qr/Type=Application/, 'desktop is Application type');
    like($desktop, qr/Name=Test App/, 'desktop has name');
    like($desktop, qr/Exec=\.\/AppRun/, 'desktop exec is AppRun');
}

# ── macOS Build ──────────────────────────────────────────────────────

{
    my $out = file_join($tmpdir, 'build_mac');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'TestApp',
        version  => '1.0.0',
        icon     => $icon,
        assets   => $assets_dir,
        output   => $out,
        platform => 'macos',
    );

    my $result = $p->build;
    ok($result->{success}, 'macos build succeeded');
    is($result->{platform}, 'macos', 'result platform is macos');
    ok($result->{size} > 0, 'result has size');

    my $app = file_join($out, 'TestApp.app');
    ok(file_is_dir($app), '.app dir created');
    ok(file_is_dir(file_join($app, 'Contents')), 'Contents dir');
    ok(file_is_dir(file_join($app, 'Contents', 'MacOS')), 'MacOS dir');
    ok(file_is_dir(file_join($app, 'Contents', 'Resources')), 'Resources dir');
    ok(file_is_file(file_join($app, 'Contents', 'Info.plist')), 'Info.plist exists');
    ok(file_is_file(file_join($app, 'Contents', 'Resources', 'script.pl')), 'script copied');

    # Launcher is executable
    my $launcher = file_join($app, 'Contents', 'MacOS', 'testapp');
    ok(file_is_file($launcher), 'launcher exists');
    ok(-x $launcher, 'launcher is executable');

    # Assets copied
    ok(file_is_dir(file_join($app, 'Contents', 'Resources', 'assets')), 'assets dir');
    ok(file_is_file(file_join($app, 'Contents', 'Resources', 'assets', 'style.css')), 'asset file copied');
    ok(file_is_file(file_join($app, 'Contents', 'Resources', 'assets', 'images', 'bg.png')), 'nested asset copied');

    # Deps copied
    ok(file_is_dir(file_join($app, 'Contents', 'Resources', 'lib')), 'lib dir');

    # Plist content
    my $plist = file_slurp(file_join($app, 'Contents', 'Info.plist'));
    like($plist, qr/TestApp/, 'plist has app name');

    # Callback works
    my $cb_called = 0;
    $p->build(sub { $cb_called = 1 });
    ok($cb_called, 'build callback called');
}

# ── Linux Build ──────────────────────────────────────────────────────

{
    my $out = file_join($tmpdir, 'build_linux');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'TestApp',
        assets   => $assets_dir,
        output   => $out,
        platform => 'linux',
    );

    my $result = $p->build;
    ok($result->{success}, 'linux build succeeded');
    is($result->{platform}, 'linux', 'result platform is linux');

    my $app = file_join($out, 'TestApp');
    ok(file_is_dir($app), 'app dir created');

    my $apprun = file_join($app, 'AppRun');
    ok(file_is_file($apprun), 'AppRun exists');
    ok(-x $apprun, 'AppRun is executable');

    ok(file_is_file(file_join($app, 'testapp.desktop')), 'desktop file');
    ok(file_is_file(file_join($app, 'usr', 'share', 'script.pl')), 'script copied');
    ok(file_is_dir(file_join($app, 'usr', 'lib', 'perl5')), 'lib dir');
    ok(file_is_dir(file_join($app, 'usr', 'share', 'assets')), 'assets dir');
}

# ── Windows Build ────────────────────────────────────────────────────

{
    my $out = file_join($tmpdir, 'build_win');
    file_mkdir($out);
    my $p = Chandra::Pack->new(
        script   => $script,
        name     => 'TestApp',
        assets   => $assets_dir,
        output   => $out,
        platform => 'windows',
    );

    my $result = $p->build;
    ok($result->{success}, 'windows build succeeded');
    is($result->{platform}, 'windows', 'result platform is windows');

    my $app = file_join($out, 'TestApp');
    ok(file_is_dir($app), 'app dir created');
    ok(file_is_file(file_join($app, 'testapp.bat')), 'bat launcher');
    ok(file_is_file(file_join($app, 'script.pl')), 'script copied');
    ok(file_is_dir(file_join($app, 'lib')), 'lib dir');
    ok(file_is_dir(file_join($app, 'assets')), 'assets dir');
}

# ── Platform Detection ───────────────────────────────────────────────

{
    my $p = Chandra::Pack->new(script => $script);
    my $plat = $p->platform;
    if ($^O eq 'darwin') {
        is($plat, 'macos', 'detects macos');
    } elsif ($^O eq 'MSWin32') {
        is($plat, 'windows', 'detects windows');
    } else {
        is($plat, 'linux', 'detects linux/other');
    }
}

done_testing;
