use v5.10; use strict; use warnings;
use Test::More;
use Test::Alien;
use Alien::curlimpersonate;

alien_ok 'Alien::curlimpersonate';
my ($libdir) = Alien::curlimpersonate->dynamic_libs;
$libdir =~ s{/[^/]+$}{} if defined $libdir;

xs_ok {
    cbuilder_link => { extra_linker_flags => $libdir ? ["-Wl,-rpath,$libdir"] : [] },
    xs => <<'XS',
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <curl/curl.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
version(klass)
    SV *klass
  CODE:
    PERL_UNUSED_VAR(klass);
    if (curl_version_info(CURLVERSION_NOW)->version_num != LIBCURL_VERSION_NUM)
        croak("libcurl header/runtime version mismatch");
    RETVAL = curl_version();
  OUTPUT:
    RETVAL

int
profile(klass)
    SV *klass
  PREINIT:
    CURL *easy;
  CODE:
    PERL_UNUSED_VAR(klass);
    easy = curl_easy_init();
    RETVAL = easy ? (int) curl_easy_impersonate(easy, "chrome131", 1) : -1;
    if (easy) curl_easy_cleanup(easy);
  OUTPUT:
    RETVAL
XS
}, with_subtest {
    my ($module) = @_;
    like $module->version, qr{libcurl/8\.23\.0\b}, 'linked runtime is curl 8.23.0';
    like $module->version, qr{curl-impersonate/2\.3\.0\b}, 'runtime identifies the pinned upstream release';
    like $module->version, qr{\bc-ares/\S+}, 'asynchronous c-ares resolver is linked';
    is $module->profile, 0, 'existing chrome131 profile remains usable';
};

done_testing;
