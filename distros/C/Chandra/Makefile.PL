use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my @extra_libs;
my @extra_ccflags;
my @extra_ldflags;

if ($^O eq 'darwin') {
    # macOS - use Cocoa/WebKit
    push @extra_ccflags, '-DWEBVIEW_COCOA=1';
    push @extra_ccflags, '-DOBJC_OLD_DISPATCH_PROTOTYPES=1';
    push @extra_ccflags, '-x objective-c';  # Compile as Objective-C
    # Match the architecture of the Perl we're building for
    if ($Config{archname} =~ /arm|aarch64/) {
        push @extra_ccflags, '-arch arm64e';
        push @extra_ldflags, '-arch arm64e';
    }
    push @extra_ldflags, '-framework WebKit';
    push @extra_ldflags, '-framework Cocoa';
}
elsif ($^O eq 'linux' || $^O eq 'freebsd' || $^O eq 'openbsd' || $^O eq 'netbsd' || $^O eq 'dragonfly') {
    # Linux/BSD - use GTK/WebKit2
    push @extra_ccflags, '-DWEBVIEW_GTK=1';

    # Discover any installed webkit2gtk version via pkg-config
    my ($gtk_cflags, $gtk_libs, $webkit_pkg);
    my @webkit_candidates = grep { /^webkit2gtk-/ }
        split /\n/, `pkg-config --list-all 2>/dev/null | awk '{print \$1}'`;
    # Sort descending so we prefer the newest version
    @webkit_candidates = sort { $b cmp $a } @webkit_candidates;
    for my $pkg (@webkit_candidates) {
        my $cflags = `pkg-config --cflags gtk+-3.0 $pkg 2>/dev/null`;
        my $libs   = `pkg-config --libs gtk+-3.0 $pkg 2>/dev/null`;
        chomp($cflags);
        chomp($libs);
        if ($cflags && $libs) {
            ($gtk_cflags, $gtk_libs, $webkit_pkg) = ($cflags, $libs, $pkg);
            last;
        }
    }

    if (!$gtk_cflags || !$gtk_libs) {
        warn <<'MSG';

*** Chandra requires gtk+-3.0 and webkit2gtk development libraries on Linux.
***
*** Install them with your system package manager:
***
***   Debian/Ubuntu:  sudo apt-get install libgtk-3-dev libwebkit2gtk-4.1-dev
***                   (or libwebkit2gtk-4.0-dev on older releases)
***   Fedora/RHEL:    sudo dnf install gtk3-devel webkit2gtk4.1-devel
***                   (or webkit2gtk3-devel on older releases)
***   Arch:           sudo pacman -S gtk3 webkit2gtk
***   Alpine:         sudo apk add gtk+3.0-dev webkit2gtk-dev
***   openSUSE:       sudo zypper install gtk3-devel webkit2gtk-gtk3-devel
***
*** Then re-run: perl Makefile.PL

MSG
        exit 0;  # exit 0 = NA for CPAN Testers
    }
    push @extra_ccflags, $gtk_cflags if $gtk_cflags;
    push @extra_libs, $gtk_libs if $gtk_libs;
}
elsif ($^O eq 'MSWin32') {
    # Windows - use MSHTML/Edge
    push @extra_ccflags, '-DWEBVIEW_WINAPI=1';
    push @extra_libs, '-lole32', '-lcomctl32', '-loleaut32', '-luuid', '-lgdi32';
}
else {
    warn "*** Chandra is not supported on $^O\n";
    exit 0;  # exit 0 = NA for CPAN Testers
}

WriteMakefile(
    NAME              => 'Chandra',
    VERSION_FROM      => 'lib/Chandra.pm',
    ABSTRACT          => 'Perl bindings to webview-c for cross-platform GUIs',
    AUTHOR            => 'LNATION <email@lnation.org>',
    LICENSE           => 'mit',
    MIN_PERL_VERSION  => '5.010',
    
    TYPEMAPS          => ['typemap'],
    INC               => '-I. -Iinclude -Iinclude/chandra',
    OBJECT            => 'Chandra$(OBJ_EXT)',
    CCFLAGS           => join(' ', $Config{ccflags}, @extra_ccflags),
    LDDLFLAGS         => join(' ', $Config{lddlflags}, @extra_ldflags),
    LIBS              => [join(' ', @extra_libs)],
    
    PREREQ_PM         => {
        'Cpanel::JSON::XS' => 0,
        'IO::Socket::UNIX' => 0,
        'IO::Select'       => 0,
        'File::Raw'        => 0,
    },
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/javalikescript/webview-c.git',
                web  => 'https://github.com/javalikescript/webview-c',
            },
        },
    },
);
