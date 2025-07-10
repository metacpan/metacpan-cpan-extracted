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
# gpg: Signature made Wed Sep 13 14:19:12 2023 UTC
# gpg:                using RSA key 0C7983A8FD9A104C623172CB62F25B592B6F76DA
# gpg: Good signature from "Frank Denis (Jedi/Sector One) <0daydigest@pureftpd.org>" [unknown]
# gpg:                 aka "Frank Denis (Jedi/Sector One) <j@pureftpd.org>" [unknown]
# gpg:                 aka "Frank Denis <github@pureftpd.org>" [unknown]
# gpg:                 aka "Frank Denis <frank.denis@corp.ovh.com>" [unknown]
# if building from the source rather than a distribution, put in src/:
# https://download.libsodium.org/libsodium/releases/libsodium-1.0.19.tar.gz
# https://download.libsodium.org/libsodium/releases/libsodium-1.0.19.tar.gz.sig
# check the signature, or at least:
# sha256: 018d79fe0a045cca07331d37bd0cb57b2e838c51bc48fd837a1472e50068bbea  libsodium-1.0.19.tar.gz
# sha512: 8e9b6d796f6330e00921ce37f1b43545966094250938626ae227deef5fd1279f2fc18b5cd55e23484732a27df4d919cf0d2f07b9c2f1aa0c0ef689e668b0d439  libsodium-1.0.19.tar.gz

# almost certainly none of this will work on windows. although libsodium is
# cross-platform and provides some msvc scripts (or however that works), i've
# no idea how to get it to function. it should be possible.
# so for now, sorry charlie; patches and suggestions are appreciated!

die "OS unsupported\n" if $^O eq 'MSWin32';

my $libsodium_version = '1.0.19';
my $libsodium_major_minimum = '10';
my $libsodium_minor_minimum = '3';
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
$eumm_args{INC} .= "-Wall -Wextra " if $ENV{AUTHOR_MODE};

if (exists $ENV{SODIUM_LIBS} || exists $ENV{SODIUM_INC}) {
  $eumm_args{INC} = " $ENV{SODIUM_INC} " if $ENV{SODIUM_INC};
  $eumm_args{LIBS} = " $ENV{SODIUM_LIBS} " if $ENV{SODIUM_LIBS};
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
  if (!$ENV{SODIUM_BUNDLED} && _c_compile_test($test_sodium_src, "$Config{cc} $cflags -lsodium")) {
    $ENV{SODIUM_LIBS} = $eumm_args{LIBS} = " -lsodium ";
  }
  else {
    warn <<EOWARN unless $ENV{SODIUM_BUNDLED};
!!! using the bundled version of libsodium ($libsodium_version).
!!! if this is not what you want, please set environment variables SODIUM_INC
!!! and/or SODIUM_LIBS as needed
EOWARN
    $ENV{SODIUM_BUNDLED} = 1;
    $eumm_args{depend} = { '$(OBJECT)' => '$(MYEXTLIB)' };
    $eumm_args{INC} .= " -Isrc/libsodium-$libsodium_version/src/libsodium/include ";
    $eumm_args{MYEXTLIB} = "src/lib/libsodium$Config{lib_ext}";
    $eumm_args{clean} = { FILES => "src/libsodium-$libsodium_version src/libsodium-stable src/include src/lib" };
  }
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
  # handle the upstream insanity. now release tarballs do not have a
  # libsodium-$version subdir, it's always libsodium-stable. just move it into
  # a proper location.
  my $libsodium_junk_dir = File::Spec->catdir($src_dir, 'libsodium-stable');
  my $libsodium_dir = File::Spec->catdir($src_dir, "libsodium-$libsodium_version");
  my $min_build = $ENV{SODIUM_LIBRARY_MINIMAL} ? 'SODIUM_LIBRARY_MINIMAL=1' : '';
  return <<EOMAKE;
$libsodium_dir/configure:
	\$(TAR) -C '$src_dir' -xzf '$src_dir/libsodium-$libsodium_version.tar.gz'
	@[ -d "$libsodium_junk_dir" ] && mv '$libsodium_junk_dir' '$libsodium_dir'
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
