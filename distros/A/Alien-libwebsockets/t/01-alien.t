use strict;
use warnings;
use Test::More;
use Test::Alien;
use Alien::libwebsockets;

alien_ok 'Alien::libwebsockets';

diag 'install_type: ' . Alien::libwebsockets->install_type;
diag 'cflags: ' . Alien::libwebsockets->cflags;
diag 'libs: ' . Alien::libwebsockets->libs;

my $has_ext = Alien::libwebsockets->has_extensions;
diag "has_extensions: $has_ext";
if (Alien::libwebsockets->install_type eq 'share') {
    ok $has_ext, 'share install has extensions enabled';
}
else {
    note 'system install - has_extensions may not detect symbol; skipping assertion';
}

# preload with RTLD_GLOBAL so xs_ok can resolve symbols at runtime
DynaLoader::dl_load_file($_, 0x01) for Alien::libwebsockets->dynamic_libs;

TODO: {
    local $TODO = 'xs_ok may fail on platforms where RTLD_GLOBAL does not propagate to DT_NEEDED'
        if $^O =~ /^(?:freebsd|openbsd|netbsd|dragonfly)$/;

    xs_ok do { local $/; <DATA> }, with_subtest {
        my $ver = do { no strict 'refs'; &{"$_[0]\::lws_version"}() };
        like $ver, qr/\A\d+\.\d+/, "lws_get_library_version() => '$ver'";
    };
}

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

extern const char *lws_get_library_version(void);

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
lws_version()
    CODE:
        RETVAL = lws_get_library_version();
    OUTPUT:
        RETVAL
