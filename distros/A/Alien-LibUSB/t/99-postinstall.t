use strict;
use warnings;

use Test::More;
use Alien::LibUSB;

my $libusb = Alien::LibUSB->new;

if ($libusb->install_type eq 'system' || $ENV{POSTINSTALL_TESTING}) {
    eval 'use Inline';
    if ($@) {
        plan(skip_all => 'Inline required');
    } else {
        plan tests => 3;
    }
} else {
    plan(skip_all => 'Skipping post-install tests');
}

my $c = <<END;
#include <libusb.h>

SV*
version()
{
#if defined(LIBUSB_API_VERSION) && (LIBUSB_API_VERSION >= 0x01000100)
    const struct libusb_version *version;
#endif
    SV *sv;
    int res;

    res = libusb_init(NULL);
    if (res != 0) {
        sv = newSVpvf("Error: %s", libusb_error_name(res));
    } else {
#if defined(LIBUSB_API_VERSION) && (LIBUSB_API_VERSION >= 0x01000100)
        version = libusb_get_version();
        sv = newSVpvf("%d.%d.%d%s (%d)",
                      version->major, version->minor, version->micro,
                      version->rc, version->nano);
#else
        sv = newSVpvf("unknown");
#endif
        libusb_exit(NULL);
    }

    return sv;
}
END

my $cflags = $libusb->cflags;
my $libs = $libusb->libs;
diag "Using CFLAGS=$cflags, LIBS=$libs\n";
Inline->bind(C => $c, CCFLAGS => $cflags, LIBS => $libs);

my $version = version();
unlike($version, qr/^Error:/, 'Initialize libusb-1.0');
isnt($version, '', 'Nonempty version string');
isnt($version, undef, 'Defined version string');

my $type = $libusb->install_type;
diag "Initialized libusb-1.0, version $version, install type $type\n";

