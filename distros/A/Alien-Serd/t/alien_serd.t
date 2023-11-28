use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Serd;
use File::Which;

alien_diag 'Alien::Serd';
alien_ok 'Alien::Serd';

if( which 'serdi' ) {
  run_ok([ qw(serdi -v) ])
    ->success
    ->out_like(qr/serdi\s+([0-9.]+)/);
}

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "serd/serd.h"

bool wrap_serd_uri_string_has_scheme( const char* class, const uint8_t *utf8) {
  return serd_uri_string_has_scheme(utf8);
}

MODULE = main PACKAGE = main

bool wrap_serd_uri_string_has_scheme(class, utf8)
  const char* class
  const char* utf8

END
xs_ok $xs, with_subtest {
  my ($module) = @_;
  ok !! $module->wrap_serd_uri_string_has_scheme("http://example.com"), 'has scheme';
  ok ! $module->wrap_serd_uri_string_has_scheme("example.com"), 'no scheme';
};

ffi_ok { symbols => [ 'serd_uri_string_has_scheme' ] }, with_subtest {
  my $ffi = shift;
  my $serd_uri_string_has_scheme = $ffi->function( serd_uri_string_has_scheme => ['string'] => 'bool' );

  ok !! $serd_uri_string_has_scheme->("http://example.com"), 'has scheme';
  ok ! $serd_uri_string_has_scheme->("example.com"), 'no scheme';

};

done_testing;
