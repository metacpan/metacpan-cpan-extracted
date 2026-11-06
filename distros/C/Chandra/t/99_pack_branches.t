#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# The configuration fallbacks and the tool failures of Chandra::Pack, driven
# with fake commands on the PATH. getpwuid is replaced before the module
# compiles so that the account home can be taken away.
my $pw_home;
BEGIN { *CORE::GLOBAL::getpwuid = sub { return ((undef) x 7, $pw_home) } }

use Chandra::Pack;

my $dir = tempdir(CLEANUP => 1);
local $ENV{HOME} = $dir;
my @warned;
local $SIG{__WARN__} = sub { push @warned, $_[0] };

sub write_file { my ($path, $content) = @_; open my $fh, '>', $path or die "$path: $!"; print $fh $content; close $fh; return $path }
sub slurp { local (@ARGV, $/) = @_; return scalar <> }
my $bin = "$dir/bin";
mkdir $bin or die;
sub fake { my ($name, $body) = @_; write_file("$bin/$name", "#!/bin/sh\n$body\n"); chmod 0755, "$bin/$name" }

my $script = write_file("$dir/app.pl", "use strict;\nuse Cpanel::JSON::XS;\nprint 1;\n");

# --- the configuration file without a HOME ---
{
    local $ENV{HOME} = '';
    local $ENV{USERPROFILE} = "$dir/profile";
    like(Chandra::Pack::_config_file(), qr{^\Q$dir/profile\E/}, 'with no HOME and no account home the profile directory is used');
    delete local $ENV{USERPROFILE};
    my $cwd = Chandra::Pack::_config_file();
    unlike($cwd, qr{^\Q$dir\E}, 'with neither the current directory is used');
    like($cwd, qr{\.chandra/pack\.conf$}, 'under its own directory');
    $pw_home = "$dir/pw";
    like(Chandra::Pack::_config_file(), qr{^\Q$dir/pw\E/}, 'the account home is read when HOME is empty');
}

# --- saving the configuration ---
{
    local $ENV{HOME} = "$dir/fresh";
    Chandra::Pack->config(identity => 'I', sign_cert => 'c', sign_password => 'p', save => 1);
    my $file = "$dir/fresh/.chandra/pack.conf";
    ok(-f $file, 'saving makes the directory');
    like(slurp($file), qr/^sign_cert = c$/m, 'and writes the certificate');
    Chandra::Pack->config(identity => undef, save => 1);
    unlike(slurp($file), qr/^identity/m, 'a key set to undef is left out of the file');
    Chandra::Pack->config(sign_cert => undef, sign_password => undef, apple_id => undef, team_id => undef, notary_keychain => undef);
}

# --- a script named by its extension alone ---
{
    my $dot = write_file("$dir/.pl", "1;\n");
    is(Chandra::Pack->new(script => $dot)->name, '', 'a script named only by its extension has an empty name');
}

# --- a Linux build with an icon that is missing, scanned past a code reference in @INC ---
{
    my $out = "$dir/linux";
    mkdir $out or die;
    my $p = Chandra::Pack->new(script => $script, name => 'Gap', output => $out, platform => 'linux', icon => "$dir/missing.png");
    local @INC = (sub { }, @INC);
    ok($p->build->{success}, 'a Linux build with a missing icon still succeeds');
    ok(!-e "$out/Gap/gap.png", 'and copies no icon');
    unlike($p->_generate_desktop, qr/^Icon=.*\./m, 'the desktop entry names the icon without an extension');
}

# --- the asset copies ---
{
    my $p = Chandra::Pack->new(script => $script, name => 'NoAssets');
    $p->_copy_assets("$dir/none");
    ok(!-d "$dir/none", 'no assets, nothing copied');
    $p->{assets} = "$dir/not-there";
    $p->_copy_assets("$dir/none2");
    ok(!-d "$dir/none2", 'a missing assets directory copies nothing');
    mkdir "$dir/src" or die;
    write_file("$dir/src/a.txt", 'a');
    mkdir "$dir/dst" or die;
    Chandra::Pack::_copy_dir_recursive("$dir/src", "$dir/dst");
    ok(-f "$dir/dst/a.txt", 'copying into a directory that exists works');
}

# --- a Windows build signed by a signtool that works, without a password ---
{
    my $out = "$dir/win";
    mkdir $out or die;
    ok(Chandra::Pack->new(script => $script, name => 'WinNoIcon', output => $out, platform => 'windows', icon => "$dir/missing.ico")->build->{success}, 'a Windows build whose icon is missing goes on without one');
    my $p = Chandra::Pack->new(script => $script, name => 'WinSign', output => $out, platform => 'windows');
    $p->{sign_cert} = "$dir/cert.pfx";
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    fake('signtool', 'exit 0');
    @warned = ();
    ok($p->build->{success}, 'a Windows build signs with a signtool that succeeds');
    ok(!scalar(grep { /signtool/ } @warned), 'without a warning');
    unlink "$bin/signtool";
}

# --- a which that names a file that cannot run ---
{
    local $ENV{PATH} = "$bin:$ENV{PATH}";
    write_file("$dir/not-executable", '');
    fake('which', "echo $dir/not-executable");
    is(Chandra::Pack::_find_command('anything'), undef, 'a which that names a file that cannot run is not believed');
    unlink "$bin/which";
}

# --- macOS: icons the tools refuse, and the signing pipeline ---
SKIP: {
    skip 'macOS builds need darwin', 14 unless $^O eq 'darwin';
    my $out = "$dir/mac";
    mkdir $out or die;
    local $ENV{PATH} = "$bin:$ENV{PATH}";

    my $jpg = write_file("$dir/icon.jpg", 'jpeg bytes');
    my $p = Chandra::Pack->new(script => $script, name => 'Jpeg', output => $out, icon => $jpg);
    $p->{perl} = '';
    ok($p->build->{success}, 'a build with a jpeg icon and an empty perl path succeeds');
    ok(!-e "$out/Jpeg.app/Contents/Resources/app.icns", 'and ends without an icns');

    require MIME::Base64;
    my $png = write_file("$dir/icon.png", MIME::Base64::decode_base64('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='));
    fake('sips', 'exit 1');
    my $icns = "$dir/conv1.icns";
    $p->_convert_icon_macos($png, $icns);
    ok(-f $icns, 'when sips fails the png is copied in place of the icns');
    $p->_convert_icon_macos($png, $icns);
    pass('and converting again leaves the copy');
    unlink "$bin/sips";
    fake('iconutil', 'exit 1');
    my $icns2 = "$dir/conv2.icns";
    $p->_convert_icon_macos($png, $icns2);
    ok(-f $icns2, 'when iconutil fails the png is copied too');
    unlink "$bin/iconutil";

    my $dist = Chandra::Pack->new(script => $script, name => 'Notary', output => $out);
    my $built = $dist->build;
    ok($built->{success}, 'the app to distribute is built');
    fake('codesign', 'exit 0');
    fake('xcrun', 'case "$2" in submit) exit ${FAKE_SUBMIT:-0};; staple) exit ${FAKE_STAPLE:-0};; esac; exit 0');
    fake('hdiutil', 'exit 1');
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => 'a@example.com', team_id => undef);
    my $r = $dist->_distribute_macos({ %$built });
    like($r->{error}, qr/DMG creation failed/, 'with no team id the signed app goes straight to the image, which fails');
    ok($r->{signed} && !$r->{notarized}, 'signed but not notarised');
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => undef, team_id => 'TEAM');
    $r = $dist->_distribute_macos({ %$built });
    ok(!$r->{notarized}, 'with no apple id likewise');
    Chandra::Pack->config(identity => 'Fake Identity', apple_id => 'a@example.com', team_id => 'TEAM');
    {
        local $ENV{FAKE_SUBMIT} = 1;
        $r = $dist->_distribute_macos({ %$built });
        like($r->{error}, qr/Notarization failed/, 'a submission that fails stops the distribution');
    }
    {
        local $ENV{FAKE_STAPLE} = 1;
        $r = $dist->_distribute_macos({ %$built });
        like($r->{error}, qr/Stapling failed/, 'a staple that fails stops it too');
    }
    $r = $dist->_distribute_macos({ %$built });
    ok($r->{notarized}, 'a notarisation that passes is recorded');
    like($r->{error}, qr/DMG creation failed/, 'before the image fails');
    ok(!-e "$out/Notary.app.zip", 'the zip sent for notarisation is removed');
    unlink "$bin/$_" for qw(codesign xcrun hdiutil);
    Chandra::Pack->config(identity => undef, apple_id => undef, team_id => undef);
}

done_testing;
