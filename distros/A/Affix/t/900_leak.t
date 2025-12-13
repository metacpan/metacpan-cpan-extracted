use lib './lib', '../lib', '../blib/arch/', 'blib/arch', '../', '.';
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Test2::Require::AuthorTesting;
$|++;
skip_all 'I have no idea why *BSD is leaking here' if $^O =~ /BSD/i;
leaks 'use Affix' => sub {
    use Affix qw[];
    pass 'loaded';
};
leaks 'affix($$$$)' => sub {
    ok affix( libm, 'pow', [ Double, Double ], Double ), 'affix pow( Double, Double )';
    is pow( 5, 2 ), 25, 'pow(5, 2)';
};
leaks 'wrap($$$$)' => sub {
    isa_ok my $pow = wrap( libm, 'pow', [ Double, Double ], Double ), ['Affix'], 'double pow(double, double)';
    is $pow->( 5, 2 ), 25, '$pow->(5, 2)';
};
leaks 'return pointer' => sub {
    my $lib = compile_ok(<<'');
#include "std.h"
// ext: .c
void * test( ) { void * ret = "Testing"; return ret; }

    ok my $fn         = wrap( $lib, 'test', [] => Pointer [Void] ), 'affix';
    ok my $string_ptr = $fn->(),                                    'call';

    # Casting a pointer to String should return the Value "Testing"
    is Affix::cast( $string_ptr, String ), 'Testing', 'cast($ptr, String) returns value';
};
leaks 'return malloc\'d pointer' => sub {
    ok my $lib = compile_ok(<<'');
#include "std.h"
// ext: .c
#include <stdlib.h>
#include <string.h>
void * test() {
  void * ret = malloc(8);
  if ( ret == NULL ) { }
  else { strcpy(ret, "Testing"); }
  return ret;
}
void c_free(void* p) { free(p); }

    ok affix( $lib, 'test', [] => Pointer [Void] ), 'affix test()';

    # We MUST bind C's free, because Affix::free uses Perl's allocator.
    # Mixing them causes crashes on Windows.
    ok affix( $lib, 'c_free', [ Pointer [Void] ] => Void ), 'affix c_free()';
    ok my $string = test(),                                 'test()';
    is Affix::cast( $string, String ), 'Testing', 'read C string';

    # Correct cleanup: Use the allocator that created it.
    c_free($string);
    pass('freed via c_free');
};
done_testing;
