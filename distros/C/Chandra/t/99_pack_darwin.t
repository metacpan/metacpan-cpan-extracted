#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# The platform arms of Chandra::Pack from the other side: the macOS steps run on
# any host with the operating system name localised and the Apple tools faked on
# the PATH, and the Linux and Windows arms run on a Mac the same way.

use Chandra::Pack;

my $dir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $dir;
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

sub write_file { my ($path, $content) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh $content; close $fh; return $path }
my $bin = "$dir/bin";
mkdir $bin or die;
sub fake { my ($name, $body) = @_; write_file("$bin/$name", "#!/bin/sh\n$body\n"); chmod 0755, "$bin/$name" }
my $script = write_file("$dir/app.pl", "use strict;\nuse Cpanel::JSON::XS;\nprint 1;\n");

# --- the arms of the other systems, from anywhere ---
{
    local $^O = 'linux';
    is(Chandra::Pack::_detect_platform(), 'linux', 'a Linux host builds for Linux');
    eval { Chandra::Pack->new(script => $script, name => 'Nope', output => $dir)->build_macos };
    like($@, qr/only supported on darwin/, 'and refuses a macOS build');
}
{
    local $^O = 'MSWin32';
    is(Chandra::Pack::_detect_platform(), 'windows', 'a Windows host builds for Windows');
    local $ENV{HOME} = '';
    local $ENV{USERPROFILE} = "$dir/profile";
    like(Chandra::Pack::_config_file(), qr{^\Q$dir/profile\E/}, 'and reads its profile directory without HOME');
}
{
    local $^O = 'darwin';
    is(Chandra::Pack::_detect_platform(), 'macos', 'a Mac builds for macOS');
}

# --- the macOS steps on a host that is not a Mac ---
if ($^O ne 'darwin') {
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    fake('cc', 'for a; do last=$a; done; while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out=$2; shift; done; : > "$out"; chmod 755 "$out"');
    fake('codesign', 'for a; do last=$a; done; [ -e "$last" ] || exit 1; exit 0');
    fake('ditto', 'for a; do last=$a; done; [ -e "$4" ] || exit 1; : > "$last"');
    fake('xcrun', 'case "$2" in submit) exit ${FAKE_SUBMIT:-0};; staple) exit ${FAKE_STAPLE:-0};; esac; exit 0');
    fake('hdiutil', 'for a; do last=$a; done; while [ $# -gt 0 ]; do [ "$1" = "-srcfolder" ] && src=$2; shift; done; [ -e "$src" ] || exit 1; : > "$last"');
    fake('sips', 'for a; do last=$a; done; : > "$last"');
    fake('iconutil', 'for a; do last=$a; done; : > "$last"');
    local $^O = 'darwin';
    my $out = "$dir/macos";
    mkdir $out or die;
    mkdir "$dir/assets" or die;
    write_file("$dir/assets/a.txt", 'a');
    my $icns = write_file("$dir/icon.icns", 'icns bytes');
    my $p = Chandra::Pack->new(script => $script, name => 'Mac App', version => '1.2', output => $out, icon => $icns, assets => "$dir/assets", perl => '/no/such/perl');
    like($p->_generate_plist, qr/CFBundleIconFile/, 'the plist names the icon when there is one');
    my $result = $p->build;
    ok($result->{success}, 'the macOS build succeeds with a faked compiler') or diag($result->{error});
    ok(-f "$out/MacApp.app/Contents/Resources/app.icns", 'an icns icon is copied');
    ok(-x "$out/MacApp.app/Contents/MacOS/macapp", 'the launcher is in place');
    ok(-f "$out/MacApp.app/Contents/Resources/assets/a.txt", 'assets are copied');

    my $png = write_file("$dir/icon.png", 'png bytes');
    ok(Chandra::Pack->new(script => $script, name => 'Png App', output => $out, icon => "$dir/icon.png")->build->{success}, 'a build with a png icon');
    ok(-f "$out/PngApp.app/Contents/Resources/app.icns", 'ends with an icns');
    ok(Chandra::Pack->new(script => $script, name => 'No Icon File', output => $out, icon => "$dir/missing.icns")->build->{success}, 'a build whose icon file is missing goes on without one');
    my $jpg = write_file("$dir/icon.jpg", 'jpeg bytes');
    my $nop = Chandra::Pack->new(script => $script, name => 'Jpeg', output => $out, icon => $jpg);
    $nop->{perl} = '';
    ok($nop->build->{success}, 'a build with a jpeg icon and an empty perl path succeeds');
    ok(!-e "$out/Jpeg.app/Contents/Resources/app.icns", 'and ends without an icns');

    my $dist = Chandra::Pack->new(script => $script, name => 'Dist App', output => $out, distribute => 1);
    my $signed = $dist->build;
    ok($signed->{success}, 'an ad hoc signed build with a disk image succeeds') or diag($signed->{error});
    ok($signed->{signed} && -f $signed->{dmg_path}, 'signed, with the image written');
    like($dist->_codesign_macos("$out/nothing.app", '-')->{error}, qr/codesign failed/, 'signing a missing app fails');
    like($dist->_create_dmg_macos("$out/nothing.app")->{error}, qr/DMG creation failed/, 'imaging a missing app fails');
    like($dist->_notarize_macos("$out/nothing.app")->{error}, qr/Failed to create ZIP/, 'notarising a missing app fails at the zip');

    Chandra::Pack->config(identity => 'Fake Identity', apple_id => 'a@example.com', team_id => 'TEAM', notary_keychain => 'profile');
    my $r = $dist->_distribute_macos({ %$signed });
    ok($r->{notarized} && $r->{success}, 'a notarisation through a keychain profile passes');
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => 'a@example.com', team_id => 'TEAM');
    {
        local $ENV{FAKE_SUBMIT} = 1;
        like($dist->_distribute_macos({ %$signed })->{error}, qr/Notarization failed/, 'a submission that fails stops the distribution');
    }
    {
        local $ENV{FAKE_STAPLE} = 1;
        like($dist->_distribute_macos({ %$signed })->{error}, qr/Stapling failed/, 'a staple that fails stops it too');
    }
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => 'a@example.com', team_id => undef);
    ok(!$dist->_distribute_macos({ %$signed })->{notarized}, 'with no team id the app is not notarised');
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => undef, team_id => 'TEAM');
    ok(!$dist->_distribute_macos({ %$signed })->{notarized}, 'with no apple id likewise');
    Chandra::Pack->config(identity => undef, apple_id => undef, team_id => undef);
    unlink "$bin/hdiutil";
    like($dist->_distribute_macos({ %$signed })->{error}, qr/DMG creation failed/, 'without hdiutil the image fails');
    unlink "$bin/codesign";
    fake('codesign', 'exit 1');
    like($dist->_distribute_macos({ %$signed })->{error}, qr/codesign failed/, 'a signing that fails stops the distribution');

    unlink "$bin/sips";
    fake('sips', 'exit 1');
    my $conv = "$dir/conv1.icns";
    $p->_convert_icon_macos($png, $conv);
    ok(-f $conv, 'when sips fails the png is copied in place of the icns');
    $p->_convert_icon_macos($png, $conv);
    pass('and converting again leaves the copy');
    unlink "$bin/sips";
    fake('sips', 'for a; do last=$a; done; : > "$last"');
    unlink "$bin/iconutil";
    fake('iconutil', 'exit 1');
    my $conv2 = "$dir/conv2.icns";
    $p->_convert_icon_macos($png, $conv2);
    ok(-f $conv2, 'when iconutil fails the png is copied too');

    my $nocc = Chandra::Pack->new(script => $script, name => 'No Compile', output => "$dir/icon.png");
    eval { $nocc->build };
    like($@, qr/Failed to compile macOS launcher|cannot|Not a directory|exists/i, 'a launcher that cannot be written dies');
}

done_testing;
