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
    # System perl is arm64e; bundle must match for PAC-compatible IMPs
    push @extra_ccflags, '-arch arm64e';
    push @extra_ldflags, '-arch arm64e';
    push @extra_ldflags, '-framework WebKit';
    push @extra_ldflags, '-framework Cocoa';
}
elsif ($^O eq 'linux') {
    # Linux - use GTK/WebKit2
    push @extra_ccflags, '-DWEBVIEW_GTK=1';
    my $gtk_cflags = `pkg-config --cflags gtk+-3.0 webkit2gtk-4.0 2>/dev/null`;
    my $gtk_libs = `pkg-config --libs gtk+-3.0 webkit2gtk-4.0 2>/dev/null`;
    chomp($gtk_cflags);
    chomp($gtk_libs);
    if (!$gtk_cflags || !$gtk_libs) {
        warn <<'MSG';

*** Chandra requires gtk+-3.0 and webkit2gtk-4.0 development libraries on Linux.
***
*** Install them with your system package manager:
***
***   Debian/Ubuntu:  sudo apt-get install libgtk-3-dev libwebkit2gtk-4.0-dev
***   Fedora/RHEL:    sudo dnf install gtk3-devel webkit2gtk3-devel
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

WriteMakefile(
    NAME              => 'Chandra',
    VERSION_FROM      => 'lib/Chandra.pm',
    ABSTRACT          => 'Perl bindings to webview-c for cross-platform GUIs',
    AUTHOR            => 'LNATION <email@lnation.org>',
    LICENSE           => 'mit',
    MIN_PERL_VERSION  => '5.010',
    
    TYPEMAPS          => ['typemap'],
    INC               => '-I. -Iinclude -Iinclude/chandra',
    OBJECT            => 'Chandra$(OBJ_EXT) include/chandra/chandra_error$(OBJ_EXT)',
    CCFLAGS           => join(' ', $Config{ccflags}, @extra_ccflags),
    LDDLFLAGS         => join(' ', $Config{lddlflags}, @extra_ldflags),
    LIBS              => [join(' ', @extra_libs)],
    
    PREREQ_PM         => {
        'Cpanel::JSON::XS' => 0,
        'IO::Socket::UNIX' => 0,
        'IO::Select'       => 0,
        'File::Spec'       => 0,
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

# Add custom target to download webview.h if not present
sub MY::postamble {
    # On macOS with SDK Perl, the headers live inside the sysroot
    # and need -iwithsysroot instead of -I.
    my $perl_inc_flag = ($^O eq 'darwin')
        ? '-iwithsysroot "$(PERL_INC)"'
        : '"-I$(PERL_INC)"';
    my $c_rule = <<"END_RULE";

include/chandra/chandra_error\$(OBJ_EXT): include/chandra/chandra_error.c include/chandra/chandra.h
\t\$(CC) -c \$(CCFLAGS) \$(OPTIMIZE) \$(CCCDLFLAGS) \$(PASTHRU_DEFINE) \$(DEFINE) -DVERSION=\\"\$(VERSION)\\" -DXS_VERSION=\\"\$(XS_VERSION)\\" \$(INC) $perl_inc_flag -o \$\@ include/chandra/chandra_error.c
END_RULE

    return $c_rule . <<'MAKE';

webview.h:
	@echo "Downloading webview.h from GitHub..."
	curl -sL https://raw.githubusercontent.com/javalikescript/webview-c/master/webview.h -o include/webview.h
	curl -sL https://raw.githubusercontent.com/javalikescript/webview-c/master/webview-cocoa.c -o include/webview-cocoa.c
	curl -sL https://raw.githubusercontent.com/javalikescript/webview-c/master/webview-gtk.c -o include/webview-gtk.c

download: webview.h

MAKE
}
