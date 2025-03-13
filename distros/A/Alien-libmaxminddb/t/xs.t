#!perl

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.014;
use warnings;
use utf8;

use Alien::libmaxminddb;
use ExtUtils::CBuilder;
use File::Temp qw(tempfile);

use Test::More;

my $builder = ExtUtils::CBuilder->new;

plan skip_all => 'no C compiler found' if !$builder->have_compiler;
plan tests    => 4;

my $cflags       = Alien::libmaxminddb->cflags;
my $libs         = Alien::libmaxminddb->libs;
my $version      = Alien::libmaxminddb->version;
my $install_type = Alien::libmaxminddb->install_type;

diag 'install type is ' . $install_type;

ok defined $version,      'version is defined';
ok defined $install_type, 'install_type is defined';

# Dummy methods
my $dynamic_libs = Alien::libmaxminddb->dynamic_libs;
my $bin_dir      = Alien::libmaxminddb->bin_dir;

my ($fh, $src_file) = tempfile('testXXXX', SUFFIX => '.c');
print {$fh} <<'CODE';
#include <maxminddb.h>
int main(void) {
    (void) MMDB_lib_version();
    return 0;
}
CODE
close $fh;

my $obj_file = $builder->compile(
    source               => $src_file,
    extra_compiler_flags => $cflags,
);
ok $obj_file, 'can compile source code';

my $exe_file = $builder->link_executable(
    objects            => $obj_file,
    extra_linker_flags => $libs,
);
ok $exe_file, 'can produce an executable file';

unlink $exe_file, $obj_file, $src_file;
