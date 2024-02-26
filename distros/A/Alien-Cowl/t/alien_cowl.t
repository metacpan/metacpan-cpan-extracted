use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::Cowl;

alien_diag 'Alien::Cowl';
alien_ok 'Alien::Cowl';

my $xs = <<'END';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "cowl.h"

const char* version( const char* class ) {
  CowlString* v_cs = cowl_get_version_string();
  return cowl_string_get_cstring( v_cs );
}

MODULE = main PACKAGE = main

const char* version(class)
  const char* class

END
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
  my ($module) = @_;
  like $module->version, qr/^[0-9.]+$/, 'got version';
};

ffi_ok { symbols => [ qw( cowl_get_version_string cowl_string_get_cstring ) ] }, with_subtest {
  my $ffi = shift;
  $ffi->type( 'opaque', 'CowlString' );
  my $get_version_string = $ffi->function( cowl_get_version_string => [] => 'CowlString' );
  my $String_get_cstring = $ffi->function( cowl_string_get_cstring => ['CowlString'] => 'string' );
  my $cs_v = $get_version_string->();
  my $version = $String_get_cstring->($cs_v);
  like $version, qr/^[0-9.]+$/, 'got version';
};

done_testing;
