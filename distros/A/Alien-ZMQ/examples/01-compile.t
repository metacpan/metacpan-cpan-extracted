#!perl

# This test may be performed after the installation of Alien::ZMQ, e.g.:
#   prove examples/01-compile.t

use warnings;
use strict;

BEGIN {
    require ExtUtils::CBuilder;
    unless (ExtUtils::CBuilder->new->have_compiler) {
        require Test::More;
        Test::More::plan(skip_all => "these tests require a working compiler");
    }
}

use Alien::ZMQ;
use Test::More tests => 5;
use version;

my $cb = ExtUtils::CBuilder->new;

my $src = "test-$$.c";
open my $SRC, '>', $src;
print $SRC <<END;
#include <stdio.h>
#include <zmq.h>
int main(int argc, char* argv[]) {
    int major, minor, patch;
    zmq_version(&major, &minor, &patch);
    printf("%d.%d.%d %d.%d.%d",
        ZMQ_VERSION_MAJOR, ZMQ_VERSION_MINOR, ZMQ_VERSION_PATCH,
        major, minor, patch);
    return 0;
}
END
close $SRC;

my $obj = eval {
    $cb->compile(source => $src, extra_compiler_flags => [Alien::ZMQ->cflags]);
};
unlink $src;
ok($obj, "compile C code");
BAIL_OUT("compile failed") unless $obj;

my $exe = eval {
    $cb->link_executable(objects => $obj, extra_linker_flags => [Alien::ZMQ->libs]);
};
unlink $obj;
ok($exe, "link object");
BAIL_OUT("link failed") unless $exe;

$ENV{LD_LIBRARY_PATH} = Alien::ZMQ->lib_dir;
my $out = `./$exe`;
ok($out, "run executable");
unlink $exe;
my ($inc_version, $lib_version) = $out =~ /(\d\.\d\.\d) (\d\.\d\.\d)/;

cmp_ok(version->parse($inc_version), '==', Alien::ZMQ->inc_version, "include versions are equal");
cmp_ok(version->parse($lib_version), '==', Alien::ZMQ->lib_version, "library versions are equal");

