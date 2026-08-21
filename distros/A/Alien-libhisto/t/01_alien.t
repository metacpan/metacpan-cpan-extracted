use Test2::V0;
use Test::Alien;
use Alien::libhisto;

alien_ok 'Alien::libhisto';

my $xs = <<'EOF';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <histo/histo.h>
#include <histo/version.h>

MODULE = My_Test_Alien PACKAGE = My_Test_Alien

const char *
test_version(CLASS)
    char *CLASS
    CODE:
        (void)CLASS;
        RETVAL = HISTO_VERSION_STRING;
    OUTPUT:
        RETVAL

int
test_basic_histogram(CLASS)
    char *CLASS
    CODE:
        (void)CLASS;
        histo_t *h = histo_create_uniform(10, 0.0, 100.0, HISTO_FLAG_NONE);
        if (!h) {
            RETVAL = 0;
        } else {
            histo_fill(h, 50.0);
            RETVAL = (histo_num_entries(h) == 1) ? 1 : 0;
            histo_destroy(h);
        }
    OUTPUT:
        RETVAL

EOF

xs_ok { xs => $xs, verbose => 0 }, with_subtest {
    my ($module) = @_;
    my $ver = $module->test_version();
    like $ver, qr/^\d+\.\d+\.\d+/, "histo_version() returned valid semver: $ver";
    is $module->test_basic_histogram(), 1, "basic C histogram creation and fill succeeded";
};

done_testing;
