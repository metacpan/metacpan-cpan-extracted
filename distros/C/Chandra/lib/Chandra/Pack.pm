package Chandra::Pack;

use strict;
use warnings;

our $VERSION = '0.19';

use File::Raw qw(import);
use Cwd ();

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

    return {
        success  => 1,
        path     => $app_dir,
        platform => 'macos',
        size     => _dir_size($app_dir),
    };
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

    return {
        success  => 1,
        path     => $app_dir,
        platform => 'linux',
        size     => _dir_size($app_dir),
    };
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
    # Use sips + iconutil if available
    my $iconset = "$icns.iconset";
    file_mkpath($iconset);
    my @sizes = (16, 32, 64, 128, 256, 512);
    for my $s (@sizes) {
        system('sips', '-z', $s, $s, $png, '--out',
            file_join($iconset, "icon_${s}x${s}.png")) == 0 or next;
        my $s2 = $s * 2;
        if ($s2 <= 1024) {
            system('sips', '-z', $s2, $s2, $png, '--out',
                file_join($iconset, "icon_${s}x${s}\@2x.png"));
        }
    }
    if (system('iconutil', '-c', 'icns', $iconset, '-o', $icns) != 0) {
        # Fallback: just copy the PNG
        file_copy($png, $icns);
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

    my $packer = Chandra::Pack->new(
        script     => 'app.pl',
        name       => 'My App',
        version    => '1.0.0',
        icon       => 'icon.png',
        assets     => 'assets/',
        output     => 'dist/',
        identifier => 'com.example.myapp',
    );

    # Scan dependencies
    my @deps = $packer->scan_deps;

    # Build package
    $packer->build(sub {
        my ($result) = @_;
        print "Built: $result->{path}\n" if $result->{success};
    });

    # Or build for a specific platform
    $packer->build_macos;
    $packer->build_linux;
    $packer->build_windows;

=head1 DESCRIPTION

Chandra::Pack bundles a Perl script and its dependencies into a
distributable application package. It creates C<.app> bundles on macOS,
AppImage-style directories on Linux, and portable directories on Windows.

=head1 METHODS

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
    );

=head2 scan_deps

Returns a list of hashrefs with C<module> and C<file> keys for all
detected dependencies.

=head2 build($callback)

Build for the configured platform. Calls C<$callback> with a result
hashref containing C<success>, C<path>, C<platform>, and C<size>.

=head2 build_macos

Build a macOS C<.app> bundle.

=head2 build_linux

Build a Linux AppImage-style directory.

=head2 build_windows

Build a Windows portable directory.

=head1 SEE ALSO

L<Chandra::App>

=cut
