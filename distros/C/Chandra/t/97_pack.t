#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Chandra::Pack;

my $dir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $dir;
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

sub write_file { my ($path, $content) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh $content; close $fh; return $path }

my $script = write_file("$dir/my_app-demo.pl", "use strict;\nuse Cpanel::JSON::XS;\nrequire Missing::Module::Nowhere;\nuse lib 'x';\nprint 1;\n");

# --- configuration ---
{
    is(Chandra::Pack->config('identity'), '-', 'the identity is ad hoc until configured');
    is(Chandra::Pack->config({ identity => 'Dev' }), 'Chandra::Pack', 'config with a hash returns the class');
    is(Chandra::Pack->config('identity'), 'Dev', 'and sets the key');
    my %all = Chandra::Pack->config;
    ok(exists $all{apple_id}, 'config with no arguments returns everything');
    {
        local $ENV{CHANDRA_IDENTITY} = 'EnvId';
        local $ENV{CHANDRA_APPLE_ID} = 'env@example.com';
        local $ENV{CHANDRA_TEAM_ID} = 'TEAM';
        local $ENV{CHANDRA_NOTARY_KEYCHAIN} = 'chain';
        local $ENV{CHANDRA_SIGN_CERT} = 'cert';
        local $ENV{CHANDRA_SIGN_PASSWORD} = 'pw';
        Chandra::Pack->config(save => 1, bogus => 1);
    }
    is(Chandra::Pack->config('identity'), 'EnvId', 'the environment fills the keys not given');
    like($warned[-1], qr/Unknown config key: bogus/, 'an unknown key warns');
    ok(-f "$dir/.chandra/pack.conf", 'save writes the config file');
    like(do { local (@ARGV, $/) = ("$dir/.chandra/pack.conf"); <> }, qr/^identity = EnvId$/m, 'with the keys');
    write_file("$dir/.chandra/pack.conf", "# comment\n\nidentity = FromFile\nunknown = x\nnot a setting\n");
    Chandra::Pack::_load_config();
    is(Chandra::Pack->config('identity'), 'FromFile', 'loading the file reads the keys it knows and skips the rest');
    Chandra::Pack->config(identity => undef, apple_id => undef, team_id => undef, notary_keychain => undef, sign_cert => undef, sign_password => undef);
    {
        local $ENV{HOME} = '';
        like(Chandra::Pack::_config_file(), qr{/\.chandra/pack\.conf$}, 'with no HOME the password file gives the home');
    }
}

# --- construction ---
{
    my $p = Chandra::Pack->new(script => $script, distribute => 1, output => $dir);
    is($p->name, 'My app demo', 'the name comes from the script');
    is($p->output, $dir, 'the output directory');
    is($p->distribute, 1, 'distribute is kept');
    is($p->platform, $^O eq 'darwin' ? 'macos' : $^O eq 'MSWin32' ? 'windows' : 'linux', 'the platform is detected');
    my @deps = $p->scan_deps;
    ok(scalar(grep { $_->{module} eq 'Cpanel::JSON::XS' } @deps), 'an XS module is found among the dependencies');
    ok(!scalar(grep { $_->{module} =~ /Missing/ } @deps), 'a module that is not installed is left out');
    is_deeply([ $p->scan_deps ], \@deps, 'scanning again returns the same list');

    mkdir "$dir/lib" or die;
    write_file("$dir/lib/Unreadable.pm", "package Unreadable; 1;\n");
    chmod 0, "$dir/lib/Unreadable.pm";
    {
        local @INC = (sub { }, "$dir/lib", @INC);
        my $inc = Chandra::Pack->new(script => $script, include => ['Unreadable', 'Nope::Nowhere'], exclude => ['Cpanel::JSON::XS']);
        my @got = $inc->scan_deps;
        ok(scalar(grep { $_->{module} eq 'Unreadable' } @got), 'an included module is listed even when unreadable');
        ok(!scalar(grep { $_->{module} eq 'Cpanel::JSON::XS' } @got), 'an excluded module is left out');
    }
    chmod 0644, "$dir/lib/Unreadable.pm";
    eval { Chandra::Pack->new(script => $script, platform => 'amiga')->build };
    like($@, qr/Unsupported platform: amiga/, 'an unknown platform croaks');
    is(Chandra::Pack::_dir_size("$dir/nothing"), 0, 'the size of a missing directory is 0');
}

# --- a Linux build with every extra, then distribution ---
{
    my $out = "$dir/linux";
    mkdir $out or die;
    mkdir "$dir/assets" or die;
    mkdir "$dir/assets/sub" or die;
    write_file("$dir/assets/a.txt", 'a');
    write_file("$dir/assets/sub/b.txt", 'b');
    require MIME::Base64;
    my $icon = write_file("$dir/icon.png", MIME::Base64::decode_base64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
    my $p = Chandra::Pack->new(script => $script, name => 'Lin App', output => $out, platform => 'linux', icon => $icon, assets => "$dir/assets", distribute => 1);
    my $seen;
    @warned = ();
    my $result = $p->build(sub { $seen = $_[0] });
    is($result, $seen, 'the build callback gets the result');
    ok($result->{success}, 'the Linux build succeeds');
    ok(-f "$out/LinApp/linapp.png", 'the icon is copied');
    ok(-f "$out/LinApp/usr/share/assets/sub/b.txt", 'assets are copied with their subdirectories');
    ok(-f "$out/LinApp/usr/lib/perl5/Cpanel/JSON/XS.pm", 'the dependency is copied');
    ok(scalar(grep { /appimagetool not found/ } @warned), 'without appimagetool the AppImage is skipped');

    my $bin = "$dir/bin";
    mkdir $bin or die;
    write_file("$bin/appimagetool", "#!/bin/sh\nexit 1\n");
    chmod 0755, "$bin/appimagetool";
    {
        local $ENV{PATH} = "$bin:$ENV{PATH}";
        my $failed = $p->_distribute_linux({ path => "$out/LinApp", success => 1 });
        like($failed->{error}, qr/appimagetool failed/, 'an appimagetool that fails is reported');
        write_file("$bin/appimagetool", "#!/bin/sh\ntouch \"\$2\"\n");
        my $made = $p->_distribute_linux({ path => "$out/LinApp", success => 1 });
        ok($made->{success} && -f $made->{appimage_path}, 'an appimagetool that works gives the AppImage');
        unlink "$out/LinApp/linapp.desktop";
        like($p->_create_appimage("$out/LinApp", "$bin/appimagetool")->{error}, qr/Missing \.desktop file/, 'no desktop file, no AppImage');
    }
    is(Chandra::Pack::_find_command('surely-not-a-command-here'), undef, 'an unknown command is not found');
    {
        local $ENV{PATH} = '/nonexistent';
        local $ENV{HOME} = $dir;
        write_file("$dir/bin/foundhere", "#!/bin/sh\n");
        chmod 0755, "$dir/bin/foundhere";
        is(Chandra::Pack::_find_command('foundhere'), "$dir/bin/foundhere", 'a command is found in the home bin without which');
    }
}

# --- a Windows build with signing asked for ---
{
    my $out = "$dir/windows";
    mkdir $out or die;
    my $p = Chandra::Pack->new(script => $script, name => 'Win', output => $out, platform => 'windows', assets => "$dir/assets");
    $p->{sign_cert} = "$dir/cert.pfx";
    $p->{sign_password} = 'secret';
    @warned = ();
    my $result = $p->build;
    ok($result->{success}, 'the Windows build succeeds');
    ok(-f "$out/Win/win.bat", 'with its launcher');
    ok(scalar(grep { /signtool signing failed/ } @warned), 'and warns when signtool is missing');
}

# --- a macOS build, signed ad hoc and put on a disk image ---
SKIP: {
    skip 'macOS builds need darwin', 14 unless $^O eq 'darwin';
    my $out = "$dir/macos";
    mkdir $out or die;
    my $icns = write_file("$dir/icon.icns", 'icns bytes');
    my $p = Chandra::Pack->new(script => $script, name => 'Mac App', version => '1.2', output => $out, icon => $icns, assets => "$dir/assets", perl => '/no/such/perl');
    like($p->_generate_plist, qr/CFBundleIconFile/, 'the plist names the icon when there is one');
    my $result = $p->build;
    ok($result->{success}, 'the macOS build succeeds');
    ok(-f "$out/MacApp.app/Contents/Resources/app.icns", 'an icns icon is copied');
    ok(-x "$out/MacApp.app/Contents/MacOS/macapp", 'the launcher is compiled');
    ok(-f "$out/MacApp.app/Contents/Resources/assets/a.txt", 'assets are copied');
    my ($so) = glob("$out/MacApp.app/Contents/Resources/lib/auto/Cpanel/JSON/XS/XS.*");
    ok($so, 'the XS library of a dependency is copied');

    my $png = Chandra::Pack->new(script => $script, name => 'Png App', output => $out, icon => "$dir/icon.png");
    ok($png->build->{success}, 'a build with a png icon');
    ok(-f "$out/PngApp.app/Contents/Resources/app.icns", 'ends with an icns, made or copied');

    my $dist = Chandra::Pack->new(script => $script, name => 'Dist App', output => $out, distribute => 1);
    my $signed = $dist->build;
    ok($signed->{success}, 'an ad hoc signed build with a disk image succeeds') or diag($signed->{error});
    ok($signed->{signed} && -f $signed->{dmg_path}, 'signed, with the image written');

    like($dist->_codesign_macos("$out/nothing.app", '-')->{error}, qr/codesign failed/, 'signing a missing app fails');
    like($dist->_create_dmg_macos("$out/nothing.app")->{error}, qr/DMG creation failed/, 'imaging a missing app fails');
    my $note = $dist->_notarize_macos("$out/nothing.app");
    like($note->{error}, qr/Failed to create ZIP|Notarization failed/, 'notarising a missing app fails');
    Chandra::Pack->config(notary_keychain => 'profile');
    $note = $dist->_notarize_macos("$out/DistApp.app");
    like($note->{error}, qr/Notarization failed/, 'and notarising without credentials fails after the zip');
    Chandra::Pack->config(notary_keychain => undef);

    Chandra::Pack->config(identity => 'Not A Real Identity', apple_id => 'a', team_id => 't');
    my $bad = Chandra::Pack->new(script => $script, name => 'Bad Sign', output => $out, distribute => 1)->build;
    ok(!$bad->{success}, 'a signing identity that does not exist fails the distribution');
    Chandra::Pack->config(identity => undef, apple_id => undef, team_id => undef);

    my $nocc = Chandra::Pack->new(script => $script, name => 'No Compile', output => "$dir/icon.png");
    eval { $nocc->build };
    like($@, qr/Failed to compile macOS launcher|cannot|Not a directory|exists/i, 'a launcher that cannot be written dies');
}

done_testing;
