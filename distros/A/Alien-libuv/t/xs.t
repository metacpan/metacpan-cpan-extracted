use Test2::V0;
use Test::Alien;
use Alien::libuv;

alien_ok 'Alien::libuv';
# Some options behave differently on Windows
sub WINLIKE () {
    return 1 if $^O eq 'MSWin32';
    #return 1 if $^O eq 'cygwin';
    return 1 if $^O eq 'msys';
    return '';
}

my $xs = {xs => do { local $/; <DATA> },};

if (WINLIKE) {
    $xs->{cbuilder_compile} = {
        extra_compiler_flags => ['-D_WIN32_WINNT=0x0600'],
    };
}

xs_ok $xs, with_subtest {
  my $version = UVTest::uv_version_string();
  ok $version, 'version returns okay';
  note "version=$version";
};

done_testing;

__END__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <uv.h>

MODULE = UVTest PACKAGE = UVTest

const char *
uv_version_string()
