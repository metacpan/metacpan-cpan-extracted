package Chandra::Pack;

use strict;
use warnings;

our $VERSION = '0.21';

use File::Raw qw(import);
use Cwd ();

# ── Configuration Storage ────────────────────────────────────────────

our %CONFIG = (
    # macOS
    identity        => '-',          # ad-hoc signing by default
    apple_id        => undef,
    team_id         => undef,
    notary_keychain => undef,
    
    # Windows (future)
    sign_cert       => undef,
    sign_password   => undef,
);

sub config {
    my $class = shift;
    
    # Getter: config() or config('key')
    if (@_ == 0) {
        return %CONFIG;
    }
    if (@_ == 1 && !ref $_[0]) {
        return $CONFIG{$_[0]};
    }
    
    # Setter: config(key => val, ...)
    my %args = ref $_[0] eq 'HASH' ? %{$_[0]} : @_;
    
    # Load from env vars if not provided
    $args{identity}        //= $ENV{CHANDRA_IDENTITY};
    $args{apple_id}        //= $ENV{CHANDRA_APPLE_ID};
    $args{team_id}         //= $ENV{CHANDRA_TEAM_ID};
    $args{notary_keychain} //= $ENV{CHANDRA_NOTARY_KEYCHAIN};
    $args{sign_cert}       //= $ENV{CHANDRA_SIGN_CERT};
    $args{sign_password}   //= $ENV{CHANDRA_SIGN_PASSWORD};
    
    for my $key (keys %args) {
        if (exists $CONFIG{$key}) {
            $CONFIG{$key} = $args{$key};
        } else {
            Carp::carp("Unknown config key: $key");
        }
    }
    
    # Save to file if requested
    if (delete $args{save}) {
        _save_config();
    }
    
    return $class;
}

sub _config_file {
    my $home = $ENV{HOME} || (getpwuid($<))[7] || '.';
    return file_join($home, '.chandra', 'pack.conf');
}

sub _load_config {
    my $file = _config_file();
    return unless file_is_file($file);
    my $content = file_slurp($file);
    for my $line (split /\n/, $content) {
        next if $line =~ /^\s*#/ || $line =~ /^\s*$/;
        if ($line =~ /^(\w+)\s*=\s*(.*)$/) {
            $CONFIG{$1} = $2 if exists $CONFIG{$1};
        }
    }
}

sub _save_config {
    my $file = _config_file();
    my $dir = file_dirname($file);
    file_mkpath($dir) unless file_is_dir($dir);
    my $content = "# Chandra::Pack configuration\n";
    for my $key (sort keys %CONFIG) {
        next unless defined $CONFIG{$key};
        $content .= "$key = $CONFIG{$key}\n";
    }
    file_spew($file, $content);
    chmod 0600, $file;  # Protect credentials
}

# Load config on module load
_load_config();

sub new {
    my ($class, %args) = @_;
    Carp::croak("'script' is required") unless $args{script};
    Carp::croak("Script '$args{script}' not found") unless file_exists($args{script});
    Carp::croak("Script '$args{script}' is not a file") unless file_is_file($args{script});

    my $name = $args{name} || _name_from_script($args{script});
    bless {
        script     => Cwd::abs_path($args{script}),
        name       => $name,
        version    => $args{version}    || '0.0.1',
        icon       => $args{icon},
        assets     => $args{assets},
        output     => $args{output}     || '.',
        platform   => $args{platform}   || _detect_platform(),
        identifier => $args{identifier} || _default_identifier($name),
        perl       => $args{perl}       || $^X,
        include    => $args{include}    || [],
        exclude    => $args{exclude}    || [],
        distribute => $args{distribute} || 0,
        _deps      => undef,
    }, $class;
}

# ── Accessors ────────────────────────────────────────────────────────

sub script     { $_[0]->{script} }
sub name       { $_[0]->{name} }
sub version    { $_[0]->{version} }
sub icon       { $_[0]->{icon} }
sub assets     { $_[0]->{assets} }
sub output     { $_[0]->{output} }
sub platform   { $_[0]->{platform} }
sub identifier { $_[0]->{identifier} }
sub perl       { $_[0]->{perl} }
sub distribute { $_[0]->{distribute} }

# ── Dependency Scanning ──────────────────────────────────────────────

sub scan_deps {
    my ($self) = @_;
    return @{ $self->{_deps} } if $self->{_deps};

    my %seen;
    my %exclude = map { $_ => 1 } @{ $self->{exclude} };
    my @queue = ($self->{script});
    my @deps;

    # Add explicit includes
    for my $mod (@{ $self->{include} }) {
        my $file = _mod_to_file($mod);
        my $path = _find_in_inc($file);
        if ($path) {
            push @deps, { module => $mod, file => $path };
            push @queue, $path;
        }
    }

    while (my $file = shift @queue) {
        next if $seen{$file}++;
        my $content = eval { file_slurp($file) };
        next unless defined $content;

        # Extract use/require statements
        while ($content =~ /^\s*(?:use|require)\s+([\w:]+)/mg) {
            my $mod = $1;
            next if $exclude{$mod};
            next if _is_pragma($mod);
            my $mod_file = _mod_to_file($mod);
            my $path = _find_in_inc($mod_file);
            if ($path && !$seen{$path}) {
                push @deps, { module => $mod, file => $path };
                push @queue, $path;
            }
        }
    }

    $self->{_deps} = \@deps;
    return @deps;
}

# ── Build ────────────────────────────────────────────────────────────

sub build {
    my ($self, $cb) = @_;
    my $platform = $self->{platform};
    my $method = "build_$platform";
    Carp::croak("Unsupported platform: $platform") unless $self->can($method);

    my $result = $self->$method();
    $cb->($result) if $cb;
    return $result;
}

sub build_macos {
    my ($self) = @_;
    Carp::croak('macOS builds are only supported on darwin hosts') unless $^O eq 'darwin';
    my $safe = _safe_name($self->{name});
    my $app_dir = file_join($self->{output}, "$safe.app");
    my $contents = file_join($app_dir, 'Contents');
    my $macos = file_join($contents, 'MacOS');
    my $resources = file_join($contents, 'Resources');
    my $lib_dir = file_join($resources, 'lib');

    # Create structure
    file_mkpath($macos);
    file_mkpath($resources);
    file_mkpath($lib_dir);

    # Info.plist
    file_spew(file_join($contents, 'Info.plist'), $self->_generate_plist());

    # Launcher (compiled C binary so macOS Launch Services accepts it)
    my $launcher = file_join($macos, lc($safe));
    $self->_compile_launcher_macos($launcher);

    # Copy script
    file_copy($self->{script}, file_join($resources, 'script.pl'));

    # Copy deps
    $self->_copy_deps($lib_dir);

    # Icon
    if ($self->{icon} && file_exists($self->{icon})) {
        my $ext = file_extname($self->{icon});
        if ($ext eq '.icns') {
            file_copy($self->{icon}, file_join($resources, 'app.icns'));
        } elsif ($ext eq '.png') {
            $self->_convert_icon_macos($self->{icon}, file_join($resources, 'app.icns'));
        }
    }

    # Assets
    $self->_copy_assets(file_join($resources, 'assets')) if $self->{assets};

    my $result = {
        success  => 1,
        path     => $app_dir,
        platform => 'macos',
        size     => _dir_size($app_dir),
    };

    # Distribution pipeline: codesign → notarize → DMG
    if ($self->{distribute}) {
        $result = $self->_distribute_macos($result);
    }

    return $result;
}

sub build_linux {
    my ($self) = @_;
    my $safe = _safe_name($self->{name});
    my $app_dir = file_join($self->{output}, $safe);
    my $usr = file_join($app_dir, 'usr');
    my $lib_dir = file_join($usr, 'lib', 'perl5');
    my $share = file_join($usr, 'share');

    # Create structure
    file_mkpath($lib_dir);
    file_mkpath($share);

    # AppRun
    my $apprun = file_join($app_dir, 'AppRun');
    file_spew($apprun, $self->_generate_launcher_linux());
    chmod 0755, $apprun;

    # Desktop entry
    file_spew(file_join($app_dir, lc($safe) . '.desktop'), $self->_generate_desktop());

    # Copy script
    file_copy($self->{script}, file_join($usr, 'share', 'script.pl'));

    # Copy deps
    $self->_copy_deps($lib_dir);

    # Icon
    if ($self->{icon} && file_exists($self->{icon})) {
        file_copy($self->{icon}, file_join($app_dir, lc($safe) . file_extname($self->{icon})));
    }

    # Assets
    $self->_copy_assets(file_join($share, 'assets')) if $self->{assets};

    my $result = {
        success  => 1,
        path     => $app_dir,
        platform => 'linux',
        size     => _dir_size($app_dir),
    };

    # Distribution pipeline: AppImage
    if ($self->{distribute}) {
        $result = $self->_distribute_linux($result);
    }

    return $result;
}

sub build_windows {
    my ($self) = @_;
    my $safe = _safe_name($self->{name});
    my $app_dir = file_join($self->{output}, $safe);
    my $lib_dir = file_join($app_dir, 'lib');

    # Create structure
    file_mkpath($lib_dir);

    # Launcher bat
    file_spew(file_join($app_dir, lc($safe) . '.bat'), $self->_generate_launcher_windows());

    # Copy script
    file_copy($self->{script}, file_join($app_dir, 'script.pl'));

    # Copy deps
    $self->_copy_deps($lib_dir);

    # Assets
    $self->_copy_assets(file_join($app_dir, 'assets')) if $self->{assets};

    return {
        success  => 1,
        path     => $app_dir,
        platform => 'windows',
        size     => _dir_size($app_dir),
    };
}

# ── Distribution Pipelines ───────────────────────────────────────────

sub _distribute_macos {
    my ($self, $result) = @_;
    my $app_path = $result->{path};
    my $identity = $CONFIG{identity} || '-';
    
    # Step 1: Code sign
    my $sign_result = $self->_codesign_macos($app_path, $identity);
    unless ($sign_result->{success}) {
        return { %$result, success => 0, error => $sign_result->{error} };
    }
    $result->{signed} = 1;
    
    # Step 2: Notarize (skip for ad-hoc signing)
    if ($identity ne '-' && $CONFIG{apple_id} && $CONFIG{team_id}) {
        my $notarize_result = $self->_notarize_macos($app_path);
        unless ($notarize_result->{success}) {
            return { %$result, success => 0, error => $notarize_result->{error} };
        }
        $result->{notarized} = 1;
    }
    
    # Step 3: Create DMG
    my $dmg_result = $self->_create_dmg_macos($app_path);
    unless ($dmg_result->{success}) {
        return { %$result, success => 0, error => $dmg_result->{error} };
    }
    $result->{dmg_path} = $dmg_result->{path};
    $result->{size} = file_size($dmg_result->{path});
    
    return $result;
}

sub _codesign_macos {
    my ($self, $app_path, $identity) = @_;
    
    # Generate entitlements for hardened runtime
    my $entitlements = $self->_generate_entitlements_macos();
    require File::Temp;
    my $ent_file = File::Temp->new(SUFFIX => '.plist', UNLINK => 1);
    print $ent_file $entitlements;
    close $ent_file;
    
    my @cmd = (
        'codesign',
        '--deep',
        '--force',
        '--sign', $identity,
        '--options', 'runtime',
        '--entitlements', "$ent_file",
        $app_path
    );
    
    my $output = `@cmd 2>&1`;
    if ($? != 0) {
        return { success => 0, error => "codesign failed: $output" };
    }
    
    return { success => 1 };
}

sub _generate_entitlements_macos {
    return <<'ENTITLEMENTS';
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.cs.allow-jit</key>
    <true/>
    <key>com.apple.security.cs.allow-unsigned-executable-memory</key>
    <true/>
    <key>com.apple.security.cs.disable-library-validation</key>
    <true/>
</dict>
</plist>
ENTITLEMENTS
}

sub _notarize_macos {
    my ($self, $app_path) = @_;
    
    # Create ZIP for submission
    my $zip_path = "$app_path.zip";
    my $zip_cmd = "ditto -c -k --keepParent \Q$app_path\E \Q$zip_path\E 2>&1";
    my $zip_out = `$zip_cmd`;
    if ($? != 0) {
        return { success => 0, error => "Failed to create ZIP: $zip_out" };
    }
    
    # Submit to notarization service
    my @submit_cmd = (
        'xcrun', 'notarytool', 'submit',
        '--apple-id', $CONFIG{apple_id},
        '--team-id', $CONFIG{team_id},
        '--wait',
    );
    
    if ($CONFIG{notary_keychain}) {
        push @submit_cmd, '--keychain-profile', $CONFIG{notary_keychain};
    } else {
        # Will prompt for password
        push @submit_cmd, '--password', '@env:CHANDRA_NOTARY_PASSWORD';
    }
    
    push @submit_cmd, $zip_path;
    
    my $submit_out = `@submit_cmd 2>&1`;
    unlink $zip_path;
    
    if ($? != 0) {
        return { success => 0, error => "Notarization failed: $submit_out" };
    }
    
    # Staple the ticket
    my $staple_cmd = "xcrun stapler staple \Q$app_path\E 2>&1";
    my $staple_out = `$staple_cmd`;
    if ($? != 0) {
        return { success => 0, error => "Stapling failed: $staple_out" };
    }
    
    return { success => 1 };
}

sub _create_dmg_macos {
    my ($self, $app_path) = @_;
    
    my $safe = _safe_name($self->{name});
    my $vol_name = $self->{name};
    my $dmg_path = file_join($self->{output}, "$safe.dmg");
    my $temp_dmg = "$dmg_path.tmp";
    
    # Create temporary DMG
    my $size = _dir_size($app_path);
    my $size_mb = int($size / 1_000_000) + 50;  # Add 50MB headroom
    
    # Create DMG
    my @hdiutil = (
        'hdiutil', 'create',
        '-volname', $vol_name,
        '-srcfolder', $app_path,
        '-ov',
        '-format', 'UDBZ',  # Compressed
        $dmg_path
    );
    
    my $output = `@hdiutil 2>&1`;
    if ($? != 0) {
        return { success => 0, error => "DMG creation failed: $output" };
    }
    
    return { success => 1, path => $dmg_path };
}

sub _distribute_linux {
    my ($self, $result) = @_;
    my $app_dir = $result->{path};
    
    # Check for appimagetool
    my $appimagetool = _find_command('appimagetool');
    unless ($appimagetool) {
        Carp::carp("appimagetool not found; skipping AppImage creation");
        return $result;
    }
    
    # Create AppImage
    my $appimage_result = $self->_create_appimage($app_dir, $appimagetool);
    unless ($appimage_result->{success}) {
        return { %$result, success => 0, error => $appimage_result->{error} };
    }
    
    $result->{appimage_path} = $appimage_result->{path};
    $result->{size} = file_size($appimage_result->{path});
    
    return $result;
}

sub _create_appimage {
    my ($self, $app_dir, $appimagetool) = @_;
    
    my $safe = _safe_name($self->{name});
    my $appimage_path = file_join($self->{output}, "$safe.AppImage");
    
    # Ensure proper AppDir structure
    # AppRun should already exist from build_linux
    # Ensure .desktop file is at root level
    my $desktop_file = file_join($app_dir, lc($safe) . '.desktop');
    unless (file_is_file($desktop_file)) {
        return { success => 0, error => "Missing .desktop file" };
    }
    
    # Run appimagetool
    my $cmd = "\Q$appimagetool\E \Q$app_dir\E \Q$appimage_path\E 2>&1";
    my $output = `$cmd`;
    if ($? != 0) {
        return { success => 0, error => "appimagetool failed: $output" };
    }
    
    # Make executable
    chmod 0755, $appimage_path;
    
    return { success => 1, path => $appimage_path };
}

sub _find_command {
    my ($cmd) = @_;
    my $path = `which $cmd 2>/dev/null`;
    chomp $path;
    return $path if $path && -x $path;
    
    # Check common locations
    for my $dir ('/usr/local/bin', '/usr/bin', "$ENV{HOME}/bin", "$ENV{HOME}/.local/bin") {
        my $full = "$dir/$cmd";
        return $full if -x $full;
    }
    
    return undef;
}

# ── Template Generators ──────────────────────────────────────────────

sub _generate_plist {
    my ($self) = @_;
    my $safe = _safe_name($self->{name});
    my $has_icon = ($self->{icon} && file_exists($self->{icon})) ? 1 : 0;
    my $plist = <<PLIST;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>$self->{name}</string>
    <key>CFBundleIdentifier</key><string>$self->{identifier}</string>
    <key>CFBundleVersion</key><string>$self->{version}</string>
    <key>CFBundleShortVersionString</key><string>$self->{version}</string>
    <key>CFBundleExecutable</key><string>${\ lc($safe) }</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSEnvironment</key>
    <dict>
        <key>PATH</key><string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
PLIST
    if ($has_icon) {
        $plist .= "    <key>CFBundleIconFile</key><string>app</string>\n";
    }
    $plist .= "</dict>\n</plist>\n";
    return $plist;
}

sub _compile_launcher_macos {
    my ($self, $output) = @_;
    my $perl = $self->{perl};
    chomp(my $full_perl = `which $perl` || $perl);
    my $c_src = <<'CSRC';
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include <limits.h>

int main(int argc, char **argv) {
    char exe[PATH_MAX], dir[PATH_MAX], resources[PATH_MAX];
    char lib[PATH_MAX], perl5lib[PATH_MAX * 2];
    char script[PATH_MAX];

    /* Find our own location */
    uint32_t sz = sizeof(exe);
    if (_NSGetExecutablePath(exe, &sz) != 0) {
        fprintf(stderr, "Cannot determine executable path\n");
        return 1;
    }
    realpath(exe, dir);
    char *d = dirname(dir);

    snprintf(resources, sizeof(resources), "%s/../Resources", d);
    snprintf(lib, sizeof(lib), "%s/lib", resources);
    snprintf(script, sizeof(script), "%s/script.pl", resources);

    /* Set PERL5LIB */
    const char *existing = getenv("PERL5LIB");
    if (existing && *existing)
        snprintf(perl5lib, sizeof(perl5lib), "%s:%s", lib, existing);
    else
        snprintf(perl5lib, sizeof(perl5lib), "%s", lib);
    setenv("PERL5LIB", perl5lib, 1);

CSRC
    $c_src .= "    execl(\"$full_perl\", \"$full_perl\", script, (char *)NULL);\n";
    $c_src .= <<'CSRC';
    perror("exec");
    return 1;
}
CSRC

    require File::Temp;
    my $tmp = File::Temp->new(SUFFIX => '.c', UNLINK => 1);
    print $tmp $c_src;
    close $tmp;

    my $cmd = "cc -o \Q$output\E -framework Foundation \Q$tmp\E 2>&1";
    my $out = `$cmd`;
    if ($? != 0) {
        die "Failed to compile macOS launcher: $out\n";
    }
}

sub _generate_launcher_macos {
    my ($self) = @_;
    my $perl = $self->{perl};
    return <<'LAUNCHER';
#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
export PERL5LIB="$DIR/../Resources/lib:$PERL5LIB"
exec "$perl" "$DIR/../Resources/script.pl" "$@"
LAUNCHER
}

sub _generate_launcher_linux {
    my ($self) = @_;
    my $perl = $self->{perl};
    return <<LAUNCHER;
#!/bin/bash
DIR="\$(cd "\$(dirname "\$0")" && pwd)"
export PERL5LIB="\$DIR/usr/lib/perl5:\$PERL5LIB"
exec "$perl" "\$DIR/usr/share/script.pl" "\$@"
LAUNCHER
}

sub _generate_launcher_windows {
    my ($self) = @_;
    my $perl = $self->{perl};
    return <<LAUNCHER;
\@echo off
set DIR=%~dp0
set PERL5LIB=%DIR%lib;%PERL5LIB%
"$perl" "%DIR%script.pl" %*
LAUNCHER
}

sub _generate_desktop {
    my ($self) = @_;
    my $safe = lc(_safe_name($self->{name}));
    my $icon_ext = '';
    $icon_ext = file_extname($self->{icon}) if $self->{icon} && file_exists($self->{icon});
    return <<DESKTOP;
[Desktop Entry]
Type=Application
Name=$self->{name}
Exec=./AppRun
Icon=${safe}${icon_ext}
Categories=Utility;
DESKTOP
}

# ── Internal Helpers ─────────────────────────────────────────────────

sub _copy_deps {
    my ($self, $lib_dir) = @_;
    my @deps = $self->scan_deps;
    for my $dep (@deps) {
        my $mod_file = _mod_to_file($dep->{module});
        my $dest = file_join($lib_dir, $mod_file);
        my $dest_dir = file_dirname($dest);
        file_mkpath($dest_dir) unless file_is_dir($dest_dir);
        file_copy($dep->{file}, $dest);

        # Copy XS shared object if present
        my $xs_so = _find_xs_so($dep->{file}, $dep->{module});
        if ($xs_so) {
            my $auto_dir = _auto_dir($dep->{module});
            my $so_dest_dir = file_join($lib_dir, $auto_dir);
            file_mkpath($so_dest_dir) unless file_is_dir($so_dest_dir);
            file_copy($xs_so, file_join($so_dest_dir, file_basename($xs_so)));
        }
    }
}

sub _copy_assets {
    my ($self, $dest_dir) = @_;
    my $src = $self->{assets};
    return unless $src && file_is_dir($src);
    _copy_dir_recursive($src, $dest_dir);
}

sub _copy_dir_recursive {
    my ($src, $dest) = @_;
    file_mkpath($dest) unless file_is_dir($dest);
    my $entries = file_readdir($src);
    for my $entry (@$entries) {
        next if $entry eq '.' || $entry eq '..';
        my $s = file_join($src, $entry);
        my $d = file_join($dest, $entry);
        if (file_is_dir($s)) {
            _copy_dir_recursive($s, $d);
        } else {
            file_copy($s, $d);
        }
    }
}

sub _convert_icon_macos {
    my ($self, $png, $icns) = @_;
    # Use sips + iconutil if available, but suppress image conversion stderr
    my $iconset = "$icns.iconset";
    file_mkpath($iconset);
    my @sizes = (16, 32, 64, 128, 256, 512);
    my $had_icon = 0;

    for my $s (@sizes) {
        my $out_png = file_join($iconset, "icon_${s}x${s}.png");
        {
            open my $err, '>', '/dev/null' or last;
            local *STDERR = $err;
            if (system('sips', '-z', $s, $s, $png, '--out', $out_png) == 0) {
                $had_icon = 1;
                my $s2 = $s * 2;
                if ($s2 <= 1024) {
                    system('sips', '-z', $s2, $s2, $png, '--out',
                        file_join($iconset, "icon_${s}x${s}\@2x.png"));
                }
            }
        }
    }

    if ($had_icon && system('iconutil', '-c', 'icns', $iconset, '-o', $icns) == 0) {
        # success
    } else {
        # Fallback: just copy the PNG to preserve the icon reference
        file_copy($png, $icns) unless file_is_file($icns);
    }

    # Clean up iconset
    file_rm_rf($iconset);
}

sub _find_xs_so {
    my ($pm_path, $module) = @_;
    my $auto_dir = _auto_dir($module);
    for my $inc (@INC) {
        next if ref $inc;
        my $dir = file_join($inc, $auto_dir);
        next unless file_is_dir($dir);
        my $entries = file_readdir($dir);
        for my $e (@$entries) {
            return file_join($dir, $e) if $e =~ /\.\Q$Config::Config{dlext}\E$/;
        }
    }
    return undef;
}

sub _auto_dir {
    my ($module) = @_;
    my $path = $module;
    $path =~ s/::/\//g;
    return "auto/$path";
}

sub _find_in_inc {
    my ($file) = @_;
    for my $dir (@INC) {
        next if ref $dir;
        my $path = file_join($dir, $file);
        return $path if file_is_file($path);
    }
    return undef;
}

sub _mod_to_file {
    my ($mod) = @_;
    $mod =~ s/::/\//g;
    return "$mod.pm";
}

sub _is_pragma {
    my ($mod) = @_;
    return 1 if $mod =~ /^(strict|warnings|utf8|constant|feature|overload|overloading|lib|vars|base|parent|fields|integer|bigint|bignum|bigrat|bytes|charnames|diagnostics|encoding|if|less|locale|mro|open|ops|re|sigtrap|sort|subs|threads|threads::shared|version|vmsish|autouse|autodie|experimental)$/;
    return 1 if $mod =~ /^[a-z]/; # convention: pragmas are lowercase
    return 0;
}

sub _name_from_script {
    my ($script) = @_;
    my $base = file_basename($script);
    $base =~ s/\.pl$//;
    $base =~ s/[_-]/ /g;
    return ucfirst($base);
}

sub _safe_name {
    my ($name) = @_;
    $name =~ s/[^a-zA-Z0-9_]//g;
    return $name || 'App';
}

sub _default_identifier {
    my ($name) = @_;
    my $safe = lc(_safe_name($name));
    return "org.perl.$safe";
}

sub _detect_platform {
    return 'macos'   if $^O eq 'darwin';
    return 'windows' if $^O eq 'MSWin32';
    return 'linux';
}

sub _dir_size {
    my ($dir) = @_;
    return 0 unless file_is_dir($dir);
    my $total = 0;
    my $entries = file_readdir($dir);
    for my $e (@$entries) {
        next if $e eq '.' || $e eq '..';
        my $path = file_join($dir, $e);
        if (file_is_dir($path)) {
            $total += _dir_size($path);
        } else {
            $total += file_size($path);
        }
    }
    return $total;
}

1;

__END__

=head1 NAME

Chandra::Pack - Bundle Chandra apps into distributable packages

=head1 SYNOPSIS

    use Chandra::Pack;

    # Configure credentials (once, persists to ~/.chandra/pack.conf)
    Chandra::Pack->config(
        identity    => 'Developer ID Application: Your Name',
        apple_id    => 'you@example.com',
        team_id     => 'ABCD1234',
        save        => 1,
    );

    my $packer = Chandra::Pack->new(
        script     => 'app.pl',
        name       => 'My App',
        version    => '1.0.0',
        icon       => 'icon.png',
        assets     => 'assets/',
        output     => 'dist/',
        identifier => 'com.example.myapp',
        distribute => 1,  # Full release pipeline
    );

    # Build with distribution (sign, notarize, DMG on macOS; AppImage on Linux)
    $packer->build(sub {
        my ($result) = @_;
        print "Built: $result->{path}\n" if $result->{success};
        print "DMG: $result->{dmg_path}\n" if $result->{dmg_path};
    });

=head1 DESCRIPTION

Chandra::Pack bundles a Perl script and its dependencies into a
distributable application package. It creates C<.app> bundles on macOS,
AppImage-style directories on Linux, and portable directories on Windows.

When C<distribute =E<gt> 1> is set, the full release pipeline runs:

=over 4

=item * B<macOS>: codesign → notarize → staple → DMG

=item * B<Linux>: AppImage (via appimagetool)

=item * B<Windows>: Directory build (installer support planned)

=back

=head1 CLASS METHODS

=head2 config(%args)

Configure credentials for signing and notarization. Call once before
building. Settings can be persisted to C<~/.chandra/pack.conf>.

    Chandra::Pack->config(
        # macOS signing/notarization
        identity         => 'Developer ID Application: ...',
        apple_id         => 'your@email.com',
        team_id          => 'ABCD1234',
        notary_keychain  => 'notary-profile',  # from notarytool store-credentials
        
        # Persist to disk
        save             => 1,
    );

Environment variables are used as fallbacks:

    CHANDRA_IDENTITY
    CHANDRA_APPLE_ID
    CHANDRA_TEAM_ID
    CHANDRA_NOTARY_KEYCHAIN
    CHANDRA_NOTARY_PASSWORD

=head1 INSTANCE METHODS

=head2 new(%args)

    my $packer = Chandra::Pack->new(
        script     => 'app.pl',       # required
        name       => 'My App',       # default: derived from script name
        version    => '1.0.0',        # default: 0.0.1
        icon       => 'icon.png',     # optional
        assets     => 'assets/',      # optional
        output     => 'dist/',        # default: .
        platform   => 'macos',        # default: current platform
        identifier => 'com.x.myapp',  # default: org.perl.<name>
        perl       => '/usr/bin/perl',# default: current perl
        include    => ['DBI'],        # extra modules to include
        exclude    => ['Test::More'], # modules to skip
        distribute => 1,              # run full distribution pipeline
    );

=head2 scan_deps

Returns a list of hashrefs with C<module> and C<file> keys for all
detected dependencies.

=head2 build($callback)

Build for the configured platform. Calls C<$callback> with a result
hashref containing C<success>, C<path>, C<platform>, and C<size>.

When C<distribute =E<gt> 1>:

=over 4

=item * macOS: adds C<signed>, C<notarized>, C<dmg_path>

=item * Linux: adds C<appimage_path>

=back

=head2 build_macos

Build a macOS C<.app> bundle. With C<distribute =E<gt> 1>, also signs,
notarizes, and creates a DMG.

=head2 build_linux

Build a Linux AppImage-style directory. With C<distribute =E<gt> 1>,
runs appimagetool to create a standalone AppImage.

=head2 build_windows

Build a Windows portable directory.

=head1 DISTRIBUTION DETAILS

=head2 macOS Code Signing

Uses hardened runtime with entitlements for JIT and unsigned memory
(required for Perl). Ad-hoc signing (C<identity =E<gt> '-'>) skips
notarization but still works locally.

=head2 macOS Notarization

Requires Apple Developer account. Store credentials once with:

    xcrun notarytool store-credentials notary-profile \
        --apple-id your@email.com \
        --team-id ABCD1234 \
        --password your-app-specific-password

Then configure:

    Chandra::Pack->config(notary_keychain => 'notary-profile');

=head2 Linux AppImage

Requires C<appimagetool> in PATH. Install from:
L<https://github.com/AppImage/AppImageKit/releases>

=head1 SEE ALSO

L<Chandra::App>

=cut
