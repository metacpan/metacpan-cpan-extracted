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
        my $cmd    = $pkgconf . ' ' . join(' ', @options) . ' ' . $module;
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

sub can_compile {
    my ($self, $cflags, $code) = @_;

    my $ok = 0;

    my ($out, $src_file) = File::Temp::tempfile('testXXXX', SUFFIX => '.c')
        or die 'Cannot create temporary source code file';
    print {$out} $code;
    close $out
        or die "Cannot write to $src_file";

    my $obj_file = eval {
        $self->{builder}->compile(
            source               => $src_file,
            extra_compiler_flags => $cflags,
        );
    };
    if (defined $obj_file) {
        $ok = 1;
        unlink $obj_file;
    }

    unlink $src_file;

    return $ok;
}

sub requires_flag {
    my ($self, $cflags, $flag, $code) = @_;

    my @flags = (!$self->can_compile($cflags, $code)
            && $self->can_compile([@{$cflags}, $flag], $code)) ? $flag : ();
    return @flags;
}

sub std_c99 {
    my ($self, $cflags) = @_;

    my @flags = $self->requires_flag($cflags, q{-std=c99}, <<'CODE');
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
    return @flags;
}

sub ms_extensions {
    my ($self, $cflags) = @_;

    my @flags = $self->requires_flag($cflags, q{-fms-extensions}, <<'CODE');
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
    return @flags;
}

sub has_unsigned_int128 {
    my ($self, $cflags) = @_;

    my $ok = $self->can_compile($cflags, <<'CODE');
int main(void) {
    unsigned __int128 u = 0;
    return (int) u;
}
CODE
    return $ok;
}

sub has_unsigned_int128_mode {
    my ($self, $cflags) = @_;

    my $ok = $self->can_compile($cflags, <<'CODE');
int main(void) {
    unsigned int __attribute__((mode(TI))) u = 0;
    return (int) u;
}
CODE
    return $ok;
}

sub create_config_h {
    my ($self, $filename, $cflags) = @_;

    my $little_endian = $self->{is_little_endian} ? 1 : 0;

    open my $out, '>', $filename
        or die "Cannot create $filename";
    print {$out} qq{#define PACKAGE_VERSION "$BUNDLED_VERSION"\n};
    print {$out} qq{#define MMDB_LITTLE_ENDIAN $little_endian\n};
    my $ok = close $out;

    return $ok;
}

sub create_maxminddb_config_h {
    my ($self, $filename, $cflags) = @_;

    open my $out, '>', $filename
        or die "Cannot create $filename";
    print {$out} qq{#ifndef MAXMINDDB_CONFIG_H\n};
    print {$out} qq{#define MAXMINDDB_CONFIG_H\n};
    if ($self->has_unsigned_int128) {
        print {$out} qq{#define MMDB_UINT128_USING_MODE 0\n};
        print {$out} qq{#undef MMDB_UINT128_IS_BYTE_ARRAY\n};
    }
    elsif ($self->has_unsigned_int128_mode) {
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

    my @cflags;
    push @cflags, $self->std_c99(\@cflags);
    push @cflags, $self->ms_extensions(\@cflags);

    my @src_files = map { File::Spec->catfile(qw(maxminddb src), $_) }
        qw(maxminddb.c data-pool.c);

    my $hdr_file = File::Spec->catfile(qw(maxminddb include), 'maxminddb.h');

    File::Copy::copy($hdr_file, 'maxminddb.h')
        or die "Cannot copy $hdr_file";

    $self->create_config_h('config.h', \@cflags)
        or die 'Cannot create config.h';

    $self->create_maxminddb_config_h('maxminddb_config.h', \@cflags)
        or die 'Cannot create maxminddb_config.h';

    my @inc_dirs = File::Spec->curdir();

    my @obj_files = map {
        $self->{builder}->compile(
            source               => $_,
            include_dirs         => \@inc_dirs,
            extra_compiler_flags => [@cflags, '-DHAVE_CONFIG_H=1'],
        ) or die "Cannot compile $_";
    } @src_files;

    my $lib_file = $self->create_library('maxminddb', \@obj_files);

    unlink @obj_files;

    $self->{hdr_files} = [qw(maxminddb.h maxminddb_config.h)];
    $self->{lib_files} = [$lib_file];

    my @libs = '-lmaxminddb';
    if ($^O eq 'MSWin32') {
        push @libs, '-lws2_32';
    }

    $self->{config} = {
        cflags       => join(q{ }, @cflags),
        install_type => 'share',
        libs         => join(q{ }, @libs),
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
}

package main;

my $dist_dir = File::Spec->catdir(qw(blib lib auto share dist), $DIST_NAME);

my $config = PgkConf->new(module => 'libmaxminddb')->config;
if (!defined $config) {
    $config = LibraryBuilder->new->build->install($dist_dir)->config;
}
ConfigWriter->new(config => $config)->install($dist_dir)->done;
