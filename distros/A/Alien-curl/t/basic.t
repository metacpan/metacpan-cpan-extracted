use Test2::Bundle::Extended;
use Test::Alien 0.11;
use Alien::curl;

alien_ok 'Alien::curl';

run_ok(['curl', '--version'])
  ->success
  ->out_like(qr/curl/);

xs_ok(
  do { local $/; <DATA> },
  with_subtest {
    my $version = Curl::curl_version();
    ok $version, "version returned ok";
    note "version = $version";
  }
);

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <curl/curl.h>

MODULE = Curl PACKAGE = Curl

const char *
curl_version()
