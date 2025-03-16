use 5.014;
use warnings;
use utf8;

my $DIST_NAME       = 'Alien-libmaxminddb';
my $BUNDLED_VERSION = '1.12.2';

package PgkConf;

use File::Spec qw();

sub new {
    my ($class, %attrs) = @_;

    my $self = bless \%attrs, $class;

    $self->{pkgconf} = $self->find_pkgconf(qw(pkgconf pkg-config));

    return $self;
}

sub find_pkgconf {
    my ($self, @programs) = @_;

    my $devnull = File::Spec->devnull;

    for my $pkgconf (@programs) {
        my $output = `$pkgconf --version 2>$devnull`;
        if ($? == 0) {
            return $pkgconf;
        }
    }

    return;
}

sub pkgconf {
    my ($self, @options) = @_;

    my $module = $self->{module};

    my $devnull = File::Spec->devnull;

    my $pkgconf = $self->{pkgconf};
    if (defined $pkgconf) {
        my $cmd    = $pkgconf . q{ } . join(q{ }, @options) . q{ } . $module;
        my $output = `$cmd 2>$devnull`;
        if ($? == 0) {
            chomp $output;
            return 1, $output;
        }
    }

    return 0, undef;
}

sub cflags {
    my ($self) = @_;

    return $self->pkgconf('--cflags');
}

sub libs {
    my ($self) = @_;

    return $self->pkgconf('--libs');
}

sub modversion {
    my ($self) = @_;

    return $self->pkgconf('--modversion');
}

sub config {
    my ($self) = @_;

    my ($ok_cflags, $cflags) = $self->cflags;
    return if !$ok_cflags;

    my ($ok_libs, $libs) = $self->libs;
    return if !$ok_libs;

    my ($ok_modversion, $modversion) = $self->modversion;
    return if !$ok_modversion;

    my $config = {
        cflags       => $cflags,
        install_type => 'system',
        libs         => $libs,
        version      => $modversion,
    };

    return $config;
}

package LibraryBuilder;

use Config;
use ExtUtils::CBuilder;
use File::Copy qw();
use File::Path qw();
use File::Spec qw();
use File::Temp qw();

sub new {
    my ($class, %attrs) = @_;

    my $self = bless \%attrs, $class;

    my $builder = ExtUtils::CBuilder->new;
    if (!$builder->have_compiler) {
        warn "Error: No C compiler found\n";
        die "OS unsupported\n";
    }

    my $is_little_endian = 1;
    my $byteorder        = $Config{byteorder};
    if (!defined $byteorder) {
        warn "\$Config{byteorder} is undefined\n";
        die "OS unsupported\n";
    }
    if ($byteorder == 4321 || $byteorder == 87654321) {
        $is_little_endian = 0;
    }
    elsif (!($byteorder == 1234 || $byteorder == 12345678)) {
        warn "Unknown byte order: $byteorder\n";
        die "OS unsupported\n";
    }

    $self->{builder}          = $builder;
    $self->{is_little_endian} = $is_little_endian;

    return $self;
}

sub compile {
    my ($self, $cflags_ref, $code) = @_;

    my ($out, $src_file) = File::Temp::tempfile('testXXXX', SUFFIX => '.c')
        or die 'Cannot create temporary source code file';
    print {$out} $code;
    close $out
        or die "Cannot write to $src_file";

    my $obj_file = eval {
        $self->{builder}->compile(
            source               => $src_file,
            extra_compiler_flags => $cflags_ref,
        );
    };

    unlink $src_file;

    return $obj_file;
}

sub can_compile {
    my ($self, $cflags_ref, $code) = @_;

    my $ok = 0;

    my $obj_file = $self->compile($cflags_ref, $code);
    if (defined $obj_file) {
        unlink $obj_file;
        $ok = 1;
    }

    return $ok;
}

sub can_link {
    my ($self, $cflags_ref, $libs_ref, $code) = @_;

    my $ok = 0;

    my $obj_file = $self->compile($cflags_ref, $code);
    if (defined $obj_file) {
        my $exe_file = eval {
            $self->{builder}->link_executable(
                objects            => $obj_file,
                extra_linker_flags => $libs_ref,
            );
        };
        if (defined $exe_file) {
            unlink $exe_file;
            $ok = 1;
        }
        unlink $obj_file;
    }

    return $ok;
}

sub check_cflags {
    my ($self, $cflags_ref, $other_cflags_ref, $code) = @_;

    my $new_cflags_ref = [@{$cflags_ref}, @{$other_cflags_ref}];
    if (  !$self->can_compile($cflags_ref, $code)
        && $self->can_compile($new_cflags_ref, $code)) {
        return $new_cflags_ref;
    }
    return $cflags_ref;
}

sub check_libs {
    my ($self, $cflags_ref, $libs_ref, $other_libs_ref, $code) = @_;

    my $new_libs_ref = [@{$libs_ref}, @{$other_libs_ref}];
    if (  !$self->can_link($cflags_ref, $libs_ref, $code)
        && $self->can_link($cflags_ref, $new_libs_ref, $code)) {
        return $new_libs_ref;
    }
    return $libs_ref;
}

sub check_std_c99 {
    my ($self, $cflags_ref) = @_;

    return $self->check_cflags($cflags_ref, ['-std=c99'], <<'CODE');
struct point {
    int x;
    int y;
};
int main(void) {
    struct point p = { .x = 1, .y = 2 };
    for (int i = 0; i < 1; i++) {
        --p.x;
    }
    return p.x;
}
CODE
}

sub check_ms_extensions {
    my ($self, $cflags_ref) = @_;

    return $self->check_cflags($cflags_ref, ['-fms-extensions'], <<'CODE');
struct anonymous {
    union {
        float x;
        int n;
    };
};
int main(void) {
    struct anonymous a;
    a.n = 0;
    return a.n;
}
CODE
}

sub has_unsigned_int128 {
    my ($self, $cflags_ref) = @_;

    return $self->can_compile($cflags_ref, <<'CODE');
int main(void) {
    unsigned __int128 u = 0;
    return (int) u;
}
CODE
}

sub has_unsigned_int128_mode {
    my ($self, $cflags_ref) = @_;

    return $self->can_compile($cflags_ref, <<'CODE');
int main(void) {
    unsigned int __attribute__((mode(TI))) u = 0;
    return (int) u;
}
CODE
}

sub check_libm {
    my ($self, $cflags_ref, $libs_ref) = @_;

    return $self->check_libs($cflags_ref, $libs_ref, ['-lm'], <<'CODE');
#include <math.h>

int main(void) {
    (void) fabs(0.0);
    (void) fabsf(0.0);
    return 0;
}
CODE
}

sub check_libsocket {
    my ($self, $cflags_ref, $libs_ref) = @_;

    if ($^O eq 'MSWin32') {
        return ['-lws2_32'];
    }

    return $self->check_libs($cflags_ref, $libs_ref, ['-lsocket'], <<'CODE');
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>
#include <stddef.h>

int main(void) {
    struct addrinfo *ai = NULL;
    if (getaddrinfo("localhost", NULL, NULL, &ai) == 0) {
        freeaddrinfo(ai);
    }
    return 0;
}
CODE
}

sub create_config_h {
    my ($self, $filename, $cflags_ref) = @_;

    my $little_endian = $self->{is_little_endian} ? 1 : 0;

    open my $out, '>', $filename
        or die "Cannot create $filename";
    print {$out} qq{#define PACKAGE_VERSION "$BUNDLED_VERSION"\n};
    print {$out} qq{#define MMDB_LITTLE_ENDIAN $little_endian\n};
    my $ok = close $out;

    return $ok;
}

sub create_maxminddb_config_h {
    my ($self, $filename, $cflags_ref) = @_;

    open my $out, '>', $filename
        or die "Cannot create $filename";
    print {$out} qq{#ifndef MAXMINDDB_CONFIG_H\n};
    print {$out} qq{#define MAXMINDDB_CONFIG_H\n};
    if ($self->has_unsigned_int128($cflags_ref)) {
        print {$out} qq{#define MMDB_UINT128_USING_MODE 0\n};
        print {$out} qq{#undef MMDB_UINT128_IS_BYTE_ARRAY\n};
    }
    elsif ($self->has_unsigned_int128_mode($cflags_ref)) {
        print {$out} qq{#define MMDB_UINT128_USING_MODE 1\n};
        print {$out} qq{#undef MMDB_UINT128_IS_BYTE_ARRAY\n};
    }
    else {
        print {$out} qq{#define MMDB_UINT128_IS_BYTE_ARRAY 1\n};
    }
    print {$out} qq{#endif\n};
    my $ok = close $out;

    return $ok;
}

sub create_library {
    my ($self, $basename, $obj_files) = @_;

    my $lib_ext  = $Config{lib_ext};
    my $lib_file = 'lib' . $basename . $lib_ext;

    my $ar = $Config{ar};
    system($ar, 'rc', $lib_file, @{$obj_files}) == 0
        or die "Cannot create $lib_file";

    return $lib_file;
}

sub install {
    my ($self, $dist_dir) = @_;

    my @hdr_files = @{$self->{hdr_files}};
    my @lib_files = @{$self->{lib_files}};

    my $inc_dir = File::Spec->catdir($dist_dir, 'include');
    File::Path::make_path($inc_dir);

    for my $file (@hdr_files) {
        File::Copy::move($file, $inc_dir)
            or die "Cannot copy $file";
    }

    my $lib_dir = File::Spec->catdir($dist_dir, 'lib');
    File::Path::make_path($lib_dir);

    for my $file (@lib_files) {
        File::Copy::move($file, $lib_dir)
            or die "Cannot copy $file";
    }

    return $self;
}

sub build {
    my ($self) = @_;

    my $cflags_ref = $self->check_ms_extensions($self->check_std_c99([]));

    my $libs_ref = [
        '-lmaxminddb',
        @{$self->check_libm($cflags_ref, [])},
        @{$self->check_libsocket($cflags_ref, [])},
    ];

    my @src_files = map { File::Spec->catfile(qw(maxminddb src), $_) }
        qw(maxminddb.c data-pool.c);

    my $hdr_file = File::Spec->catfile(qw(maxminddb include), 'maxminddb.h');

    File::Copy::copy($hdr_file, 'maxminddb.h')
        or die "Cannot copy $hdr_file";

    $self->create_config_h('config.h', $cflags_ref)
        or die 'Cannot create config.h';

    $self->create_maxminddb_config_h('maxminddb_config.h', $cflags_ref)
        or die 'Cannot create maxminddb_config.h';

    my @inc_dirs = File::Spec->curdir();

    my @obj_files = map {
        $self->{builder}->compile(
            source               => $_,
            include_dirs         => \@inc_dirs,
            extra_compiler_flags => [@{$cflags_ref}, '-DHAVE_CONFIG_H=1'],
        ) or die "Cannot compile $_";
    } @src_files;

    my $lib_file = $self->create_library('maxminddb', \@obj_files);

    unlink @obj_files;

    $self->{hdr_files} = [qw(maxminddb.h maxminddb_config.h)];
    $self->{lib_files} = [$lib_file];

    $self->{config} = {
        cflags       => join(q{ }, @{$cflags_ref}),
        install_type => 'share',
        libs         => join(q{ }, @{$libs_ref}),
        version      => $BUNDLED_VERSION,
    };

    return $self;
}

sub config {
    my ($self) = @_;

    return $self->{config};
}

package ConfigWriter;

use File::Path qw();
use File::Spec qw();
use JSON::PP   qw();

sub new {
    my ($class, %attrs) = @_;

    my $self = bless \%attrs, $class;

    return $self;
}

sub install {
    my ($self, $dist_dir) = @_;

    my $alien_dir = File::Spec->catdir($dist_dir, '_alien');
    File::Path::make_path($alien_dir);

    my $json_file = File::Spec->catfile($alien_dir, 'alien.json');
    open my $out, '>', $json_file
        or die "Cannot create $json_file";
    print ${out} JSON::PP->new->pretty->encode($self->{config});
    close $out
        or die "Cannot write to $json_file";

    return $self;
}

sub done {
    open my $out, '>', 'done.txt';
    close $out;
    return;
}

package main;

my $dist_dir = File::Spec->catdir(qw(blib lib auto share dist), $DIST_NAME);

my $config = PgkConf->new(module => 'libmaxminddb')->config;
if (!defined $config) {
    $config = LibraryBuilder->new->build->install($dist_dir)->config;
}
ConfigWriter->new(config => $config)->install($dist_dir)->done;
