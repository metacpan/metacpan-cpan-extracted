use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::zix;

alien_diag 'Alien::zix';
alien_ok 'Alien::zix';

my $xs = <<'END';
#if defined(_MSC_VER) || defined(__MINGW32__)
#  define NO_XSLOCKS /* To avoid Perl wrappers of C library */
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "zix/zix.h"

size_t wrap_zix_string_length( const char* class, const char* str ) {
  return zix_string(str).length;
}

MODULE = main PACKAGE = main

size_t wrap_zix_string_length( class, str )
  const char* class
  const char* str

END
#use DDP; p $xs;
xs_ok { xs => $xs }, with_subtest {
  my ($module) = @_;
  is $module->wrap_zix_string_length("foo"), 3, 'correct length';
};

ffi_ok { symbols => [ 'zix_digest32' ] }, with_subtest {
  my $ffi = shift;
  my $zix_digest32 = $ffi->function( zix_digest32 => ['uint32_t','string','size_t'] => 'uint32_t');
  ok lives {
    $zix_digest32->(0, "foo", length "foo");
  }, 'call zix_digest32';
};

done_testing;
