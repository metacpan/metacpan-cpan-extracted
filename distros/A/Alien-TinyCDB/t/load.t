use strict;
use warnings;
use Test::More tests => 5;

use_ok('Alien::TinyCDB');

my $install_type = Alien::TinyCDB->install_type;
my $cflags       = Alien::TinyCDB->cflags;
my $libs         = Alien::TinyCDB->libs;
my @dynamic_libs = Alien::TinyCDB->dynamic_libs;

diag("install type: $install_type");
diag("cflags: [$cflags]");
diag("libs: [$libs]");
diag("dynamic_libs: $_") for @dynamic_libs;

# ->libs is the reason this distribution exists: every consumer links against
# TinyCDB through it, so -lcdb must be present on BOTH the system and the share
# path. On share it is preceded by a -L into the private prefix; -lcdb is the
# invariant.
like($libs, qr/-lcdb\b/, 'libs links -lcdb');

# ->cflags is NOT truthy on both paths, and asserting so would be wrong:
#   * share  — the header lives in the Alien's private prefix, so cflags MUST
#              carry a -I include path (a build compiled without it cannot find
#              cdb.h).
#   * system — pkg-config reports empty cflags because cdb.h is on the default
#              include path; an empty cflags is the correct answer here, so the
#              contract is only that it is defined, not that it is true.
if ($install_type eq 'share') {
  like($cflags, qr/(?:^|\s)-I\S/, 'share cflags carries an -I include path');
}
else {
  ok(defined $cflags,
    'system cflags defined (may be empty: cdb.h on the default include path)');
}

# ->dynamic_libs is the FFI::Platypus entry point the POD advertises (a Path-1
# maintainer decision), so it must yield at least one shared library on BOTH
# paths: the system libcdb.so on a system install, and — because upstream's
# default target builds only the static libcdb.a — the sharedlib /
# install-sharedlib Makefile targets plus Gather::IsolateDynamic on a share
# build.
ok(scalar(@dynamic_libs) >= 1, 'dynamic_libs returns at least one shared library path')
  or diag('no shared library found: FFI consumers cannot dlopen TinyCDB');
my @shared = grep { /\.(?:so|dll|dylib|bundle)(?:\.\d+)*$/ } @dynamic_libs;
ok(scalar(@shared) >= 1, 'dynamic_libs entry is a real shared object');
