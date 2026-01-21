#!/usr/bin/env perl
use strict;
use warnings;

use ExtUtils::MakeMaker;
use Config;
use Cwd;
use File::Spec;
use File::Temp;
use Text::ParseWords;

# builtin libsodium (these comments are to be updated when bundled lib is updated):

# the libsodium release from 1.0.21 will again be from the upstream stable
# branch snapshot. to the best of my knowledge, this is from the upstream
# commit:
# https://github.com/jedisct1/libsodium/commit/aa1d5c8d66abc0d246cc85d0e275a7eedc480ef4
# it is the stable release as of Jan 21 2026 03:00:00 +0000

# a minisign signature is included with the bundled library tarball. this can
# be verified with the `minisign` utility or `pminisign` from this cpan
# distribution. you will need to already have libsodium, on which they both
# depend.

# $ pminisign -P RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3 -Vm libsodium-1.0.21-stable.tar.gz
# Signature and comment signature verified
# Trusted comment: timestamp:1768955633   file:libsodium-stable.tar.gz    hashed

# sha256: bef95e3e4aecd123c6489048cf1b896cc8b35bc661556ca342b3dac61e8ae378  libsodium-1.0.21-stable.tar.gz
# sha512: 71b0f0f3f2c4f2780871c0df122b9b74e26f05b6c583b62312a71d1620043dbf7137c148ada818a5b1f3d730eabe5092d8397bd960472319b415130069a23b14  libsodium-1.0.21-stable.tar.gz

# see main module INSTALLATION section for how to install with a different
# release.

# almost certainly none of this will work on windows. although libsodium is
# cross-platform and provides some msvc scripts (or however that works), i've
# no idea how to get it to function. it should be possible.
# so for now, sorry charlie; patches and suggestions are appreciated!

die "OS unsupported\n" if $^O eq 'MSWin32';

my $src_dir = File::Spec->catdir(getcwd(), "src");
my $libsodium_version = '1.0.21-stable';
my $libsodium_major_minimum = '10';
my $libsodium_minor_minimum = '3';
my $bundled_src_path = File::Spec->catfile($src_dir, "libsodium-$libsodium_version.tar.gz");
my $test_src = 'int main (int argc, char **argv) { return 0; }';
my $test_sodium_src = <<EOTEST;
#include <sodium.h>

#if (SODIUM_LIBRARY_VERSION_MAJOR < ${libsodium_major_minimum}U)
#error "major version is less than ${libsodium_major_minimum}: " _ SODIUM_LIBRARY_VERSION_MAJOR
#endif
#if (SODIUM_LIBRARY_VERSION_MINOR == ${libsodium_major_minimum}U) && (SODIUM_LIBRARY_VERSION_MINOR < ${libsodium_minor_minimum}U)
#error "minor version is less than ${libsodium_minor_minimum}: " _ SODIUM_LIBRARY_VERSION_MINOR
#endif

$test_src
EOTEST
my %eumm_args;

my $cflags = " $Config{ccflags} $Config{cccdlflags} $Config{optimize} ";
$cflags .= "$ENV{CFLAGS} " if $ENV{CFLAGS};
$cflags .= "$ENV{CPPFLAGS} " if $ENV{CPPFLAGS};
$cflags .= "$ENV{LDFLAGS} " if $ENV{LDFLAGS};
# lto is recommended against by upstream. best effort to prevent it.
if (_c_compile_test($test_src, "$Config{cc} -fno-lto")) {
  $cflags .= '-fno-lto ';
}
else {
  $cflags =~ s/(\A|\s)-flto\S*(\s|\z)//g;
}
# and sanitizers are more strongly discouraged, as they can introduce
# side-channels. upstream does test with sanitizers, and if you're doing your
# own testing and reading this...well you can comment it out.
if (_c_compile_test($test_src, "$Config{cc} -fno-sanitize=all")) {
  $cflags .= '-fno-sanitize=all ';
}
else {
  $cflags =~ s/(\A|\s)-fsanitize\S*(\s|\z)//g;
}

if ($ENV{SODIUM_LIBRARY_MINIMAL}) {
	$cflags .= '-DSODIUM_LIBRARY_MINIMAL ';
}

$eumm_args{INC} = '';
$eumm_args{LIBS} = '';
$eumm_args{INC} = "-Wall -Wextra" if $ENV{AUTHOR_MODE};

if (exists $ENV{SODIUM_LIBS} || exists $ENV{SODIUM_INC}) {
  $eumm_args{INC} .= " $ENV{SODIUM_INC} " if $ENV{SODIUM_INC};
  $eumm_args{LIBS} .= " $ENV{SODIUM_LIBS} " if $ENV{SODIUM_LIBS};
  my $cmd = "$Config{cc} $eumm_args{INC} $cflags $eumm_args{LIBS}";
  unless (_c_compile_test($test_sodium_src, $cmd)) {
    die <<EODIE;
!!! failed to compile with given env vars. please correct.
!!! SODIUM_INC = $ENV{SODIUM_INC}
!!! SODIUM_LIBS = $ENV{SODIUM_LIBS}
EODIE
  }
}
else {
  if ($ENV{SODIUM_BUNDLED}) {
    unless (File::Spec->file_name_is_absolute($ENV{SODIUM_BUNDLED})) {
      $ENV{SODIUM_BUNDLED} = $bundled_src_path;
    }
  }
  elsif (_c_compile_test($test_sodium_src, "$Config{cc} $cflags -lsodium")) {
    $eumm_args{LIBS} .= " -lsodium ";
  }
  else {
    warn <<EOWARN;
!!! using the bundled version of libsodium ($libsodium_version).
!!! if this is not what you want, please set environment variables
!!! SODIUM_BUNDLED, SODIUM_INC, and/or SODIUM_LIBS as needed
EOWARN
    $ENV{SODIUM_BUNDLED} = $bundled_src_path;
  }
}

if ($ENV{SODIUM_BUNDLED}) {
  $ENV{SODIUM_BUNDLED} = File::Spec->rel2abs($ENV{SODIUM_BUNDLED});
  $eumm_args{depend} = { '$(OBJECT)' => '$(MYEXTLIB)' };
  $eumm_args{INC} .= " -Isrc/libsodium-build/src/libsodium/include ";
  $eumm_args{MYEXTLIB} = "src/lib/libsodium$Config{lib_ext}";
  $eumm_args{clean} = { FILES => "src/libsodium-build src/include src/lib" };
}

my %WriteMakefileArgs = (
  "ABSTRACT" => "perl XS bindings for libsodium",
  "AUTHOR" => "Brad Barden <perlmodules\@5c30.org>",
  "DISTNAME" => "Crypt-Sodium-XS",
  "LICENSE" => "perl",
  "NAME" => "Crypt::Sodium::XS",
  "MIN_PERL_VERSION" => "5.001000",
  "PREREQ_PM" => {
    "XSLoader" => 0,
  },
  "TEST_REQUIRES" => {
    "Test::More" => "0.88",
  },
  VERSION_FROM => "lib/Crypt/Sodium/XS.pm",
  EXE_FILES => [
    "bin/csxs-ppcrypt",
    "bin/pminisign",
  ],
  "test" => {
    "TESTS" => "t/*.t"
  },
  META_MERGE => {
    resources => {
      x_IRC => 'irc://irc.perl.org/#sodium',
    },
  },
  %eumm_args,
);

my %FallbackPrereqs = (
  "Test::More" => "0.88",
  "XSLoader" => 0,
  "strict" => 0,
  "warnings" => 0
);

my $eumm_version = eval { $ExtUtils::MakeMaker::VERSION };
delete $WriteMakefileArgs{TEST_REQUIRES} if $eumm_version < 6.64;
$WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs if $eumm_version < 6.64;
delete $WriteMakefileArgs{BUILD_REQUIRES} if $eumm_version < 6.56;
delete $WriteMakefileArgs{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
delete $WriteMakefileArgs{META_MERGE} if $eumm_version < 6.46;
delete $WriteMakefileArgs{LICENSE} if $eumm_version < 6.31;
delete $WriteMakefileArgs{MIN_PERL_VERSION} if $eumm_version < 6.48;

WriteMakefile(%WriteMakefileArgs);

sub MY::postamble {
  return '' unless $ENV{SODIUM_BUNDLED};
  my $src_dir = File::Spec->catdir(getcwd(), "src");
  # handle whatever subdir there is in the tarball. it must start with
  # "libsodium-" (all release tarballs have this).
  my $libsodium_dir = File::Spec->catdir($src_dir, "libsodium-build");
  # do not use minimal. completely untested.
  my $min_build = $ENV{SODIUM_LIBRARY_MINIMAL} ? 'SODIUM_LIBRARY_MINIMAL=1' : '';
  return <<EOMAKE;
$libsodium_dir/configure:
	cd '$src_dir' && \$(TAR) -xzf '$ENV{SODIUM_BUNDLED}'
	rm -rf "$src_dir/libsodium-build"
	mv "$src_dir/libsodium-"*/ "$src_dir/libsodium-build"
$libsodium_dir/Makefile: $libsodium_dir/configure
	cd '$libsodium_dir' && ./configure --prefix= --with-pic --disable-shared
\$(MYEXTLIB): $libsodium_dir/Makefile
	cd '$libsodium_dir' && \$(MAKE) \\
		SODIUM_STATIC=1 $min_build CC='\$(CC)' CFLAGS='$cflags' DESTDIR='$libsodium_dir/..' install
EOMAKE
}

# NB: has to take command as a string (cflags etc need tokenization)
sub _c_compile_test {
  my ($src, $cmd) = @_;
  my $tmpdir = File::Temp->newdir;
  my $c = File::Spec->catfile($tmpdir, "input.c");
  open(my $fh, '>', $c) or die "$c: open: $!";
  print $fh $src or die "$c: print: $!";
  close($fh) or die "$c: close: $!";
  $cmd .= " -o /dev/null $c";
  return system($cmd) == 0;
}
